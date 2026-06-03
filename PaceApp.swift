//
//  PaceApp.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/10/26.
//

import SwiftUI
import FirebaseAuth

@main
struct PaceApp: App {

    // SwiftUI to use your AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - Properties

    /// Central router that manages navigation path and destination resolution.
    @State private var router = Router()
    @State private var ciqManager = ConnectIQManager.shared

    // MARK: - Initialization

    /// Configure global UI appearance for navigation components on app launch.
    init() {
        setNavigationAppearance()
        configureSegmentedAppearance()
        AuthManager.shared.configure()
    }

    // MARK: - Scene

    /// Root scene containing a NavigationStack driven by the shared router.
    ///
    /// Root transitions (setRoot) are animated via a CATransition applied
    /// directly on the window layer inside Router.setRoot(_:forward:), so no
    /// SwiftUI .transition / .id modifiers are needed here — keeping the
    /// NavigationStack clean and preventing the multi-screen bleed-through bug.
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                router.rootView()
                    .navigationDestination(for: Destinations.self) { dest in
                        router.destination(for: dest)
                            .onDisappear {
                                // Tells the entire app to stop editing
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
            .onOpenURL { url in
                print("[PaceApp] Received URL: \(url)")
                if AuthManager.shared.isSignIn(withEmailLink: url.absoluteString) {
                    Task {
                        do {
                            let email = UserDefaults.standard.string(forKey: "emailForSignIn") ?? ""
                            let user = try await AuthManager.shared.signInWithEmailLink(email: email, link: url.absoluteString)
                            print("[PaceApp] Signed in with email link: \(user.uid)")
                            router.setupRootNavigation()
                        } catch {
                            ToastManager.shared.present(.error(error.localizedDescription))
                        }
                    }
                } else {
                    ciqManager.handleOpenURL(url)
                }
            }
            // ── Cold-launch watch restoration ────────────────────────────────
            .task {
                ciqManager.restoreSessionIfNeeded()
            }
            // ── Session-based root navigation ─────────────────────────────────
            .task {
                await resolveStartupRoot()
            }
        }
    }

    // MARK: - Startup Root Resolution

    /// Shows splash first, then resolves the static root for the current session.
    @MainActor
    private func resolveStartupRoot() async {
        try? await Task.sleep(for: .milliseconds(1200))
        router.setupRootNavigation()
    }

    // MARK: - Appearance Configuration

    /// Sets up UINavigationBar and text input appearance used throughout the app.
    fileprivate func setNavigationAppearance() {
        let appearance = UINavigationBarAppearance()

        // 1. Base Configuration
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear     // Removes the bottom separator line

        // Configure custom fonts for navigation bar titles
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

        // 3. Apply the configured appearance globally
        let navBarProxy = UINavigationBar.appearance()
        navBarProxy.standardAppearance   = appearance
        navBarProxy.scrollEdgeAppearance = appearance
        navBarProxy.compactAppearance    = appearance

        // 4. Set global tint (affects back buttons and navigation icons)
        navBarProxy.tintColor = .whiteApp

        // 5. Global Keyboard Appearance
        UITextField.appearance().keyboardAppearance = .dark
    }

    // Configure segmented control appearance once
    fileprivate func configureSegmentedAppearance() {
        let appearance = UISegmentedControl.appearance()
        appearance.backgroundColor = .grayHint
        appearance.selectedSegmentTintColor = .neonAquaBlue
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.whiteApp],     for: .selected)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.darkCharcoal], for: .normal)
    }
}
