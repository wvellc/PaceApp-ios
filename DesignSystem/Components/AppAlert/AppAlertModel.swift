//
//  AppAlertModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

// MARK: - AppAlertModel

/// Defines the content and behaviour of a single app-level alert popup.
struct AppAlertModel: Identifiable {

	// MARK: - Properties

	let id: UUID

	/// Bold title displayed at the top of the popup. Required.
	let title: LocalizedStringResource

	/// Optional supporting body text shown below the title.
	let description: LocalizedStringResource?

	/// Primary (right / blue) button. Always visible.
	let primaryButton: AppAlertButton

	/// Optional secondary (left / gray) button.
	/// When `nil` only the primary button is rendered (full-width).
	let secondaryButton: AppAlertButton?

	/// When `true` tapping the dim overlay does NOT dismiss the alert.
	let restrictOutsideTap: Bool

	// MARK: - Init

	/// Creates an `AppAlertModel`.
	///
	/// - Parameters:
	///   - title: Bold heading text.
	///   - description: Optional supporting body. Default `nil`.
	///   - primaryButton: The main action button (right side / full-width when alone).
	///   - secondaryButton: An optional cancel-style button (left side). Default `nil`.
	///   - restrictOutsideTap: Pass `true` to prevent outside-tap dismissal. Default `false`.
	init(
		id: UUID = .init(),
		title: LocalizedStringResource,
		description: LocalizedStringResource? = nil,
		primaryButton: AppAlertButton,
		secondaryButton: AppAlertButton? = nil,
		restrictOutsideTap: Bool = false
	) {
		self.id = id
		self.title = title
		self.description = description
		self.primaryButton = primaryButton
		self.secondaryButton = secondaryButton
		self.restrictOutsideTap = restrictOutsideTap
	}
}

// MARK: - AppAlertButton

/// A single button descriptor used inside `AppAlertModel`.
struct AppAlertButton {

	/// Label text shown on the button.
	let title: LocalizedStringResource

	/// Closure executed when the button is tapped.
	let action: () -> Void

	/// Creates an `AppAlertButton`.
	init(_ title: LocalizedStringResource, action: @escaping () -> Void = {}) {
		self.title = title
		self.action = action
	}
}
