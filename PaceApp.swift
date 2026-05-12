//
//  PaceApp.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/10/26.
//

import SwiftUI

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
    }

    // MARK: - Scene

    /// Root scene containing a NavigationStack driven by the shared router.
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
                ciqManager.handleOpenURL(url)
            }
            // ── Cold-launch watch restoration ────────────────────────────────
            // restoreSessionIfNeeded() reads AppSession.pairedWatchUUID and calls
            // connectIQ.getKnownDevices() to re-populate ciqManager.devices without
            // requiring the user to open Garmin Connect again.
            // deviceStatusChanged() then fires for each known device, updating
            // ciqManager.deviceStatus and therefore ciqManager.connectedDevice.
            .task {
                ciqManager.restoreSessionIfNeeded()
            }
        }
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
