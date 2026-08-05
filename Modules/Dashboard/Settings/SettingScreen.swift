//
//  SettingScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import SwiftUI
import Logging

/// Settings screen for user preferences
struct SettingScreen: View {
	
	@Environment(Router.self) private var router
	@Environment(StravaManager.self) private var strava
	@State private var viewModel = SettingsViewModel()
	
	@State private var selectedMenuItem: SettingsMenuItemID? = nil
	/// Blocks the whole screen while an account action (delete / logout) runs.
	@State private var isProcessingAccountAction = false

	// Re-authentication (for account deletion) — no sign-out.
	@State private var showReauthOTPSheet = false
	@State private var showEmailReauthWait = false
	@State private var reauthVerificationID = ""
	@State private var reauthContact = ""

	/// Presents the FAQ page in an in-app Safari sheet (SFSafariViewController).
	@State private var showFAQSafari = false

	var body: some View {
		VStack(spacing: 0) {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 16) {
					
					// Distance unit picker with safe update handling
					AppSegmentedControl(
						selection: $viewModel.selectedUnit,
						segments: MeasureUnit.allCases.map { (key: $0, title: $0.rawValue) },
						unselectedForeground: .darkCharcoal,
						trackBackground: .grayHint
					)
					.padding(10)
					.cardBackground()
					.onChange(of: viewModel.selectedUnit) { _, newValue in
						viewModel.updateDistanceUnit(newValue)      // Prevents didSet crash + debounced save
					}

					// Strava connection management
					stravaSection

					ForEach(viewModel.menuItems) { item in
						if item.id == .developedBy {
							DevelopedByView(
								item: item,
								isDevelopedByExpanded: isDevelopedByExpandedBinding
							)
						} else {
							settingsMenuRow(item: item)
						}
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 24)
			}
			.scrollBounceBehavior(.basedOnSize)
			
			Spacer(minLength: 0)
			footerSection
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.appBackground()
		.navigationAppTitle(title: .settings)
		.navigationDestination(item: $selectedMenuItem) { item in
			destinationView(for: item)
		}
		// Block interaction + back navigation while deleting/logging out.
		.disabled(isProcessingAccountAction)
		.overlay {
			if isProcessingAccountAction { processingOverlay }
		}
		.navigationBarBackButtonHidden(isProcessingAccountAction)
		.animation(.easeInOut(duration: 0.2), value: isProcessingAccountAction)
		.animation(.easeInOut(duration: 0.2), value: strava.isConnected)
		.onAppear { strava.startObserving() }
		// Phone reauth — enter the OTP sent to the signed-in number, then delete.
		.sheet(isPresented: $showReauthOTPSheet) {
			ReauthOTPSheet(phone: reauthContact, verificationID: reauthVerificationID) {
				performDelete()
			}
		}
		// Email reauth — wait while the user taps the link sent to their email.
		.sheet(isPresented: $showEmailReauthWait) {
			EmailReauthWaitSheet(email: reauthContact) {
				AuthManager.shared.isReauthenticatingForDeletion = false
				showEmailReauthWait = false
			}
		}
		// FAQ — opens in Safari rather than the in-app WebView.
		.sheet(isPresented: $showFAQSafari) {
			SafariView(url: URL(string: NetworkConst.WebUrl.faq)!)
				.ignoresSafeArea()
		}
	}

	// MARK: - Processing Overlay

	/// Full-screen dimmer + spinner shown while an account action is in flight.
	/// The dimmer captures all taps so nothing underneath is interactable.
	private var processingOverlay: some View {
		ZStack {
			Color.black.opacity(0.55)
				.ignoresSafeArea()
			ProgressView()
				.scaleEffect(1.5)
				.tint(.whiteApp)
				.padding(28)
				.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
		}
		.transition(.opacity)
	}
	
	// MARK: - Bindings
	
	private var isDevelopedByExpandedBinding: Binding<Bool> {
		Binding(
			get: { viewModel.isDevelopedByExpanded },
			set: { viewModel.isDevelopedByExpanded = $0 }
		)
	}
	
	// MARK: - Navigation Destinations
	
	@ViewBuilder
	private func destinationView(for item: SettingsMenuItemID) -> some View {
		switch item {
			case .termsConditions:
				AppWebViewScreen(requestUrl: NetworkConst.WebUrl.termsOfService)
			case .privacyPolicy:
				AppWebViewScreen(requestUrl: NetworkConst.WebUrl.privacyPolicy)
			case .licenses:
				AppWebViewScreen(requestUrl: NetworkConst.WebUrl.licences)
			default:
				EmptyView()
		}
	}
	
	// MARK: - Menu Row
	
