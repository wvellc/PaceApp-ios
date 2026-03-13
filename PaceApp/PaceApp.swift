//
//  PaceAppApp.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/10/26.
//

import SwiftUI

@main
struct PaceApp: App {
	// MARK: - Properties
	/// Central router that manages navigation path and destination resolution.
	@State private var router = Router()
	
	// MARK: - Initialization
	/// Configure global UI appearance for navigation components on app launch.
	init() {
		// Apply a consistent transparent navigation bar style across the app
		setNavigationAppearance()
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

		// Prefer a dark keyboard for text fields used in the app
		UITextField.appearance().keyboardAppearance = .dark
	}
	
	// MARK: - Scene
	/// Root scene containing a NavigationStack driven by the shared router.
	var body: some Scene {
		WindowGroup {
			NavigationStack(path: $router.path) {
				router.rootView()
					.navigationDestination(for: Destinations.self) { dest in
						router.destination(for: dest)
					}
			}
			.preferredColorScheme(.light)
			.environment(router)
		}
	}
}

