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

	//Selection for Navigation
	@State private var selectedMenuItem: SettingsMenuItemID? = nil
	
	var body: some View {
		@Bindable var viewModel = viewModel
		VStack(spacing: 0) {
			// MARK: Scrollable Content
			ScrollView(showsIndicators: false) {
				VStack(spacing: 16) {
					
					// MARK: Distance Unit Segmented Control
					AppSegmentedControl(
						selection: $viewModel.selectedUnit,
						segments: MeasureUnit.allCases.map { (key: $0, title: $0.rawValue) },
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
		.navigationAppTitle(title: .settings)
		// MARK: - Navigation using selectedMenuItem
		.navigationDestination(item: $selectedMenuItem) { item in
			destinationView(for: item)
		}
	}
	
	// MARK: - Destination Builder
	@ViewBuilder
	private func destinationView(for item: SettingsMenuItemID) -> some View {
		switch item {
			case .termsConditions:
				AppWebViewScreen(
					requestUrl: NetworkConst.WebUrl.termsOfService
				)
			case .privacyPolicy	:
				AppWebViewScreen(
					requestUrl: NetworkConst.WebUrl.privacyPolicy
				)
			case .licenses		:
				AppWebViewScreen(
					requestUrl: NetworkConst.WebUrl.licences
				)
			default: EmptyView()
		}
	}
		
	// MARK: - Standard Menu Row (reuses profileMenuRow pattern)
	
	@ViewBuilder
	private func settingsMenuRow(item: SettingsMenuItem) -> some View {
		Button(action: {
			handleMenuTap(item: item)
		}, label: {
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
		})
		.buttonStyle(.plainSelected())
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
			case .developedBy:
				withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
					viewModel.isDevelopedByExpanded.toggle()
				}
			case .privacyPolicy, .termsConditions, .licenses:
				selectedMenuItem = item.id
		}
	}
	
	private func handleLogout() {
		viewModel.showLogoutAlert {
			selectedMenuItem = nil
			AppSession.removeAllData()
			router.setRoot(.auth)
		}
	}
	
	private func handleDeleteAccount() {
		viewModel.showDeleteAccountAlert {
			//TODO: Call delete account API then clear session
			selectedMenuItem = nil
			AppSession.removeAllData()
			router.setRoot(.auth)
		}
	}
}

#Preview {
	SettingScreen()
		.environment(Router())
}
