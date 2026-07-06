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
	
	// MARK: - Environment
	
	@Environment(Router.self) private var router
	@Environment(ConnectIQManager.self) private var ciqManager
	/// Shared navigation state to push destinations from TabBarScreen.
	@Environment(TabNavigationState.self) private var tabNavState
	
	// MARK: - Body
	
	var body: some View {
		// Global NavigationStack in PaceApp.swift is the single navigation host.
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
				if viewModel.filteredActivities.isEmpty && !viewModel.isLoading {
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
				} else if viewModel.isLoading {
					Spacer()
					ProgressView()
						.scaleEffect(1.5)
						.tint(.neonAquaBlue)
					Spacer()
				} else {
					activityList
						.transition(.opacity)
				}
			}
			.animation(.easeInOut(duration: 0.25), value: viewModel.activities.isEmpty)
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
		// Capture userId once on first appear and start loading events.
		.onAppear {
			guard let userId = AuthManager.shared.currentUserID else { return }
			viewModel.startLoading(userId: userId)
		}
		// Re-sync History whenever the watch reports a fresh completed event —
		// lastWatchSyncDate is a stored @Observable var, written after every
		// successful watch sync, so this fires without any manual pull needed.
		.onChange(of: ciqManager.lastWatchSyncDate) {
			Task { await viewModel.refresh() }
		}
		// Prune immediately when an event is deleted from anywhere (Details, Home, …).
		.onChange(of: EventDeletionCenter.shared.lastDeletedEventId) { _, id in
			if let id { viewModel.removeLocally(eventId: id) }
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
		List {
			ForEach(viewModel.filteredActivities) { activity in
				Button {
					// Push EventDetailsScreen via shared TabNavigationState
					tabNavState.selectedActivity = activity
				} label: {
					PaceRunActivityCard(activity: activity)
				}
				.buttonStyle(.plain)
				.listRowInsets(EdgeInsets(top: 8, leading: Constant.UI.defaultPadding, bottom: 8, trailing: Constant.UI.defaultPadding))
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
				.swipeActions(edge: .trailing, allowsFullSwipe: false) {
					Button(role: .destructive) {
						// Confirm before deleting — destructive and irreversible.
						AppAlertManager.shared.confirmEventDeletion {
							withAnimation {
								if let syncId = activity.syncId {
									ciqManager.deleteSyncedEvent(id: syncId)
								} else {
									viewModel.delete(event: activity)
								}
							}
						}
					} label: {
						Image(systemName: "trash.fill")
					}
					.tint(.redBoho)
					
						Button {
						router.navigate(to: .createRunEvent)
					} label: {
						Image(systemName: "plus.square.fill.on.square.fill")
					}
					.tint(.neonAquaBlue)
				}
				// Pagination trigger: load next page when the last item appears.
				.onAppear {
					if activity.id == viewModel.filteredActivities.last?.id {
						viewModel.loadNextPage()
					}
				}
			}
			
			// Loading-more indicator at the bottom of the list
			if viewModel.isLoadingMore {
				HStack {
					Spacer()
					ProgressView()
						.tint(.neonAquaBlue)
						.padding(.vertical, 16)
					Spacer()
				}
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
			}
		}
		.listStyle(.plain)
		.padding(.top, Constant.UI.defaultPadding / 2)
		.tint(.purple)
		// Pull-to-refresh: re-fetches page 1 with committed filters and resets pagination.
		.refreshable {
			await viewModel.refresh()
		}
	}
}

// MARK: - Preview

#Preview {
	HistoryScreen()
}
