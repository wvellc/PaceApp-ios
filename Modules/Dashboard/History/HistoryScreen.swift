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
	@State private var isFilterSheetPresented = false
	
	//MARK: Environment
	@Environment(Router.self) private var router
	
	// MARK: Body
	var body: some View {
		VStack(spacing: 0) {
			// Navigation Bar
			AppNavigation()
			
			// Search Bar
			searchBar
				.padding(.horizontal, 16)
				.padding(.top, 16)
				.padding(.bottom, 8)
			
			// Activity List
			Group {
				if viewModel.filteredActivities.isEmpty {
					Spacer(minLength: 25)
					NoDataView(
						icon: .icEmptyHistory,	
						title: .letsGetAfterItPrsAwait,
						onIconTap: {
							router.navigate(to: .createRunEvent)
						}
					)
					.transition(.opacity)
					Spacer(minLength: 25)
					Spacer()
				} else {
					activityList
						.transition(.opacity)
				}
			}
			.animation(.easeInOut(duration: 0.25), value: viewModel.filteredActivities.isEmpty)
		}
		.appBackground()
		// ── Filter Bottom Sheet ────────────────────────────────────
		.sheet(isPresented: $isFilterSheetPresented) {
			FilterSheetView(
				distanceMin:    $viewModel.filterDistanceMin,
				distanceMax:    $viewModel.filterDistanceMax,
				filterDate:     $viewModel.filterDate,
				filterLocation: $viewModel.filterLocation,
				onApply: {
					viewModel.applyFilter()
				},
				onClear: {
					viewModel.clearFilter()
					isFilterSheetPresented = false
				},
				onDismiss: {
					isFilterSheetPresented = false
				}
			)
			.applySheetSizing(height: 580)
			.presentationBackground(.whiteApp)
			.scrollDismissesKeyboard(.immediately)

			
		}
	}
}

// MARK: - Subviews
private extension HistoryScreen {
	
	// MARK: Search Bar
	var searchBar: some View {
		AppTextField(
			text: $viewModel.searchText,
			placeholder: .searchHere,
			leadingView: AnyView(Image(.icSearch)),
			trailingView: AnyView(
				Button(action: {
					isFilterSheetPresented = true
				}, label: {
					Image(viewModel.isFilterActive ? .icFilterApplied : .icFilter)
				})
			),
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
					
					NavigationLink {
						EventDetailsScreen(activityData: activity)
					} label: {
						PaceRunActivityCard(activity: activity)
					}

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

