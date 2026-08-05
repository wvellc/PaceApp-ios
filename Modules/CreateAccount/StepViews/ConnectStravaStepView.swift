//
//  ConnectStravaStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI

// MARK: - ConnectStravaStepView

/// Final onboarding step — connect Strava via the shared OAuth flow (StravaManager).
/// The footer "Connect Strava" button starts the flow; onboarding finishes on its own
/// once the connection lands.
struct ConnectStravaStepView: View {

	@Environment(StravaManager.self) private var strava

	var body: some View {
		VStack {

			// Subtitle
			Text("Sync your activities and compete with friends for the segment.")
				.font(.medium20)
				.foregroundStyle(.whiteApp)
				.lineSpacing(10)
				.frame(maxWidth: .infinity, alignment: .leading)

			VSpace(height: 64)

			Image(.stravaLogo)
				.resizable()
				.frame(width: 100, height: 108)

			VSpace(height: 42)

			// Connected badge — shown once the account links.
			if strava.isConnected, let name = strava.athleteName, !name.isEmpty {
				HStack(spacing: 12) {
					Image(.icPerson)
						.resizable()
						.renderingMode(.template)
						.foregroundStyle(.neonAquaBlue)
						.frame(width: 22, height: 22)
					Text("Connected as \(name)")
						.font(.semiBold16)
						.foregroundStyle(.darkCharcoal)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
				.padding(Constant.UI.padding12)
				.cardBackground()
			}

			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.top, 24)
	}
}

#Preview {
	ConnectStravaStepView()
		.environment(StravaManager.shared)
		.appBackground()
}
