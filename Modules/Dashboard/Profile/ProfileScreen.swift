//
//  ProfileScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import SwiftUI

struct ProfileScreen: View {
	
	@Environment(Router.self) private var router
	@State private var viewModel = ProfileViewModel()
	
	var body: some View {
		VStack(spacing: 0) {
			
			// MARK: App Navigation Bar
			AppNavigation(trailing: {
				Button(action: {
					router.navigate(to: .settings)
				}, label: {
					RoundedRectangle(cornerRadius: 100)
						.foregroundStyle(.whiteApp)
						.frame(width: 40, height: 40)
						.overlay(content: {
							Image(.icSettings)
								.resizable()
								.frame(width: 20, height: 20)
						})
				})
			})
			
			ScrollView(showsIndicators: false) {
				VStack {
					VSpace(height: 31)
					
					// MARK: Avatar Section
					avatarSection
					
					
					VSpace(height: 16)
					
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
		.environment(viewModel)
	}
	
	// MARK: - Avatar Section
	
	@ViewBuilder
	private var avatarSection: some View {
		let avatarShape = ProfilePhotoShape()
		
		VStack {
			// Avatar Image
			avatarShape
				.fill(.whiteApp)
				.frame(width: 100, height: 108)
				.overlay {
					AsyncImage(url: URL(string: viewModel.avatarURL)) { phase in
						
						if let image = phase.image {
							image
								.resizable()
								.scaledToFill()
								.clipShape(avatarShape)
							
						} else if phase.error != nil {
							Image(.icProfile)
								.resizable()
								.renderingMode(.template)
								.foregroundStyle(.grayHint)
								.scaledToFill()
								.frame(width: 60, height: 60)
							
						} else {
							ProgressView()
								.tint(.grayHint) // Acts as a placeholder.
						}
						
						
					}
				}
			
			VSpace(height: 16)
			
			// Name
			Text(
				"\(viewModel.firstName ?? "")\(viewModel.firstName != nil ? " " : "")\(viewModel.lastName ?? "")"
			)
				.font(.bold24)
				.foregroundStyle(.whiteApp)
			
			// Email
			Text(viewModel.userEmail)
				.font(.medium14)
				.foregroundStyle(.white50)
			
			VSpace(height: 16)
			
			// Edit Profile Button
			Button(
				action: {
					router
						.navigate(
							to: .editProfile(
										firstName: viewModel.firstName,
										lastName: viewModel.lastName,
										profile: viewModel.avatarURL
									)
						)
				},
				label: {
					Text("Edit Profile")
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
				})
		}
		.padding(.top, 8)
	}
	
	// MARK: - Menu Section
	
	@ViewBuilder
	private var menuSection: some View {
		VStack(spacing: 16) {
			ForEach(viewModel.menuItems) { item in
				profileMenuRow(item: item)
			}
		}
	}
	
	// MARK: - Menu Row
	
	@ViewBuilder
	private func profileMenuRow(item: ProfileMenuItem) -> some View {
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
			
			// Trailing: Toggle or nothing
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
		.padding(12)
		.cardBackground()
		.onTapGesture {
			handleMenuTap(item: item)
		}
	}
	
	// MARK: - Actions
	
	private func handleMenuTap(item: ProfileMenuItem) {
		//		switch item.id {
		//			case .manageWatch:
		//				router.navigate(to: .manageWatch)
		//			case .setGait:
		//				router.navigate(to: .setGait)
		//			default:
		//				break
		//		}
	}
}

#Preview {
	ProfileScreen()
		.environment(Router())
}
