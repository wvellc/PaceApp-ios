//
//  PaceAppApp.swift
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
		// Apply a consistent transparent navigation bar style across the app
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
								UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
							}
					}
					.dismissKeyboardOnTap()

			}
			.tint(.radiantBlue)
			.preferredColorScheme(.light)
			.environment(router)
			.appBackground()
            .environment(ciqManager)
            .onOpenURL { url in
                print("Received URL: \(url)")
                ciqManager.handleOpenURL(url)
            }
        }
	}
	
	// MARK: - Appearance Configuration
	/// Sets up UINavigationBar and text input appearance used throughout the app.
	fileprivate func setNavigationAppearance() {
		let appearance = UINavigationBarAppearance()
		// Start from a transparent background configuration
		appearance.configureWithTransparentBackground()
		// Ensure the bar itself is clear and without a shadow line
		appearance.backgroundColor = .clear
		appearance.shadowColor = .clear
		
		// Apply to all navigation bar states
		UINavigationBar.appearance().standardAppearance = appearance
		UINavigationBar.appearance().scrollEdgeAppearance = appearance
		UINavigationBar.appearance().compactAppearance = appearance
		UINavigationBar.appearance().tintColor = UIColor.radiantBlue
		
		// Prefer a dark keyboard for text fields used in the app
		UITextField.appearance().keyboardAppearance = .dark
	}

	// Configure segmented control appearance once
	fileprivate func configureSegmentedAppearance() {
		let appearance = UISegmentedControl.appearance()
		appearance.backgroundColor = .grayHint
		appearance.selectedSegmentTintColor = .neonAquaBlue
		appearance.setTitleTextAttributes([.foregroundColor: UIColor.whiteApp], for: .selected)
		appearance.setTitleTextAttributes([.foregroundColor: UIColor.darkCharcoal], for: .normal)
	}

}

