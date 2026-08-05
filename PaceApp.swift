//
//  PaceApp.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/10/26.
//

import SwiftUI
import FirebaseAuth
import Logging

@main
struct PaceApp: App {
	
	// SwiftUI to use your AppDelegate
	@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
	
	// MARK: - Properties
	
	/// Central router that manages navigation path and destination resolution.
	@State private var router = Router.shared
	@State private var ciqManager = ConnectIQManager.shared
	@State private var stravaManager = StravaManager.shared
	
	// MARK: - Initialization
	
	/// Configure global UI appearance for navigation components on app launch.
	init() {
		setNavigationAppearance()
		configureSegmentedAppearance()
		// AuthManager.configure() is called in AppDelegate after FirebaseApp.configure().
	}
	
	// MARK: - Scene
	
	var body: some Scene {
		WindowGroup {
			NavigationStack(path: $router.path) {
				router.rootView()
					.navigationDestination(for: Destinations.self) { dest in
						router.destination(for: dest)
							.onDisappear {
								UIApplication.shared.sendAction(
									#selector(UIResponder.resignFirstResponder),
									to: nil, from: nil, for: nil
								)
							}
					}
					.dismissKeyboardOnTap()
			}
			.tint(.radiantBlue)
			.preferredColorScheme(.light)
			.environment(router)
			.environment(ciqManager)
			.environment(stravaManager)
			.appBackground()
			.installToast(position: .top)
			.installAppAlert()
			
			// MARK: URL / Deep Link handler
			//
			// All URL types arrive here in SwiftUI. We must handle them in priority order:
			//  1. Firebase reCAPTCHA callback  — reversed-client-ID custom scheme
			//  2. Firebase email sign-in link  — universal link (thepaceapp.firebaseapp.com)
			//  3. ConnectIQ                    — everything else
			.onOpenURL { url in
				logger.debug("Received app URL: \(url.absoluteString)")
				
				// Priority 1 — Firebase reCAPTCHA / phone-auth callback.
				// Must be checked BEFORE email-link check because canHandle()
				// matches the reversed-client-ID scheme used by reCAPTCHA.
				if Auth.auth().canHandle(url) {
					return
				}
				
				// Priority 2 — Strava OAuth callback (paceapp:// deep link or universal link).
				if StravaManager.isStravaCallback(url) {
					stravaManager.handleOpenURL(url)
					return
				}

				// Priority 3 — Firebase email sign-in link.
				guard AuthManager.shared.isSignIn(withEmailLink: url.absoluteString) else {
					// Priority 4 — ConnectIQ or other custom schemes.
					ciqManager.handleOpenURL(url)
					return
				}
				
				// Re-authentication for account deletion — keep the user signed in,
				// reauthenticate with the link, then delete. No fresh sign-in.
				if AuthManager.shared.isReauthenticatingForDeletion,
				   AuthManager.shared.currentUser != nil {
					Task { @MainActor in
						do {
							try await AuthManager.shared.reauthenticateWithEmailLink(link: url.absoluteString)
							try await AuthManager.shared.deleteAccount()
							ToastManager.shared.present(.success("Your account has been deleted."))
						} catch {
							AuthManager.shared.isReauthenticatingForDeletion = false
							ToastManager.shared.present(.error(AuthErrorMapper.message(for: error)))
						}
					}
					return
				}

				let savedEmail = UserDefaults.standard.string(forKey: Keys.emailForSignIn) ?? ""

				guard !savedEmail.isEmpty else {
					ToastManager.shared.present(
						.error("Please open this link on the device where you requested it, or request a new login link.")
					)
					router.setRoot(.auth, forward: false)
					return
				}
				
				router.setRoot(.authenticating, forward: true)
				
				Task { @MainActor in
					do {
						let user = try await AuthManager.shared.signInWithEmailLink(
							email: savedEmail,
							link: url.absoluteString
						)
						logger.info("Email link sign-in succeeded: \(user.uid)")
						// waitForUserDetails is handled by the auth state listener path;
						// here we explicitly fetch before routing for determinism.
						do {
							_ = try await AuthManager.shared.fetchUserProfileInfo(userId: user.uid)
						} catch {
							let nsError = error as NSError
							if nsError.domain == "AuthManager" && nsError.code == 404 {
								var initial = UserModel(uuid: user.uid)
								initial.email = user.email
								AuthManager.shared.userDetails = initial
								await AuthManager.shared.syncUserToFirestore(userId: user.uid)
							} else {
								var placeholder = UserModel(uuid: user.uid)
								placeholder.email = user.email
								AuthManager.shared.userDetails = placeholder
							}
						}
						router.setupRootNavigation()
					} catch {
						logger.error("Email link sign-in failed: \(error.localizedDescription)")
						ToastManager.shared.present(.error(AuthErrorMapper.message(for: error)))
						router.setRoot(.auth, forward: false)
					}
				}
			}
            // Cold-launch watch restoration + pending event resync.
            // restoreSessionIfNeeded() rebuilds device registrations and triggers
            // loadPersistedStateFromFirestore(). resyncPendingEvents() then forwards
            // any events that were marked pending in a previous session.
            .task {
                ciqManager.restoreSessionIfNeeded()
                await ciqManager.resyncPendingEvents()
            }
		}
	}
	
	// MARK: - Appearance Configuration
	
	fileprivate func setNavigationAppearance() {
		let appearance = UINavigationBarAppearance()
		appearance.configureWithTransparentBackground()
		appearance.backgroundColor = .clear
		appearance.shadowColor = .clear
		
		let titleFont      = UIFont.systemFont(ofSize: 16, weight: .medium)
		let largeTitleFont = UIFont.systemFont(ofSize: 34, weight: .semibold)
		
		appearance.titleTextAttributes = [
			.foregroundColor: UIColor.whiteApp,
			.font: titleFont
		]
		appearance.largeTitleTextAttributes = [
			.foregroundColor: UIColor.whiteApp,
			.font: largeTitleFont
		]
		
		let navBarProxy = UINavigationBar.appearance()
		navBarProxy.standardAppearance   = appearance
		navBarProxy.scrollEdgeAppearance = appearance
		navBarProxy.compactAppearance    = appearance
		navBarProxy.tintColor = .whiteApp
		
		UITextField.appearance().keyboardAppearance = .dark
	}
	
	fileprivate func configureSegmentedAppearance() {
		let appearance = UISegmentedControl.appearance()
		appearance.backgroundColor = .grayHint
		appearance.selectedSegmentTintColor = .neonAquaBlue
		appearance.setTitleTextAttributes([.foregroundColor: UIColor.whiteApp],     for: .selected)
		appearance.setTitleTextAttributes([.foregroundColor: UIColor.darkCharcoal], for: .normal)
	}
}
