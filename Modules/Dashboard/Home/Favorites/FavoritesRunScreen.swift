//
//  FavoritesRunScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/5/26.
//

import SwiftUI

/// Show your favorite runs
struct FavoritesRunScreen: View {
	
	// MARK: - Properties
	@State private var viewModel = FavoritesViewModel()
	
	// This tracks which item is currently being navigated to
	@State private var selectedActivity: ActivityData?
	
	var body: some View {
		VStack {
			if viewModel.isLoading {
				// MARK: Loading State - Centered Spinner + Message
				Spacer()
				VStack(spacing: 20) {
					ProgressView()
						.scaleEffect(1.5)
						.tint(.whiteApp)
					
					Text(.fetchingFavorites)
						.font(.semiBold20)
						.foregroundStyle(.whiteApp)

					
					Text(.thisWontTakeLong)
						.font(.medium16)
						.foregroundStyle(.whiteApp.opacity(0.9))
				}
				.frame(maxWidth: .infinity)
				Spacer()
			} else if viewModel.favRuns.isEmpty {
				// MARK: Empty State
				Spacer(minLength: 40)
				HStack {
					Spacer()
					NoDataView(
						icon: .icFavoritesPlaceholder,
						title: .noFavoritesYet,
						description: .tapTheHeartOnAnyRunToAddItHere
					)
					.transition(.opacity.combined(with: .scale(scale: 0.95)))
					Spacer()
				}
				Spacer()
			} else {
				// MARK: Content - Favorite Runs List
				activityList
					.transition(.opacity)
			}
		}
		.animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
		.animation(.easeInOut(duration: 0.25), value: viewModel.favRuns.isEmpty)
		.navigationAppTitle(title: .favorites)
		.appBackground()
		.navigationDestination(item: $selectedActivity) { activity in
			EventDetailsScreen(activityData: activity)
		}
		.task(id: AuthManager.shared.currentUserID) {
			guard let userId = AuthManager.shared.currentUserID else { return }
			await viewModel.loadFavorites(userId: userId)
		}
	}
	
	// MARK: - Activity List
	@ViewBuilder
	private var activityList: some View {
		List {
			ForEach(viewModel.favRuns) { activity in
				Button {
					selectedActivity = activity
				} label: {
					PaceRunActivityCard(activity: activity)
				}
				.buttonStyle(.plain)
				
				// Remove default list padding and backgrounds to make it look like a floating card
				.listRowInsets(EdgeInsets(top: 8,
										  leading: Constant.UI.defaultPadding,
										  bottom: 8,
										  trailing: Constant.UI.defaultPadding))
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
				
				// Swipe to Unfavorite
				.swipeActions(edge: .trailing, allowsFullSwipe: true) {
					Button(role: .destructive) {
						guard let userId = AuthManager.shared.currentUserID else { return }
						Task {
							await viewModel.unFavorite(run: activity, userId: userId)
						}
					} label: {
						Image(.icUnFavorite)
							.renderingMode(.template)
							.foregroundStyle(.whiteApp)
					}
					.tint(.redBoho)
				}
			}
		}
		.listStyle(.plain)
		.padding(.top, Constant.UI.defaultPadding / 2)
	}
}

#Preview {
	FavoritesRunScreen()
}
