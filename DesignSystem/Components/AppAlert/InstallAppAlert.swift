//
//  InstallAppAlert.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

// MARK: - InstallAppAlert Modifier

/// Attaches the global alert overlay to the root window.
/// Apply once in `PaceApp.swift`:
/// ```swift
/// NavigationStack { … }
///     .installAppAlert()
/// ```
struct InstallAppAlertModifier: ViewModifier {

	@StateObject private var manager = AppAlertManager.shared

	func body(content: Content) -> some View {
		content
			.overlay {
				if let alert = manager.current {
					AppAlertView(alert: alert) {
						manager.dismiss()
					}
					.zIndex(999)
					.transition(
						.asymmetric(
							insertion: .opacity,
							removal:   .opacity
						)
					)
					.animation(.spring(response: 0.35, dampingFraction: 0.82), value: manager.current?.id)
				}
			}
			.animation(.spring(response: 0.35, dampingFraction: 0.82), value: manager.current?.id)
	}
}

// MARK: - View Extension

extension View {
	/// Installs the app-wide alert overlay. Call **once** at the root scene level.
	func installAppAlert() -> some View {
		modifier(InstallAppAlertModifier())
	}
}
