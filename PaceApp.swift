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
    @State private var router = Router()
    @State private var ciqManager = ConnectIQManager.shared
    private let logger = Logger(label: "net.paceapp")

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
            .appBackground()
            .environment(ciqManager)
            .installToast(position: .top)
            .installAppAlert()

            // MARK: Universal Link / Deep Link handler
            //
            // Firebase email-link sign-in flow:
            //  1. User taps "Send Login Link" → AuthManager.sendEmailLink() sends the email.
            //  2. User taps the link in their email client.
            //  3. iOS matches the link domain against the `applinks:` entitlement entry
            //     (thepaceapp.firebaseapp.com) and calls this handler instead of Safari.
            //  4. We verify it is a sign-in link, retrieve the saved email, and sign in.
            .onOpenURL { url in
                logger.debug("Received app URL", metadata: [
                    "url": "\(url.absoluteString)"
                ])

                guard AuthManager.shared.isSignIn(withEmailLink: url.absoluteString) else {
                    // Not a Firebase email link — forward to ConnectIQ.
                    ciqManager.handleOpenURL(url)
                    return
                }

                Task { @MainActor in
                    // Retrieve the email that was saved when the link was sent.
                    // This MUST be the same device — Firebase email links are device-bound.
                    let savedEmail = UserDefaults.standard.string(forKey: Keys.emailForSignIn) ?? ""

                    guard !savedEmail.isEmpty else {
                        // Link opened on a different device: the email is unknown.
                        // Navigate back to Login so the user can re-enter it.
                        ToastManager.shared.present(
                            .error("Please open this link on the device where you requested it, or request a new login link.")
                        )
                        router.setRoot(.auth, forward: false)
                        return
                    }

                    do {
                        let user = try await AuthManager.shared.signInWithEmailLink(
                            email: savedEmail,
                            link: url.absoluteString
                        )
                        logger.info("Email link sign-in succeeded", metadata: [
                            "userId": "\(user.uid)"
                        ])
                        router.setupRootNavigation()
                    } catch {
                        ToastManager.shared.present(.error(error.localizedDescription))
                    }
                }
            }
            // Cold-launch watch restoration
            .task { ciqManager.restoreSessionIfNeeded() }
            // Session-based root navigation after splash
            .task { await resolveStartupRoot() }
        }
    }

    // MARK: - Startup Root Resolution

    @MainActor
    private func resolveStartupRoot() async {
        try? await Task.sleep(for: .milliseconds(1600))
        router.setupRootNavigation()
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
