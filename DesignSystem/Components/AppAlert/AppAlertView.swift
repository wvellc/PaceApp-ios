//
//  AppAlertView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

// MARK: - AppAlertView

/// The popup card rendered by `InstallAppAlert` when `AppAlertManager.current` is non-nil.
/// Do not use this view directly — rely on the `.installAppAlert()` modifier at the root.
struct AppAlertView: View {

	// MARK: - Properties

	let alert: AppAlertModel

	/// Called when the alert should be dismissed (button tap or outside tap).
	let onDismiss: () -> Void

	// MARK: - Body

	var body: some View {
		// Dim overlay — tapping it dismisses unless restricted
		Color.black.opacity(0.8)
			.ignoresSafeArea()
			.onTapGesture {
				guard !alert.restrictOutsideTap else { return }
				onDismiss()
			}
			.overlay {
				card
					.padding(.horizontal, 32)
					// Scale-in entrance animation driven by parent transition
					.transition(
						.asymmetric(
							insertion: .scale(scale: 0.85).combined(with: .opacity),
							removal:   .scale(scale: 0.95).combined(with: .opacity)
						)
					)
			}
	}

	// MARK: - Card

	private var card: some View {
		VStack(spacing: 8) {

			// MARK: Text stack
			Text(alert.title)
				.font(.medium24)
				.foregroundStyle(.darkCharcoal)
				.multilineTextAlignment(.center)
				.lineSpacing(2)

			
			if let desc = alert.description {
				
				Text(desc)
					.font(.medium16)
					.lineSpacing(3)
					.foregroundStyle(.fashionGray)
					.multilineTextAlignment(.center)
			}

			VSpace()

			// MARK: Buttons
			buttonsRow
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 25)
		.frame(maxWidth: .infinity)
		.background(.whiteApp)
		.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
		.shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
	}

	// MARK: - Buttons Row

	@ViewBuilder
	private var buttonsRow: some View {
		if let secondary = alert.secondaryButton {
			// Two-button layout
			HStack(spacing: 12) {
				// Secondary — gray capsule with red text
				AppButton(
					secondary.title,
					style: .secondary,
					maxWidth: .infinity
				) {
					secondary.action()
					onDismiss()
				}

				// Primary — gradient capsule
				AppButton(
					alert.primaryButton.title,
					style: .primary,
					maxWidth: .infinity
				) {
					alert.primaryButton.action()
					onDismiss()
				}
			}
		} else {
			// Single primary button — full-width
			AppButton(
				alert.primaryButton.title,
				style: .primary,
				maxWidth: .infinity
			) {
				alert.primaryButton.action()
				onDismiss()
			}
		}
	}
}

// MARK: - Preview

#Preview("Two Buttons") {
	ZStack {
		Color.darkSeaBlue.ignoresSafeArea()
		AppAlertView(
			alert: AppAlertModel(
				title: "Take a quick break?",
				description: "Your events and Garmin sync will be waiting when you return.",
				primaryButton: AppAlertButton("Keep Going"),
				secondaryButton: AppAlertButton("Log Out")
			),
			onDismiss: {}
		)
	}
}

#Preview("Single Button") {
	ZStack {
		Color.darkSeaBlue.ignoresSafeArea()
		AppAlertView(
			alert: AppAlertModel(
				title: "Session Expired",
				description: "Please log in again to continue.",
				primaryButton: AppAlertButton("Got it"),
				restrictOutsideTap: true
			),
			onDismiss: {}
		)
	}
}
