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

	var isLoading: Bool = false
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
				.overlay {
					// Spinner while the OAuth code is exchanged (StravaManager.isWorking).
					if isLoading {
						ProgressView()
							.tint(.whiteApp)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
							.background(Color.stravaOrange)
							.clipShape(RoundedRectangle(cornerRadius: Constant.UI.defaultCornerRadius))
					}
				}
		}
		// Keep the orange fill untouched on press — only a subtle scale signals the tap.
		.buttonStyle(StravaConnectButtonStyle())
		.disabled(isLoading)
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