	@ViewBuilder
	private func settingsMenuRow(item: SettingsMenuItem) -> some View {
		Button(action: {
			handleMenuTap(item: item)
		}, label: {
			HStack(spacing: 16) {
				Circle()
					.fill(.neonAquaBlue)
					.frame(width: 42, height: 42)
					.overlay {
						Image(item.icon)
							.resizable()
							.renderingMode(.template)
							.foregroundStyle(.whiteApp)
							.frame(width: 32, height: 32)
					}
				
				Text(item.title)
					.font(.semiBold16)
					.foregroundStyle(.darkCharcoal)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(10)
			.cardBackground()
		})
		.buttonStyle(.plainSelected())
	}
	
	// MARK: - Strava

	/// Connection status card — connect, reconnect, or disconnect Strava.
	@ViewBuilder
	private var stravaSection: some View {
		VStack(spacing: 14) {
			HStack(spacing: 16) {
				Circle()
					.fill(.neonAquaBlue)
					.frame(width: 42, height: 42)
					.overlay {
						Image(.icSync)
							.resizable()
							.renderingMode(.template)
							.foregroundStyle(.whiteApp)
							.frame(width: 32, height: 32)
					}

				VStack(alignment: .leading, spacing: 2) {
					Text("Strava")
						.font(.semiBold16)
						.foregroundStyle(.darkCharcoal)
					Text(stravaStatusText)
						.font(.medium14)
						.foregroundStyle(strava.isConnected ? .fluorescentMint : .fashionGray)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}

			if strava.isConnected {
				HStack(spacing: 12) {
					stravaActionButton(title: "Resync", tint: .radiantBlue) {
						Task { await strava.syncRecent() }
					}
					stravaActionButton(title: "Disconnect", tint: .redBoho) {
						Task { await strava.disconnect() }
					}
				}
			} else {
				AppButton("Connect Strava") { strava.connect() }
			}
		}
		.padding(10)
		.cardBackground()
		.disabled(strava.isWorking)
		.opacity(strava.isWorking ? 0.6 : 1)
	}

	/// Pill-style secondary action used for Reconnect / Disconnect.
	private func stravaActionButton(title: String, tint: Color, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			Text(title)
				.font(.semiBold14)
				.foregroundStyle(tint)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 10)
				.background(tint.opacity(0.12))
				.clipShape(Capsule())
		}
	}

	private var stravaStatusText: String {
		guard strava.isConnected else { return "Not connected" }
		if let name = strava.athleteName, !name.isEmpty { return "Connected as \(name)" }
		return "Connected"
	}

	// MARK: - Footer

	@ViewBuilder
	private var footerSection: some View {
		VStack(spacing: 16) {
			AppButton(.logout) {
				handleLogout()
			}
			
			Button(action: {
				handleDeleteAccount()
			}, label: {
				Text(.deleteAccount)
					.font(.semiBold14)
					.foregroundStyle(.fashionGray)
			})
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
	}
	
	// MARK: - Actions
	
	private func handleMenuTap(item: SettingsMenuItem) {
		switch item.id {
			case .notifications:
				if let url = URL(string: UIApplication.openSettingsURLString) {
					UIApplication.shared.open(url)
				}
			case .developedBy:
				withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
					viewModel.isDevelopedByExpanded.toggle()
				}
			case .faq:
				showFAQSafari = true
			case .privacyPolicy, .termsConditions, .licenses:
				selectedMenuItem = item.id
		}
	}
	
	private func handleLogout() {
		viewModel.showLogoutAlert {
			performAccountAction(
				action: { try await AuthManager.shared.logout() },
				errorMessage: "Failed to log out. Please try again."
			)
		}
	}
	
	private func handleDeleteAccount() {
		// In-app popup asks the user to confirm; confirming starts inline re-auth.
		viewModel.showDeleteAccountAlert {
			beginReauthentication()
		}
	}

	/// Verifies it's really the user (OTP for phone, email link for email) before
	/// deleting — no sign-out. Falls back to a direct delete when the provider is unknown.
	private func beginReauthentication() {
		switch AuthManager.shared.authProviderKind {
		case .phone(let number):
			isProcessingAccountAction = true
			Task { @MainActor in
				defer { isProcessingAccountAction = false }
				do {
					reauthVerificationID = try await AuthManager.shared.sendReauthOTP()
					reauthContact = number
					showReauthOTPSheet = true
				} catch {
					ToastManager.shared.present(.error(AuthErrorMapper.message(for: error)))
				}
			}

		case .email(let email):
			isProcessingAccountAction = true
			Task { @MainActor in
				defer { isProcessingAccountAction = false }
				do {
					try await AuthManager.shared.sendReauthEmailLink()
					reauthContact = email
					showEmailReauthWait = true
				} catch {
					ToastManager.shared.present(.error(AuthErrorMapper.message(for: error)))
				}
			}

		case .unknown:
			performDelete()
		}
	}

	private func performDelete() {
		performAccountAction(
			action: { try await AuthManager.shared.deleteAccount() },
			errorMessage: "Failed to delete account. Please try again."
		)
	}
	
	// MARK: - Core Logic
	
	private func performAccountAction(
		action: @escaping () async throws -> Void,
		errorMessage: String
	) {
		selectedMenuItem = nil
		isProcessingAccountAction = true

		Task { @MainActor in
			defer { isProcessingAccountAction = false }
			do {
				try await action()
				router.setRoot(.auth)
			} catch {
				logger.error("Account action error: \(error.localizedDescription)")
				AppSession.removeAllData()
				router.setRoot(.auth)
			}
		}
	}
}

// MARK: - Preview

#Preview {
	SettingScreen()
		.environment(Router())
		.environment(StravaManager.shared)
}
