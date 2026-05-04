//
//  SettingScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//
import SwiftUI

struct SettingScreen: View {
	
	@Environment(Router.self) private var router
	@State private var viewModel = SettingsViewModel()
	
	var body: some View {
		VStack(spacing: 0) {
			// MARK: Scrollable Content
			ScrollView(showsIndicators: false) {
				VStack(spacing: 16) {
					
					// MARK: Distance Unit Segmented Control
					AppSegmentedControl(
						selection: $viewModel.selectedUnit,
						segments: DistanceType.allCases.map { (key: $0, title: $0.rawValue) },
						unselectedForeground: .darkCharcoal,
						trackBackground: .grayHint
					)
					.padding(10)
					.cardBackground()

					
					// MARK: Menu Rows
					ForEach(viewModel.menuItems) { item in
						if item.id == .developedBy {
							DevelopedByView(
								item: item,
								isDevelopedByExpanded: $viewModel.isDevelopedByExpanded
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
			
			// MARK: Footer (Logout + Delete Account) — pinned
			footerSection
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.appBackground()
		.navigationTitle(.settings)
		.navigationBarTitleDisplayMode(.inline)
	}
		
	// MARK: - Standard Menu Row (reuses profileMenuRow pattern)
	
	@ViewBuilder
	private func settingsMenuRow(item: SettingsMenuItem) -> some View {
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
		}
		.padding(10)
		.cardBackground()
		.onTapGesture {
			handleMenuTap(item: item)
		}
	}
	
	
	// MARK: - Footer
	
	@ViewBuilder
	private var footerSection: some View {
		VStack(spacing: 16) {
			// Logout button
			AppButton(.logout) {
				handleLogout()
			}
			
			// Delete Account
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
				// Open iOS notification settings for this app
				if let url = URL(string: UIApplication.openSettingsURLString) {
					UIApplication.shared.open(url)
				}
			case .privacyPolicy:
				router.navigate(to: .privacyPolicy)
			case .termsConditions:
				router.navigate(to: .termsOfService)
			case .licenses:
				router.navigate(to: .licenses)
			case .developedBy:
				withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
					viewModel.isDevelopedByExpanded.toggle()
				}
		}
	}
	
	private func handleLogout() {
		viewModel.showLogoutAlert {
			AppSession.removeAllData()
			router.setRoot(.auth)
		}
	}
	
	private func handleDeleteAccount() {
		viewModel.showDeleteAccountAlert {
			//TODO: Call delete account API then clear session
		}
	}
}

#Preview {
	SettingScreen()
		.environment(Router())
}
