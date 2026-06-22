//
//  HistoryScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/10/26.
//

import SwiftUI

// MARK: - History Screen

struct HistoryScreen: View {
	
	// MARK: - Properties
	
	@State private var viewModel = HistoryViewModel()
	@FocusState var focusedField: Bool?
	@State private var isFilterSheetPresented = false
	
	/// Tracks which activity is currently being navigated to
	@State private var selectedActivity: ActivityData?
	
	// MARK: - Environment
	
	@Environment(Router.self) private var router
	@Environment(ConnectIQManager.self) private var ciqManager
	
	// MARK: - Body
	
	var body: some View {
		NavigationStack {
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
					if viewModel.activities.isEmpty && !viewModel.isLoading {
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
			.sheet(isPresented: $isFilterSheetPresented) {
				FilterSheetView(
					distanceMin:    $viewModel.filterDistanceMin,
					distanceMax:    $viewModel.filterDistanceMax,
					filterDate:     $viewModel.filterDate,
					filterLocation: $viewModel.filterLocation,
					onApply: { viewModel.applyFilter() },
					onClear: {
						viewModel.clearFilter()
						isFilterSheetPresented = false
					},
					onDismiss: { isFilterSheetPresented = false }
				)
				.applySheetSizing(height: 580)
				.presentationBackground(.whiteApp)
				.scrollDismissesKeyboard(.immediately)
			}
			// navigationDestination is on the NavigationStack content root — outside
			// the lazy List — so the stack can always see the destination.
			.navigationDestination(item: $selectedActivity) { activity in
				EventDetailsScreen(activityData: activity)
			}
			// Capture userId once on first appear and start observing events.
			.onAppear {
				guard let userId = AuthManager.shared.currentUserID else { return }
				viewModel.startObservingEvents(userId: userId)
			}
		}
	}
}

// MARK: - Subviews

private extension HistoryScreen {
	
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
		.onSubmit { focusedField = false }
	}
	
	@ViewBuilder
	var activityList: some View {
		List(selection: $selectedActivity) {
			ForEach(viewModel.filteredActivities) { activity in
				Button {
					selectedActivity = activity
				} label: {
					PaceRunActivityCard(activity: activity)
				}
				.buttonStyle(.plain)
				.listRowInsets(EdgeInsets(top: 8, leading: Constant.UI.defaultPadding, bottom: 8, trailing: Constant.UI.defaultPadding))
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
				.swipeActions(edge: .trailing, allowsFullSwipe: true) {
					Button(role: .destructive) {
						withAnimation {
							if let syncId = activity.syncId {
								ciqManager.deleteSyncedEvent(id: syncId)
							} else {
								viewModel.delete(event: activity)
							}
						}
					} label: {
						Image(systemName: "trash.fill")
					}
					.tint(.redBoho)
					
					NavigationLink {
						withAnimation { CreateRunEventScreen(type: .duplicate, intialData: activity) }
					} label: {
						Image(systemName: "plus.square.fill.on.square.fill")
					}
					.tint(.neonAquaBlue)
				}
			}
		}
		.listStyle(.plain)
		.padding(.top, Constant.UI.defaultPadding / 2)
	}
}

// MARK: - Preview

#Preview {
	HistoryScreen()
}
