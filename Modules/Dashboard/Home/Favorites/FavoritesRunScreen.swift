//
//  FavoritesRunScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/5/26.
//

import SwiftUI

///Show your favoraite runs
struct FavoritesRunScreen: View {
	
	// MARK: Properties
	@State private var viewModel = FavoritesViewModel()
	
	// This tracks which item is currently being navigated to
	@State private var selectedActivity: ActivityData?
	
	var body: some View {
		// Activity List
		VStack(alignment: .center) {
			if viewModel.favRuns.isEmpty {
				Spacer(minLength: 25)
				//No Data
				HStack {
					Spacer()
					
					NoDataView(
						icon: .icFavoritesPlaceholder,
						title: "No Favorites Yet",
						description: "Add some favorites to see them here!"
					)
					.transition(.opacity)
					
					Spacer()
				}
				Spacer(minLength: 25)
				Spacer()
			} else {
				activityList
					.transition(.opacity)
			}
		}
		.animation(.easeInOut(duration: 0.25), value: viewModel.favRuns.isEmpty)
		.navigationAppTitle(title: .favorites)
		.appBackground()
		.navigationDestination(item: $selectedActivity) { activity in
			EventDetailsScreen(activityData: activity)
		}
		
		
	}
	
	
	// MARK: Activity List
	@ViewBuilder
	var activityList: some View {
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
										  trailing: Constant.UI.defaultPadding)
				)
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
				
				
				//Swipe to Delete (Matches the second image)
				.swipeActions(edge: .trailing, allowsFullSwipe: true) {
					Button(role: .destructive) {
						withAnimation {
							viewModel.unFavorite(run: activity)
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
