//
//  ProfileScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import SwiftUI
import RevenueCatUI

struct ProfileScreen: View {

	@Environment(Router.self) private var router
	@Environment(ConnectIQManager.self) private var ciqManager
	@Environment(SubscriptionManager.self) private var subscription
	@State private var viewModel = ProfileViewModel()
	/// Ask the watch for its settings only once per screen lifetime — avoids a
	/// redundant request on every tab visit.
	@State private var didRequestWatchSettings = false

	/// Pro paywall (free users), plan details + Customer Center (subscribers).
	@State private var showPaywall = false
	@State private var showSubscriptionDetail = false
	@State private var showCustomerCenter = false
	
	var body: some View {
		VStack(spacing: 0) {
			
			// MARK: App Navigation Bar
			AppNavigation(trailing: {
				Button {
					router.navigate(to: .settings)
				} label: {
					RoundedRectangle(cornerRadius: 100)
						.foregroundStyle(.whiteApp)
						.frame(width: 40, height: 40)
						.overlay(content: {
							Image(.icSettings)
								.resizable()
								.frame(width: 20, height: 20)
						})
				}
			})
			
			ScrollView(showsIndicators: false) {
				VStack {
					VSpace(height: 28)
					
					// MARK: Avatar Section
					avatarSection
					
					
					VSpace(height: 28)
					
					// MARK: Menu Items
					menuSection
				}
				.padding(.horizontal, 20)
				.padding(.bottom, 32)
			}
			.scrollBounceBehavior(.basedOnSize)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.appBackground()
		.onAppear {
			viewModel.loadUserInfoFromSession()
			// Ask the watch for its latest settings once — gait/height/weight then
			// stay live via the AuthManager profile listener.
			if !didRequestWatchSettings {
				didRequestWatchSettings = true
				ciqManager.requestSettings()
			}
		}
		// Live refresh: the AuthManager profile listener updates userDetails when
		// the watch syncs settings to Firestore — re-sync the view model instantly.
		.onChange(of: AuthManager.shared.userDetails) { _, _ in
			viewModel.loadUserInfoFromSession()
		}
		// Pro paywall + plan details (RevenueCat).
		.proPaywall(isPresented: $showPaywall)
		.sheet(isPresented: $showCustomerCenter) { CustomerCenterView() }
		.overlay {
			if showSubscriptionDetail {
				SubscriptionDetailView(
					planName: "Pace Pro",
					planPeriod: subscription.planPeriodTitle,
					renewalDate: subscription.renewalDate,
					willRenew: subscription.willRenew,
					onClose: { showSubscriptionDetail = false }
				)
				.transition(.opacity)
			}
		}
		.animation(.easeInOut(duration: 0.2), value: showSubscriptionDetail)
	}
	
	// MARK: - Avatar Section
	
	@ViewBuilder
	private var avatarSection: some View {
		let avatarShape = ProfilePhotoShape()
		
		VStack {
			// Avatar Image
			avatarShape
				.fill(.whiteApp)
				.frame(width: 108, height: 108)
				.overlay {
					VStack(alignment: .center) {
						Text(avatarInitials)
							.font(Gilroy.bold.size(38))
							.foregroundStyle(.radiantBlue)
							.lineLimit(1)
							.minimumScaleFactor(0.6)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
							.padding(.horizontal, 8)
							.offset(y: 8)
					}
				}
			
			VSpace(height: 18)
			
			// Name
			Text(profileDisplayName)
				.font(.bold24)
				.foregroundStyle(.whiteApp)
			
			// Contact
			Text(viewModel.contactInfo)
				.font(.medium14)
				.foregroundStyle(.white50)
			
			VSpace(height: 12)
			
			// Edit Profile Button
			// Push EditProfileScreen via global router
			Button {
				router.navigate(to: .editProfile)
			} label: {
				Text(.editProfile)
					.font(.semiBold16)
					.foregroundStyle(.fluorescentMint)
					.padding(16)
					.frame(width: 150, height: 42)
					.background(.fluorescentMint.opacity(0.20))
					.cornerRadius(8)
					.overlay(
						RoundedRectangle(cornerRadius: 8)
							.inset(by: 0.50)
							.strokeBorder(
								LinearGradient(
									colors: [.fluorescentMint.opacity(0.40), .clear],
									startPoint: .bottom,
									endPoint: .top
								),
								lineWidth: 1
							)
					)
			}

		}
		.padding(.top, 8)
	}
	
	// MARK: - Menu Section
	
	@ViewBuilder
	private var menuSection: some View {
		VStack(spacing: 16) {
			ForEach(viewModel.menuItems) { item in
				profileMenuRow(item: item)
				// Subscription row sits right under Manage Watch.
				if item.id == .manageWatch {
					subscriptionRow
				}
			}
		}
	}

	// MARK: - Subscription Row

	/// "Subscription" for free users (opens the paywall); "Subscribed" for Pro
	/// users (opens the plan-details dialog).
	@ViewBuilder
	private var subscriptionRow: some View {
		Button {
			if subscription.isPro { showSubscriptionDetail = true }
			else { showPaywall = true }
		} label: {
			HStack(spacing: 16) {
				Circle()
					.fill(.neonAquaBlue)
					.frame(width: 42, height: 42)
					.overlay {
						Image(.icSubscription)
							.resizable()
							.renderingMode(.template)
							.foregroundStyle(.whiteApp)
							.frame(width: 32, height: 32)
					}

				Text(subscription.isPro ? "Subscribed" : "Subscription")
					.font(.semiBold16)
					.foregroundStyle(.darkCharcoal)
					.frame(maxWidth: .infinity, alignment: .leading)

				// Mint badge confirms an active plan at a glance.
				if subscription.isPro {
					Image(systemName: "checkmark.seal.fill")
						.font(.system(size: 20))
						.foregroundStyle(.fluorescentMint)
				}
			}
			.padding(Constant.UI.padding12)
			.cardBackground()
		}
		.buttonStyle(.plainSelected(active: .clear, pressed: .radiantBlue))
	}
	
	// MARK: - Menu Row
	
	@ViewBuilder
	private func profileMenuRow(item: ProfileMenuItem) -> some View {
		let rowContent = profileMenuRowContent(item: item)

		switch item.type {
		case .navigation:
			// Button gives native tap debounce — prevents double-push on fast taps
			Button {
				handleMenuTap(item: item)
			} label: {
				rowContent
			}
			.buttonStyle(.plainSelected(active: .clear, pressed: .radiantBlue))

		case .toggle:
			// Plain container — the Toggle inside handles its own interaction
			rowContent
		}
	}

	@ViewBuilder
	private func profileMenuRowContent(item: ProfileMenuItem) -> some View {
		HStack(spacing: 16) {
			// Icon Circle
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
			
			// Title
			Text(item.title)
				.font(.semiBold16)
				.foregroundStyle(.darkCharcoal)
				.frame(maxWidth: .infinity, alignment: .leading)
			
			// Trailing: Toggle or chevron
			switch item.type {
				case .navigation:
					EmptyView()
				case .toggle(let binding, let value):
					Toggle("", isOn: Binding(
						get: { value },
						set: { binding($0) }
					))
					.labelsHidden()
					.tint(.neonAquaBlue)
					.toggleStyle(.automatic)
					
			}
		}
		.padding(Constant.UI.padding12)
		.cardBackground()
	}
	
	// MARK: - Actions
	
	private func handleMenuTap(item: ProfileMenuItem) {
		switch item.id {
			case .manageWatch:
				router.navigate(to: .manageWatch)
			case .stravaIntegration:
				router.navigate(to: .stravaIntegration)
			case .setGait:
				router.navigate(to: .updateGait)
			default:
				break
		}
	}
	
	// MARK: - Helpers
	
	private var avatarInitials: String {
		let firstInitial = initial(from: viewModel.firstName)
		let lastInitial = initial(from: viewModel.lastName)
		let nameInitials = firstInitial + lastInitial
		
		if nameInitials.count == 2 {
			return nameInitials
		}
		
		let fullName = [viewModel.firstName, viewModel.lastName]
			.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
			.joined(separator: " ")
		
		if let fallback = firstCharacters(from: fullName, limit: 2) {
			return fallback
		}
		
		let emailName = viewModel.contactInfo
			.split(separator: "@")
			.first
			.map(String.init)
		
		return firstCharacters(from: emailName, limit: 2) ?? "PA"
	}

	private var profileDisplayName: String {
		let fullName = [viewModel.firstName, viewModel.lastName]
			.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
			.joined(separator: " ")

		let profileDetails = [fullName, viewModel.gender?.rawValue ?? ""]
			.filter { !$0.isEmpty }
			.joined(separator: ", ")

		return profileDetails.isEmpty ? "Pace App" : profileDetails
	}
	
	private func initial(from value: String?) -> String {
		guard let character = value?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.first
		else {
			return ""
		}
		
		return String(character).uppercased()
	}
	
	private func firstCharacters(from value: String?, limit: Int) -> String? {
		let trimmed = value?
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.replacingOccurrences(of: " ", with: "") ?? ""
		
		guard trimmed.isEmpty == false else { return nil }
		return String(trimmed.prefix(limit)).uppercased()
	}
}

#Preview {
	ProfileScreen()
		.environment(Router())
		.environment(ConnectIQManager.shared)
		.environment(SubscriptionManager.shared)
}
