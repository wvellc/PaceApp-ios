//
//  StravaConnectScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/9/26.
//

import SwiftUI

// MARK: - StravaConnectScreen
//
// Connect / disconnect the user's Strava account and sync recent activities. The
// heavy lifting (token exchange, upload) is server-side; this screen just drives
// StravaManager and reflects the connection state it observes from Firestore.

struct StravaConnectScreen: View {

	@Environment(Router.self) private var router
	@Environment(StravaManager.self) private var strava

	var body: some View {
		BackgroundContainer {
			GeometryReader { geo in
				VStack(spacing: 0) {
					VSpace(height: geo.safeAreaInsets.top, isProportional: false)

					ScrollView(showsIndicators: false) {
						VStack(spacing: 24) {
							VSpace(height: 24)
							headerCard
							if strava.isConnected { connectedInfo }
						}
						.padding(.horizontal, 20)
					}
					.scrollBounceBehavior(.basedOnSize)

					Spacer(minLength: 0)
					footer
						.padding(.horizontal, 16)
						.padding(.bottom, geo.safeAreaInsets.bottom + 24)
				}
			}
		}
		.navigationBarBackButtonHidden(true)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar { toolbar }
		.toolbarBackground(.hidden, for: .navigationBar)
		.disabled(strava.isWorking)
		.overlay { if strava.isWorking { workingOverlay } }
		.animation(.easeInOut(duration: 0.2), value: strava.isConnected)
		.animation(.easeInOut(duration: 0.2), value: strava.isWorking)
		.onAppear { strava.startObserving() }
	}

	// MARK: - Toolbar

	@ToolbarContentBuilder
	private var toolbar: some ToolbarContent {
		AppBackButtonToolbarContent(onTap: { router.navigateBack() })
		ToolbarItem(placement: .principal) {
			Text("Strava")
				.font(.medium16)
				.foregroundStyle(.whiteApp)
		}
	}

	// MARK: - Header

	private var headerCard: some View {
		VStack(spacing: 16) {
			Image(.stravaLogo)
				.resizable()
				.scaledToFit()
				.frame(height: 44)

			Text(strava.isConnected ? "Your Strava is connected" : "Connect to Strava")
				.font(.semiBold20)
				.foregroundStyle(.whiteApp)
				.multilineTextAlignment(.center)

			Text(strava.isConnected
				 ? "New completed runs and walks are sent to Strava automatically."
				 : "Send your completed runs and walks straight to Strava, so all your training lives in one place.")
				.font(.medium14)
				.foregroundStyle(.white50)
				.multilineTextAlignment(.center)
		}
		.frame(maxWidth: .infinity)
		.padding(24)
		.cardBackground()
	}

	// MARK: - Connected info

	@ViewBuilder
	private var connectedInfo: some View {
		if let name = strava.athleteName, !name.isEmpty {
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
	}

	// MARK: - Footer

	@ViewBuilder
	private var footer: some View {
		VStack(spacing: 12) {
			if strava.isConnected {
				AppButton("Sync recent activities") {
					Task { await strava.syncRecent() }
				}
				Button("Disconnect") {
					Task { await strava.disconnect() }
				}
				.font(.semiBold16)
				.foregroundStyle(.redBoho)
			} else {
				AppButton("Connect with Strava") {
					strava.connect()
				}
			}

			// Strava brand-guideline attribution.
			Text("Powered by Strava")
				.font(.medium14)
				.foregroundStyle(.white50)
		}
	}

	// MARK: - Working overlay

	private var workingOverlay: some View {
		ZStack {
			Color.black.opacity(0.45).ignoresSafeArea()
			ProgressView()
				.scaleEffect(1.4)
				.tint(.whiteApp)
				.padding(24)
				.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
		}
		.transition(.opacity)
	}
}

// MARK: - Preview

#Preview {
	NavigationStack { StravaConnectScreen() }
		.environment(Router())
		.environment(StravaManager.shared)
}
