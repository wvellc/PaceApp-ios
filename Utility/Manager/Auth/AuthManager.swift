//
//  AuthManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 06/03/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Logging
import UIKit

/// Central coordinator for Firebase Authentication and Firestore user sync.
@Observable
@MainActor
final class AuthManager {

    // MARK: - Singleton

    static let shared = AuthManager()

    // MARK: - Properties

    nonisolated(unsafe) private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private let logger = Logger(label: "net.paceapp.auth")

    /// Held strongly so it isn't released while Firebase awaits reCAPTCHA.
    private var phoneAuthDelegate: PhoneAuthUIDelegate?

    var currentUser: User? { Auth.auth().currentUser }
    var isUserAuthenticated: Bool { currentUser != nil }

    // MARK: - Lifecycle

    private init() {}

    /// Call once from AppDelegate after FirebaseApp.configure().
    func configure() {
        guard authStateListenerHandle == nil else { return }
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    AppSession.isUserAuthenticated = true
                    AppSession.userId = user.uid
                    var cached = AppSession.userDetails ?? UserModel(uuid: user.uid)
                    cached.uuid = user.uid
                    if cached.email == nil      { cached.email       = user.email }
                    if cached.phoneNumber == nil { cached.phoneNumber = user.phoneNumber }
                    AppSession.userDetails = cached
                    await self.syncUserToFirestore(userId: user.uid)
                    await self.syncLocalActivitiesToFirestore(userId: user.uid)
                } else {
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

    // MARK: - Phone Auth (OTP)

    /// Sends an SMS OTP to the given E.164-formatted number.
    /// Stores the verificationID in UserDefaults for use in `verifyOTP`.
    func sendOTP(phoneNumber: String) async throws -> String {
        // Hold delegate strongly on self — it must survive the await suspension
        // while Firebase either sends the silent APNs push or shows reCAPTCHA.
        let delegate = PhoneAuthUIDelegate()
        phoneAuthDelegate = delegate

        let verificationID = try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: delegate)

        phoneAuthDelegate = nil
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

    // MARK: - Email Link Auth (Passwordless)

    func sendEmailLink(email: String) async throws {
        let settings = ActionCodeSettings()
        settings.url = URL(string: "https://thepaceapp.firebaseapp.com")
        settings.handleCodeInApp = true
        settings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: settings)
        UserDefaults.standard.set(email, forKey: Keys.emailForSignIn)
    }

    func isSignIn(withEmailLink link: String) -> Bool {
        Auth.auth().isSignIn(withEmailLink: link)
    }

    @discardableResult
    func signInWithEmailLink(email: String, link: String) async throws -> User {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            throw NSError(domain: "AuthManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Email is required to complete sign-in."])
        }
        let user = try await Auth.auth().signIn(withEmail: clean, link: link).user
        UserDefaults.standard.removeObject(forKey: Keys.emailForSignIn)
        return user
    }

    // MARK: - Sign Out / Delete

    func logout() async throws {
        try Auth.auth().signOut()
        ConnectIQManager.shared.disconnectFromApp()
        AppSession.removeAllData()
    }

    func deleteAccount() async throws {
        guard let user = currentUser else { return }
        let db = Firestore.firestore()
        let uid = user.uid
        let snap = try await db.collection("users").document(uid).collection("activities").getDocuments()
        for doc in snap.documents { try? await doc.reference.delete() }
        try? await db.collection("users").document(uid).delete()
        try? await user.delete()
        ConnectIQManager.shared.disconnectFromApp()
        AppSession.removeAllData()
    }

    // MARK: - Firestore Sync

    func syncUserToFirestore(userId: String) async {
        guard let model = AppSession.userDetails else { return }
        let data: [String: Any] = [
            "uuid":        userId,
            "firstName":   model.firstName   ?? "",
            "lastName":    model.lastName    ?? "",
            "gender":      model.gender?.rawValue ?? "",
            "email":       model.email       ?? "",
            "phoneNumber": model.phoneNumber ?? "",
            "lastSyncedAt": FieldValue.serverTimestamp()
        ]
        do {
            try await Firestore.firestore().collection("users").document(userId).setData(data, merge: true)
        } catch {
            logger.error("Firestore user sync failed: \(error.localizedDescription)")
        }
    }

    func fetchUserProfileInfo(userId: String) async throws -> UserModel {
        let snap = try await Firestore.firestore().collection("users").document(userId).getDocument()
        guard let data = snap.data() else {
            throw NSError(domain: "AuthManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "User profile not found."])
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

    // MARK: - Local Activity Sync

    private func syncLocalActivitiesToFirestore(userId: String) async {
        let db = Firestore.firestore()
        let active    = UserDefaults.standard.array(forKey: "connectIQ.syncedEvents")           as? [[String: Any]] ?? []
        let completed = UserDefaults.standard.array(forKey: "connectIQ.syncedCompletedEvents")  as? [[String: Any]] ?? []
        for payload in active + completed {
            let id: String
            if      let v = payload["id"] as? Int    { id = String(v) }
            else if let v = payload["id"] as? String { id = v }
            else { continue }
            do {
                try await db.collection("users").document(userId)
                    .collection("activities").document(id)
                    .setData(cleanPayload(payload), merge: true)
            } catch {
                logger.error("Activity sync failed id=\(id): \(error.localizedDescription)")
            }
        }
    }

    private func cleanPayload(_ payload: [String: Any]) -> [String: Any] {
        payload.mapValues { value -> Any in
            if let arr = value as? NSArray {
                return arr.compactMap { ($0 as? [String: Any]).map { cleanPayload($0) } ?? $0 }
            } else if let dict = value as? [String: Any] {
                return cleanPayload(dict)
            }
            return value
        }
    }
}

// MARK: - PhoneAuthUIDelegate

/// Presents Firebase's reCAPTCHA web view when APNs silent push is unavailable.
/// Must be held strongly by the caller for the duration of the verifyPhoneNumber call.
private final class PhoneAuthUIDelegate: NSObject, AuthUIDelegate {

    func present(_ vc: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        topVC()?.present(vc, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        topVC()?.dismiss(animated: animated, completion: completion)
    }

    private func topVC() -> UIViewController? {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: \.isKeyWindow)?
            .rootViewController
        else { return nil }
        return top(root)
    }

    private func top(_ vc: UIViewController) -> UIViewController {
        if let p = vc.presentedViewController { return top(p) }
        if let n = vc as? UINavigationController, let t = n.topViewController { return top(t) }
        if let t = vc as? UITabBarController, let s = t.selectedViewController { return top(s) }
        return vc
    }
}
