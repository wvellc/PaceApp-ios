//
//  AuthManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 06/03/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

/// Central coordinator for Firebase Authentication and Firestore User Profile/Watch Event sync.
@Observable
@MainActor
final class AuthManager {

    // MARK: - Singleton
    static let shared = AuthManager()

    // MARK: - Properties
    /// `nonisolated(unsafe)` is safe here because `AuthManager` is a singleton
    /// that is never deallocated — the `deinit` listener removal is purely defensive.
    nonisolated(unsafe) private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    var currentUser: User? { Auth.auth().currentUser }
    var isUserAuthenticated: Bool { currentUser != nil }

    // MARK: - Firebase Hosting domain constants
    //
    // These MUST stay in sync with:
    //   1. PaceApp.entitlements  → com.apple.developer.associated-domains (applinks:)
    //   2. Firebase Console       → Authentication > Sign-in method > Email link > Authorized domains
    //   3. Firebase Console       → Hosting > Custom domains (if using a custom domain)
    //
    // The continueURL is the domain iOS uses to match the Universal Link and hand
    // the URL back to the app via onOpenURL instead of opening it in Safari.
    // It must be the BARE domain root — NOT /__/auth/action — because Firebase
    // appends its own query parameters and path; sending a full /__/auth/action URL
    // causes a double-path issue that results in a "Site Not Found" page.
    private enum EmailLinkDomain {
        /// Primary domain listed first in entitlements — used as the continueURL.
        static let continueURL = "https://thepaceapp.firebaseapp.com"
        /// Must match the applinks: entry in PaceApp.entitlements exactly.
        static let appLinksDomain = "thepaceapp.firebaseapp.com"
    }

    // MARK: - Lifecycle & Configuration

    private init() {}

    /// Registers the global authentication state listener.
    /// Called from AppDelegate after FirebaseApp.configure().
    func configure() {
        guard authStateListenerHandle == nil else { return }

        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            Task { @MainActor in
                if let user = user {
                    print("[AuthManager] User logged in: \(user.uid)")
                    AppSession.isUserAuthenticated = true
                    AppSession.userId = user.uid

                    var cachedUser = AppSession.userDetails ?? UserModel(uuid: user.uid)
                    cachedUser.uuid = user.uid
                    if cachedUser.email == nil      { cachedUser.email       = user.email }
                    if cachedUser.phoneNumber == nil { cachedUser.phoneNumber = user.phoneNumber }
                    AppSession.userDetails = cachedUser

                    await self.syncUserToFirestore(userId: user.uid)
                    await self.syncLocalActivitiesToFirestore(userId: user.uid)
                } else {
                    print("[AuthManager] User logged out")
                    AppSession.isUserAuthenticated = false
                    AppSession.userId = nil
                }
            }
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Phone Authentication (OTP)

    /// Initiates phone number verification via SMS OTP using the modern async Firebase API.
    /// - Parameter phoneNumber: E.164-formatted number, e.g. "+14155552671".
    /// - Returns: The verification ID needed to verify the SMS code.
    func sendOTP(phoneNumber: String) async throws -> String {
        let verificationID = try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
        // Persist so it survives backgrounding / memory pressure between send & verify.
        UserDefaults.standard.set(verificationID, forKey: Keys.authVerificationID)
        return verificationID
    }

    /// Verifies the 6-digit SMS code and signs the user in.
    @discardableResult
    func verifyOTP(verificationID: String, code: String) async throws -> User {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        return try await Auth.auth().signIn(with: credential).user
    }

    // MARK: - Email Link Authentication (Passwordless)

    /// Sends a passwordless sign-in link to the given email address.
    ///
    /// ### Why the URL is set to the bare domain root
    /// Firebase wraps our `continueURL` inside its own `/__/auth/action?...` redirect.
    /// If we pass `https://thepaceapp.firebaseapp.com/__/auth/action` the final URL
    /// becomes `…/__/auth/action?continueUrl=/__/auth/action&…`, which breaks.
    /// The bare domain `https://thepaceapp.firebaseapp.com` is correct — Firebase
    /// appends the action path itself.
    ///
    /// ### Why this domain (not the project-ID domain)
    /// The `applinks:` entry in PaceApp.entitlements is `thepaceapp.firebaseapp.com`.
    /// The continueURL domain MUST exactly match an applinks entry so iOS intercepts
    /// the link and delivers it to `onOpenURL` instead of opening Safari.
    func sendEmailLink(email: String) async throws {
        let settings = ActionCodeSettings()
        // ✅ Bare domain root — matches applinks: in entitlements exactly.
        settings.url = URL(string: EmailLinkDomain.continueURL)
        // ✅ Required: tells Firebase this link must be handled inside the app.
        settings.handleCodeInApp = true
        // ✅ Required: Firebase uses this to construct the Universal Link for iOS.
        settings.setIOSBundleID(Bundle.main.bundleIdentifier!)

        try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: settings)

        // Persist the email on THIS device so it is available when the link re-opens the app.
        // If the user opens the link on a different device, onOpenURL shows a re-entry prompt.
        UserDefaults.standard.set(email, forKey: Keys.emailForSignIn)
    }

