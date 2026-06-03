//
//  AuthManager.swift
//  PaceApp
//
//  Created by Antigravity on 06/03/26.
//

import Foundation
import FirebaseCore
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
    nonisolated(unsafe) private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    var currentUser: User? {
        Auth.auth().currentUser
    }
    
    var isUserAuthenticated: Bool {
        currentUser != nil
    }
    
    // MARK: - Lifecycle & Configuration
    
    private init() {}
    
    /// Registers the global authentication state listener.
    /// Call this from `PaceApp.swift` or `AppDelegate.swift` on launch.
    func configure() {
        guard authStateListenerHandle == nil else { return }
        
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let user = user {
                    print("[AuthManager] User logged in: \(user.uid)")
                    AppSession.isUserAuthenticated = true
                    AppSession.userId = user.uid
                    
                    // Retrieve/update user session details
                    var cachedUser = AppSession.userDetails ?? UserModel(uuid: user.uid)
                    cachedUser.uuid = user.uid
                    if cachedUser.email == nil {
                        cachedUser.email = user.email
                    }
                    if cachedUser.phoneNumber == nil {
                        cachedUser.phoneNumber = user.phoneNumber
                    }
                    AppSession.userDetails = cachedUser
                    
                    // Sync to Firestore
                    await self.syncUserToFirestore(userId: user.uid)
                    // Sync watch events
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
    
    /// Initiates phone number verification via SMS OTP.
    /// - Parameter phoneNumber: The normalized phone number in E.164 format.
    /// - Returns: The verification ID needed to verify the code.
    func sendOTP(phoneNumber: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let verificationID = verificationID {
                    continuation.resume(returning: verificationID)
                } else {
                    continuation.resume(throwing: NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verification ID is nil"]))
                }
            }
        }
    }
    
    /// Verifies the SMS verification code and signs the user in.
    /// - Parameters:
    ///   - verificationID: The verification ID returned by `sendOTP`.
    ///   - code: The 6-digit SMS code entered by the user.
    /// - Returns: The authenticated Firebase `User`.
    @discardableResult
    func verifyOTP(verificationID: String, code: String) async throws -> User {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user
    }
    
    // MARK: - Email Link Authentication (Passwordless)
    
    /// Sends a sign-in link to the specified email address.
    /// - Parameter email: The user's email address.
    func sendEmailLink(email: String) async throws {
        let actionCodeSettings = ActionCodeSettings()
        // Default link that handles sign in inside the app.
        // Make sure this matches the domain allowed in console (default project domain)
        let fallbackURL = "https://\(FirebaseApp.app()?.options.projectID ?? "thepaceapp").firebaseapp.com/__/auth/action"
        actionCodeSettings.url = URL(string: fallbackURL)
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
        
        // Save email locally to complete login on link redirect
        UserDefaults.standard.set(email, forKey: "emailForSignIn")
    }
    
    /// Checks if a dynamic/universal link is a sign-in link.
    func isSignIn(withEmailLink linkString: String) -> Bool {
        return Auth.auth().isSignIn(withEmailLink: linkString)
    }
    
    /// Signs in a user using the email and the sign-in link retrieved from the openURL handler.
    /// - Parameters:
    ///   - email: The email address the link was sent to (retrieved from UserDefaults or user entry).
    ///   - link: The absolute string URL received when opening the app.
    /// - Returns: The authenticated Firebase `User`.
    @discardableResult
    func signInWithEmailLink(email: String, link: String) async throws -> User {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email address is required to complete sign-in."])
        }
        let authResult = try await Auth.auth().signIn(withEmail: cleanEmail, link: link)
        UserDefaults.standard.removeObject(forKey: "emailForSignIn")
        return authResult.user
    }
    
    // MARK: - Sign Out & Delete Account
    
    /// Logs the user out of Firebase and clears the local session.
    func logout() async throws {
        try Auth.auth().signOut()
        
        // Clear all sync and session data locally
        ConnectIQManager.shared.disconnectFromApp()
        AppSession.removeAllData()
    }
    
    /// Deletes the current user profile from Firebase and Firestore, then logs out.
    func deleteAccount() async throws {
        guard let user = currentUser else { return }
        
        let db = Firestore.firestore()
        let userId = user.uid
        
        // 1. Delete activities subcollection in Firestore
        let activitiesSnapshot = try await db.collection("users").document(userId).collection("activities").getDocuments()
        for doc in activitiesSnapshot.documents {
            try await doc.reference.delete()
        }
        
        // 2. Delete user document in Firestore
        try await db.collection("users").document(userId).delete()
        
        // 3. Delete user account from Firebase Auth
        try await user.delete()
        
        // 4. Clean up local session
        ConnectIQManager.shared.disconnectFromApp()
        AppSession.removeAllData()
    }
    
    // MARK: - Firestore Profile Operations
    
    /// Synchronizes the current user's profile information to Firestore.
    func syncUserToFirestore(userId: String) async {
        guard let userModel = AppSession.userDetails else { return }
        
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userId)
        
        let data: [String: Any] = [
            "uuid": userId,
            "firstName": userModel.firstName ?? "",
            "lastName": userModel.lastName ?? "",
            "gender": userModel.gender?.rawValue ?? "",
            "email": userModel.email ?? "",
            "phoneNumber": userModel.phoneNumber ?? "",
            "lastSyncedAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await ref.setData(data, merge: true)
            print("[AuthManager] Successfully synced user profile info to Firestore")
        } catch {
            print("[AuthManager] Error syncing user profile info to Firestore: \(error.localizedDescription)")
        }
    }
    
    /// Retrieves user profile details from Firestore and merges them into the local session.
    func fetchUserProfileInfo(userId: String) async throws -> UserModel {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("users").document(userId).getDocument()
        
        guard let data = snapshot.data() else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile document not found."])
        }
        
        var userModel = AppSession.userDetails ?? UserModel(uuid: userId)
        if let firstName = data["firstName"] as? String { userModel.firstName = firstName }
        if let lastName = data["lastName"] as? String { userModel.lastName = lastName }
        if let genderRaw = data["gender"] as? String, let gender = Gender(rawValue: genderRaw) { userModel.gender = gender }
        if let email = data["email"] as? String { userModel.email = email }
        if let phoneNumber = data["phoneNumber"] as? String { userModel.phoneNumber = phoneNumber }
        
        AppSession.userDetails = userModel
        return userModel
    }
    
    // MARK: - Local watch events to Firestore Sync helper
    
    /// Uploads any locally cached watch events to Firestore after authentication.
    private func syncLocalActivitiesToFirestore(userId: String) async {
        let db = Firestore.firestore()
        
        // Combine active and completed activities
        let activeEvents = UserDefaults.standard.array(forKey: "connectIQ.syncedEvents") as? [[String: Any]] ?? []
        let completedEvents = UserDefaults.standard.array(forKey: "connectIQ.syncedCompletedEvents") as? [[String: Any]] ?? []
        let allEvents = activeEvents + completedEvents
        
        for payload in allEvents {
            let id: String
            if let syncId = payload["id"] as? Int {
                id = String(syncId)
            } else if let syncId = payload["id"] as? String {
                id = syncId
            } else {
                continue
            }
            
            let ref = db.collection("users").document(userId).collection("activities").document(id)
            
            // Clean payload to ensure it is Firestore compatible (contains only basic JSON types)
            let cleanedPayload = cleanPayloadForFirestore(payload)
            
            do {
                try await ref.setData(cleanedPayload, merge: true)
            } catch {
                print("[AuthManager] Failed to upload local activity \(id): \(error.localizedDescription)")
            }
        }
    }
    
    /// Helper to convert payload structures (like nested Arrays or NSObjects) into Firestore-compatible values.
    private func cleanPayloadForFirestore(_ payload: [String: Any]) -> [String: Any] {
        var cleaned: [String: Any] = [:]
        for (key, value) in payload {
            if let nsArray = value as? NSArray {
                cleaned[key] = nsArray.compactMap { element -> Any? in
                    if let dict = element as? [String: Any] {
                        return cleanPayloadForFirestore(dict)
                    }
                    return element
                }
            } else if let nestedDict = value as? [String: Any] {
                cleaned[key] = cleanPayloadForFirestore(nestedDict)
            } else {
                cleaned[key] = value
            }
        }
        return cleaned
    }
}
