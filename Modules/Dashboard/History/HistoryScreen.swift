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
	@FocusState var focusedField: Bool?
	
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
		//Event Name
		AppTextField(
			text: $viewModel.searchText,
			placeholder: .searchHere,
			leadingView: AnyView(Image(.icSearch)),
			trailingView: AnyView(Button(action: {
				viewModel.applyFilter()
			}, label: {
				Image(viewModel.hasFilteredContent ?  .icFilterApplied : .icFilter)
			})),
			submitLabel: .done
		)
		.focused($focusedField, equals: true)
		.onSubmit {
			focusedField = false
		}
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
