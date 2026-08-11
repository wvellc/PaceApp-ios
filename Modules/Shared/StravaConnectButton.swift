//
//  StravaConnectButton.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 8/11/26.
//

import SwiftUI

// MARK: - StravaConnectButton

/// Official "Connect with Strava" button on a full Strava-orange fill,
/// per https://developers.strava.com/guidelines/. Shared by Settings + onboarding.
struct StravaConnectButton: View {

	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Image(.icStravaConnectOrange)
				.resizable()
				.scaledToFit()
				.frame(height: 48)
				.frame(maxWidth: .infinity)
				.background(.stravaOrange)
				.clipShape(RoundedRectangle(cornerRadius: Constant.UI.defaultCornerRadius))
		}
		// Keep the orange fill untouched on press — only a subtle scale signals the tap.
		.buttonStyle(StravaConnectButtonStyle())
	}
}

// MARK: - Press Style

/// No fade/tint on press, so the full orange fill stays exactly as-is.
private struct StravaConnectButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.98 : 1)
			.animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
	}
}
