//
//  AppAlertManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI
import Combine

// MARK: - AppAlertManager (Singleton)

/// Singleton that drives the app-level alert overlay.
/// Present from any ViewModel or helper via `AppAlertManager.shared`.
///
/// Usage (ViewModel):
/// ```swift
/// AppAlertManager.shared.present(
///     AppAlertModel(
///         title: "Take a quick break?",
///         description: "Your events will be waiting when you return.",
///         primaryButton: AppAlertButton("Keep Going") { },
///         secondaryButton: AppAlertButton("Log Out") { handleLogout() }
///     )
/// )
/// ```
@MainActor
final class AppAlertManager: ObservableObject {

	// MARK: - Singleton

	static let shared = AppAlertManager()
	private init() {}

	// MARK: - State

	/// The currently visible alert. `nil` means nothing is shown.
	@Published private(set) var current: AppAlertModel?

	// MARK: - Present

	/// Enqueues and shows the given alert. Replaces any existing one.
	func present(_ alert: AppAlertModel) {
		withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
			current = alert
		}
	}

	// MARK: - Dismiss

	/// Dismisses the current alert with an animation.
	func dismiss() {
		withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
			current = nil
		}
	}
}

// MARK: - Event Deletion Confirmation

extension AppAlertManager {

	/// Presents the standard "delete event" confirmation popup.
	///
	/// `onConfirm` runs only when the user taps **Delete**; tapping **Cancel**
	/// (or the button) simply dismisses. The alert auto-dismisses on either
	/// choice, and the outside tap is restricted so the destructive action is
	/// always an explicit decision.
	func confirmEventDeletion(onConfirm: @escaping () -> Void) {
		present(
			AppAlertModel(
				title: "Delete Event?",
				description: "This event and its data will be permanently removed. This can't be undone.",
				primaryButton: AppAlertButton("Cancel"),
				secondaryButton: AppAlertButton("Delete", action: onConfirm),
				restrictOutsideTap: true
			)
		)
	}
}