    /// Returns true when `linkString` is a valid Firebase email sign-in link.
    func isSignIn(withEmailLink linkString: String) -> Bool {
        Auth.auth().isSignIn(withEmailLink: linkString)
    }

    /// Completes the email link sign-in. Called from `PaceApp.onOpenURL` after
    /// `isSignIn(withEmailLink:)` returns `true`.
    @discardableResult
    func signInWithEmailLink(email: String, link: String) async throws -> User {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty else {
            throw NSError(
                domain: "AuthManager", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Email address is required to complete sign-in."]
            )
        }
        let user = try await Auth.auth().signIn(withEmail: cleanEmail, link: link).user
        UserDefaults.standard.removeObject(forKey: Keys.emailForSignIn)
        return user
    }

    // MARK: - Sign Out & Delete Account

    func logout() async throws {
        try Auth.auth().signOut()
        ConnectIQManager.shared.disconnectFromApp()
        AppSession.removeAllData()
    }

    func deleteAccount() async throws {
        guard let user = currentUser else { return }
        let db = Firestore.firestore()
        let uid = user.uid
        let activitiesSnap = try await db.collection("users").document(uid)
            .collection("activities").getDocuments()
        for doc in activitiesSnap.documents { try await doc.reference.delete() }
        try await db.collection("users").document(uid).delete()
        try await user.delete()
        ConnectIQManager.shared.disconnectFromApp()
        AppSession.removeAllData()
    }

    // MARK: - Firestore Profile Sync

    func syncUserToFirestore(userId: String) async {
        guard let userModel = AppSession.userDetails else { return }
        let data: [String: Any] = [
            "uuid":        userId,
            "firstName":   userModel.firstName   ?? "",
            "lastName":    userModel.lastName    ?? "",
            "gender":      userModel.gender?.rawValue ?? "",
            "email":       userModel.email       ?? "",
            "phoneNumber": userModel.phoneNumber ?? "",
            "lastSyncedAt": FieldValue.serverTimestamp()
        ]
        do {
            try await Firestore.firestore()
                .collection("users").document(userId).setData(data, merge: true)
            print("[AuthManager] Synced profile to Firestore")
        } catch {
            print("[AuthManager] Firestore sync error: \(error.localizedDescription)")
        }
    }

    func fetchUserProfileInfo(userId: String) async throws -> UserModel {
        let snapshot = try await Firestore.firestore()
            .collection("users").document(userId).getDocument()
        guard let data = snapshot.data() else {
            throw NSError(domain: "AuthManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "User profile document not found."])
        }
        var model = AppSession.userDetails ?? UserModel(uuid: userId)
        if let v = data["firstName"]   as? String            { model.firstName   = v }
        if let v = data["lastName"]    as? String            { model.lastName    = v }
        if let v = data["gender"]      as? String,
           let g = Gender(rawValue: v)                       { model.gender      = g }
        if let v = data["email"]       as? String            { model.email       = v }
        if let v = data["phoneNumber"] as? String            { model.phoneNumber = v }
        AppSession.userDetails = model
        return model
    }

    // MARK: - Local Activity Sync (ConnectIQ → Firestore)

    private func syncLocalActivitiesToFirestore(userId: String) async {
        let db = Firestore.firestore()
        let active    = UserDefaults.standard.array(forKey: "connectIQ.syncedEvents")
                        as? [[String: Any]] ?? []
        let completed = UserDefaults.standard.array(forKey: "connectIQ.syncedCompletedEvents")
                        as? [[String: Any]] ?? []
        for payload in active + completed {
            let id: String
            if      let v = payload["id"] as? Int    { id = String(v) }
            else if let v = payload["id"] as? String { id = v }
            else { continue }
            let ref = db.collection("users").document(userId)
                .collection("activities").document(id)
            do { try await ref.setData(cleanPayloadForFirestore(payload), merge: true) }
            catch { print("[AuthManager] Failed to sync activity \(id): \(error.localizedDescription)") }
        }
    }

    private func cleanPayloadForFirestore(_ payload: [String: Any]) -> [String: Any] {
        var cleaned: [String: Any] = [:]
        for (key, value) in payload {
            if let arr = value as? NSArray {
                cleaned[key] = arr.compactMap { element -> Any? in
                    if let dict = element as? [String: Any] { return cleanPayloadForFirestore(dict) }
                    return element
                }
            } else if let dict = value as? [String: Any] {
                cleaned[key] = cleanPayloadForFirestore(dict)
            } else {
                cleaned[key] = value
            }
        }
        return cleaned
    }
}
