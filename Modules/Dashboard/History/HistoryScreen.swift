//
//  HistoryScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/10/26.
//

import SwiftUI

// MARK: - History Screen
struct HistoryScreen: View {
	
	// MARK: Properties
	@State private var viewModel = HistoryViewModel()
	
	// MARK: Body
	var body: some View {
		VStack(spacing: 0) {
			// Navigation Bar
			// MARK: App Navigation bar
			AppNavigation()

			
			// Search Bar
			searchBar
				.padding(.horizontal, 16)
				.padding(.top, 16)
				.padding(.bottom, 8)
			
			// Activity List
			activityList
		}
		.appBackground()
	}
}

// MARK: - Subviews
private extension HistoryScreen {
	
	
	
	// MARK: Search Bar
	var searchBar: some View {
		HStack(spacing: 10) {
			Image(systemName: "magnifyingglass")
				.foregroundStyle(.fashionGray)
				.font(.system(size: 16))
			
			TextField("", text: $viewModel.searchText, prompt:
						Text("Search here...")
				.foregroundStyle(.fashionGray)
			)
			.font(.regular13)
			.foregroundStyle(.darkCharcoal)
			.autocorrectionDisabled()
			.textInputAutocapitalization(.never)
			
			Spacer()
			
			Image(systemName: "line.3.horizontal.decrease")
				.foregroundStyle(.fashionGray)
				.font(.system(size: 16))
		}
		.padding(.horizontal, 14)
		.padding(.vertical, 12)
		.background(.whiteApp, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
	}
	
	// MARK: Activity List
	var activityList: some View {
		ScrollView(showsIndicators: false) {
			LazyVStack(spacing: 16) {
				ForEach(viewModel.filteredActivities) { activity in
					PaceRunActivityCard(activity: activity)
				}
			}
			.padding(.horizontal, 16)
			.padding(.top, 16)
			.padding(.bottom, 24)
		}
	}
}

// MARK: - Preview
#Preview {
	HistoryScreen()
}
