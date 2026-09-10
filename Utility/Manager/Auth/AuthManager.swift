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
	
	@ObservationIgnored
	private var _authStateListenerHandle: AuthStateDidChangeListenerHandle?

	/// Live Firestore listener on the user document — keeps `userDetails` in sync
	/// with changes the watch (or another device) writes to Firestore.
	@ObservationIgnored
	private var _profileListener: ListenerRegistrationToken?
	
	@ObservationIgnored
	private let logger = Logger(label: "AUTH")
	
	/// Held strongly so it isn't released while Firebase awaits reCAPTCHA.
	private var phoneAuthDelegate: PhoneAuthUIDelegate?

	/// True while an email-link re-authentication (for account deletion) is in flight,
	/// so the `onOpenURL` handler treats the returning link as reauth, not a fresh sign-in.
	var isReauthenticatingForDeletion = false

	/// Guards the "signed out on another device" flow so its alert fires at most once per session.
	@ObservationIgnored
	private var isEndingRemoteSession = false

	var currentUser: User? = Auth.auth().currentUser
	var userDetails: UserModel?
	var isUserAuthenticated: Bool { currentUser != nil }
	var currentUserID: String? { currentUser?.uid }
	
	// MARK: - Lifecycle
	
	private init() {}
	
	/// Call once from AppDelegate after FirebaseApp.configure().
	func configure() {
		guard _authStateListenerHandle == nil else { return }
		
		currentUser = Auth.auth().currentUser
		
		_authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
			guard let self else {
				
				return
			}
			Task { @MainActor in
				self.currentUser = user
				
				if let user {
					self.isEndingRemoteSession = false
					await self.loadOrCreateProfile(for: user)

					// Keep userDetails live — watch → Firestore → app updates flow
					// through this listener without any manual pull.
					self.startProfileListener(userId: user.uid)

					//Set the root navigation
					Router.shared.setupRootNavigation()

				} else {
					self.stopProfileListener()
					self.userDetails = nil

					try? await AuthManager.shared.logout()

					Router.shared.setRoot(.auth)
				}
			}
		}
	}
	
	deinit {
		if let handle = _authStateListenerHandle {
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
		try Auth.auth().signOut() //Logout from firebase
		AppSession.removeAllData() //Clear session from local
		ConnectIQManager.shared.disconnectFromApp() //Disconnect watch
		StravaManager.shared.stopObserving() //Drop Strava listener so next user re-attaches to their own doc
	}

	// MARK: - Re-authentication (for account deletion)

	/// How the current user signed in, with the contact used — drives the reauth flow.
	enum AuthProviderKind: Equatable {
		case phone(String)
		case email(String)
		case unknown
	}

	var authProviderKind: AuthProviderKind {
		guard let user = currentUser else { return .unknown }
		if let phone = user.phoneNumber, !phone.isEmpty { return .phone(phone) }
		if let email = user.email, !email.isEmpty { return .email(email) }
		for p in user.providerData {
			if p.providerID == PhoneAuthProviderID, let ph = p.phoneNumber, !ph.isEmpty { return .phone(ph) }
			if p.providerID == EmailAuthProviderID, let em = p.email, !em.isEmpty { return .email(em) }
		}
		return .unknown
	}

	/// Sends a fresh OTP to the signed-in user's own phone. Returns the verificationID.
	func sendReauthOTP() async throws -> String {
		guard case let .phone(number) = authProviderKind else {
			throw NSError(domain: "AuthManager", code: -1,
						  userInfo: [NSLocalizedDescriptionKey: "This account has no phone number to verify."])
		}
		return try await sendOTP(phoneNumber: number)
	}

	/// Re-authenticates the current user with a phone OTP (no sign-out).
	func reauthenticateWithPhone(verificationID: String, code: String) async throws {
		guard let user = currentUser else {
			throw NSError(domain: "AuthManager", code: -1,
						  userInfo: [NSLocalizedDescriptionKey: "You're not signed in."])
		}
		let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
		try await user.reauthenticate(with: credential)
	}

	/// Sends a sign-in link to the signed-in user's own email for reauth (no sign-out).
	func sendReauthEmailLink() async throws {
		guard case let .email(email) = authProviderKind else {
			throw NSError(domain: "AuthManager", code: -1,
						  userInfo: [NSLocalizedDescriptionKey: "This account has no email to verify."])
		}
		try await sendEmailLink(email: email)
		isReauthenticatingForDeletion = true
	}

	/// Re-authenticates the current user with an email link, then clears the reauth flag.
	func reauthenticateWithEmailLink(link: String) async throws {
		guard let user = currentUser, case let .email(email) = authProviderKind else {
			throw NSError(domain: "AuthManager", code: -1,
						  userInfo: [NSLocalizedDescriptionKey: "You're not signed in."])
		}
		let credential = EmailAuthProvider.credential(withEmail: email, link: link)
		try await user.reauthenticate(with: credential)
		isReauthenticatingForDeletion = false
	}
	
	func deleteAccount() async throws {
		guard let user = currentUser else { return }
		let db  = Firestore.firestore()
		let uid = user.uid

		//Disconnect the watch first so its live sync can't re-create events or write
		//to Firestore mid-deletion (which floods "permission denied" once signed out).
		ConnectIQManager.shared.disconnectFromApp()

		//Stop the live profile listener so deleting the user doc below doesn't fire it.
		stopProfileListener()

		//Revoke Strava on the server (best-effort) while the ID token is still valid, then drop the listener.
		await StravaManager.shared.disconnectForAccountDeletion()

		//Best-effort data cleanup — a failed read/write must NOT abort the account
		//deletion below, else the user doc + Auth account get left behind.
		await deleteDocuments(matching: db.collection("events").whereField("userId", isEqualTo: uid), label: "events")
		await deleteDocuments(matching: db.collection("favorites").whereField("userId", isEqualTo: uid), label: "favorites")
		await deleteDocuments(matching: db.collection("users").document(uid).collection("activities"), label: "legacy activities")

		//Delete the profile doc, then the Auth account — both while still authenticated.
		//user.delete() propagates so a rare failure surfaces instead of a silent half-delete.
		try? await db.collection("users").document(uid).delete()
		try await user.delete()

		//Guarantee the keychain-persisted auth session is gone even if delete failed
		try? Auth.auth().signOut()

		//Clear cached profile + all local session
		userDetails = nil
		currentUser = nil
		AppSession.removeAllData()
	}
	
	// Best-effort bulk delete — never throws, but logs so a skipped cleanup
	// (which orphans docs under a dead uid) is visible instead of silent.
	private func deleteDocuments(matching query: Query, label: String) async {
		do {
			let snapshot = try await query.getDocuments()
			for doc in snapshot.documents { try? await doc.reference.delete() }
		} catch {
			logger.warning("Account delete: \(label) cleanup skipped — \(error.localizedDescription)")
		}
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

	/// Loads the signed-in user's profile, creating one only for a genuinely new account.
	/// A cache-first miss (fresh device) or a transient failure must NEVER seed an empty
	/// profile over an existing one — so "missing" is confirmed against the server first.
	private func loadOrCreateProfile(for user: User) async {
		if let model = try? await UserProfileRepository.shared.fetchProfile(userId: user.uid) {
			self.userDetails = model
			return
		}
		switch await UserProfileRepository.shared.fetchProfileFromServer(userId: user.uid) {
		case .found(let model):
			self.userDetails = model
		case .missing:
			await seedNewUser(user)
		case .unreachable:
			// Don't create/overwrite while offline — the live profile listener fills userDetails in.
			logger.error("Profile unresolved for \(user.uid) (server unreachable) — keeping session, not seeding.")
		}
	}

	/// Seeds a minimal profile for a brand-new account (confirmed absent on the server).
	private func seedNewUser(_ user: User) async {
		logger.info("No profile for \(user.uid) — seeding a new user document.")
		var initial = UserModel(uuid: user.uid)
		initial.email = user.email
		initial.phoneNumber = user.phoneNumber
		initial.firstName = user.displayName ?? ""
		self.userDetails = initial
		try? await UserProfileRepository.shared.upsertProfile(initial, userId: user.uid)
	}
	
	// MARK: - Live Profile Listener

	/// Attaches a real-time listener on the user document. Every change (including
	/// settings the watch syncs into Firestore) refreshes `userDetails`, which the
	/// UI observes — so the Profile screen updates instantly, no relaunch needed.
	private func startProfileListener(userId: String) {
		_profileListener?.remove()
		_profileListener = UserProfileRepository.shared.listenToProfile(userId: userId) { [weak self] model in
			Task { @MainActor in
				guard let self else { return }
				guard let model else {
					// Doc vanished or the listener was denied — the account may have been deleted
					// on another device; verify before ending this device's session.
					self.verifySessionOrSignOut()
					return
				}
				self.userDetails = model
			}
		}
	}

	private func stopProfileListener() {
		_profileListener?.remove()
		_profileListener = nil
	}

	/// Confirms the signed-in account still exists on the server by forcing a token refresh —
	/// a deleted/disabled account's refresh token is rejected (which `reload()` can miss while
	/// the cached ID token is still unexpired), and it also invalidates the token Firestore uses.
	/// On a confirmed removal it signs this device out (+ alert) and returns false; a network
	/// blip returns true so a valid user isn't logged out while offline. Call on foreground and
	/// before sensitive writes so nothing runs on a dead session.
	@discardableResult
	func verifyAccountStillValid() async -> Bool {
		guard !isReauthenticatingForDeletion, let user = currentUser else { return false }
		guard !isEndingRemoteSession else { return true }   // a check is already in flight
		isEndingRemoteSession = true
		do {
			_ = try await user.getIDTokenResult(forcingRefresh: true)
			isEndingRemoteSession = false
			return true
		} catch {
			let ns = error as NSError
			if ns.domain == AuthErrorDomain, AuthErrorCode(rawValue: ns.code) == .networkError {
				isEndingRemoteSession = false   // offline — don't block a valid user
				return true
			}
			endRemotelyEndedSession()           // account genuinely gone → end the session
			return false
		}
	}

	/// Fire-and-forget account check used by the live profile listener when its snapshot
	/// vanishes or is denied — routes through the network-blip-safe validity check.
	private func verifySessionOrSignOut() {
		Task { @MainActor in _ = await self.verifyAccountStillValid() }
	}

	/// Signs out locally and tells the user their session ended elsewhere. The auth-state
	/// listener tears down the watch/Strava/session and routes back to sign-in.
	private func endRemotelyEndedSession() {
		logger.info("Account no longer exists on the server — ending session on this device.")
		stopProfileListener()
		try? Auth.auth().signOut()
		AppAlertManager.shared.present(
			AppAlertModel(
				title: "Session expired",
				description: "Your session has timed out. Please sign in again.",
				primaryButton: AppAlertButton("OK"),
				restrictOutsideTap: true
			)
		)
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
