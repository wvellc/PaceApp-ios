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

    var currentUser: User? = Auth.auth().currentUser
    var userDetails: UserModel?
    var isUserAuthenticated: Bool { currentUser != nil }
    var currentUserID: String? { currentUser?.uid }

    // MARK: - Lifecycle

    private init() {}

    /// Call once from AppDelegate after FirebaseApp.configure().
    func configure() {
        guard authStateListenerHandle == nil else { return }

        currentUser = Auth.auth().currentUser

        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.currentUser = user

                if let user {
                    // Silently refresh profile in the background.
                    // IMPORTANT: Do NOT call setupRootNavigation() here.
                    // Navigation after OTP sign-in is driven exclusively by
                    // OTPVerificationViewModel.onOTPVerified, which waits for
                    // this fetch to complete before routing. Calling
                    // setupRootNavigation() here races with that callback and
                    // can route to .auth before userDetails is populated.
                    do {
                        _ = try await self.fetchUserProfileInfo(userId: user.uid)
                    } catch {
                        let nsError = error as NSError
                        if nsError.domain == "AuthManager" && nsError.code == 404 {
                            // Brand-new user — no Firestore document exists yet.
                            // Seed a minimal model from the Firebase Auth record.
                            self.logger.info("No Firestore profile found for \(user.uid) — seeding new user document.")
                            var initial = UserModel(uuid: user.uid)
                            initial.email = user.email
                            initial.phoneNumber = user.phoneNumber
                            self.userDetails = initial
                            do {
                                try await UserProfileRepository.shared.upsertProfile(initial, userId: user.uid)
                            } catch {
                                self.logger.error("Failed to create initial profile for \(user.uid): \(error.localizedDescription)")
                            }
                        } else {
                            // Network or permissions failure — fall back to a
                            // placeholder so the app can still route correctly.
                            self.logger.error("Profile fetch failed for \(user.uid): \(error.localizedDescription)")
                            var placeholder = UserModel(uuid: user.uid)
                            placeholder.email = user.email
                            placeholder.phoneNumber = user.phoneNumber
                            self.userDetails = placeholder
                            self.logger.warning("Running with placeholder profile — settings (gait, vibrate, beep, distanceUnit) will use defaults until next successful fetch.")
                        }
                    }

                    // Only navigate if already on dashboard/accountCreation and
                    // the profile completion status changed (e.g. user updated profile).
                    if Router.shared.root == .accountCreation && self.userDetails?.isProfileCompleted == true {
                        Router.shared.setupRootNavigation()
                    }

                } else {
                    self.userDetails = nil
                    AppSession.removeAllData()
                    if Router.shared.root == .dashboard || Router.shared.root == .accountCreation {
                        Router.shared.setRoot(.auth, forward: false)
                    }
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

    /// Sends an SMS OTP to the given E.164-formatted number and returns the verificationID.
    func sendOTP(phoneNumber: String) async throws -> String {
        // Hold delegate strongly on self — it must survive the await suspension
        // while Firebase either sends the silent APNs push or shows reCAPTCHA.
        let delegate = PhoneAuthUIDelegate()
        phoneAuthDelegate = delegate

        let verificationID = try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: delegate)

        phoneAuthDelegate = nil
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
    }

    func deleteAccount() async throws {
        guard let user = currentUser else { return }
        let db  = Firestore.firestore()
        let uid = user.uid
        let events    = try await db.collection("events").whereField("userId", isEqualTo: uid).getDocuments()
        for doc in events.documents    { try? await doc.reference.delete() }
        let favorites = try await db.collection("favorites").whereField("userId", isEqualTo: uid).getDocuments()
        for doc in favorites.documents { try? await doc.reference.delete() }
        let legacy    = try await db.collection("users").document(uid).collection("activities").getDocuments()
        for doc in legacy.documents    { try? await doc.reference.delete() }
        try? await db.collection("users").document(uid).delete()
        try? await user.delete()
        ConnectIQManager.shared.disconnectFromApp()
    }

    // MARK: - Firestore Sync

    func syncUserToFirestore(userId: String) async {
        guard let model = userDetails else {
            logger.warning("syncUserToFirestore called but userDetails is nil — skipping.")
            return
        }
        do {
            try await UserProfileRepository.shared.upsertProfile(model, userId: userId)
        } catch {
            logger.error("Firestore user sync failed for \(userId): \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch Profile

    /// Fetches the full user profile from Firestore — including gait, vibrate,
    /// beep, and distance unit settings — and caches it in `userDetails`.
    /// Called on every authenticated app launch via the auth state listener.
    @discardableResult
    func fetchUserProfileInfo(userId: String) async throws -> UserModel {
        logger.info("Fetching profile and settings for user \(userId)...")
        do {
            let model = try await UserProfileRepository.shared.fetchProfile(userId: userId)
            self.userDetails = model
            logFetchedSettings(model, userId: userId)
            return model
        } catch {
            logger.error("Failed to fetch profile for \(userId): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private Helpers

    /// Logs which settings were successfully loaded vs missing (will use defaults).
    private func logFetchedSettings(_ model: UserModel, userId: String) {
        logger.info("Profile loaded for \(userId).")

        if model.gait != nil {
            logger.info("[Settings] gait — loaded ✓")
        } else {
            logger.warning("[Settings] gait — not set, will use gender default.")
        }

        if let vibrate = model.intervalVibrate {
            logger.info("[Settings] intervalVibrate — loaded: \(vibrate) ✓")
        } else {
            logger.warning("[Settings] intervalVibrate — not set, defaulting to false.")
        }

        if let beep = model.intervalBeep {
            logger.info("[Settings] intervalBeep — loaded: \(beep) ✓")
        } else {
            logger.warning("[Settings] intervalBeep — not set, defaulting to false.")
        }

        if let unit = model.distanceUnit {
            logger.info("[Settings] distanceUnit — loaded: \(unit.rawValue) ✓")
        } else {
            logger.warning("[Settings] distanceUnit — not set, defaulting to Miles.")
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
        if let t = vc as? UITabBarController,    let s = t.selectedViewController { return top(s) }
        return vc
    }
}
