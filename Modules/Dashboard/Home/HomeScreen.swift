//
//  HomeScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/31/26.
//

import SwiftUI
import ConnectIQ

// MARK: - HomeScreen

struct HomeScreen: View {
	
	// MARK: - State
	
	@State private var viewModel = HomeViewModel()

	let runActions: [RunAction] = [
		RunAction(title: .newRun,      symbol: "icNewRun",      rout: .createRunEvent),
		RunAction(title: .favoriteRun, symbol: "icFavoriteRun", rout: .favoritesRun),
	]
	
	// MARK: - Environment
	
	@Environment(Router.self)           private var router
	@Environment(ConnectIQManager.self) private var ciqManager
	/// Shared navigation state to push destinations from TabBarScreen.
	@Environment(TabNavigationState.self) private var tabNavState
	
	// MARK: - Body
	
	var body: some View {
		ZStack {
			VStack(alignment: .leading, spacing: 0) {

				// MARK: Navigation bar
				AppNavigation()

				// MARK: Scrollable content — native List for smooth scroll + swipe.
				upCommingActivityList
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
			.appBackground()
			.navigationAppTitle(title: .home)
			
			if viewModel.showMetricPopup {
				MetricsPopupView(
					isPresented: $viewModel.showMetricPopup,
					metrics: viewModel.metrics,
					startingIndex: viewModel.selectedMetricIndex
				)
				.zIndex(20)
			}
		}
		// Start listener once per userId — HomeViewModel guards against redundant re-attaches.
		.task(id: AuthManager.shared.currentUserID) {
			guard let userId = AuthManager.shared.currentUserID else { return }
			viewModel.startObservingEvents(userId: userId)
		}
		.onAppear {
			// Attempt immediately in case the watch was already connected
			// before this screen appeared (e.g. restored from cold launch).
			tryShowMetricsPopup()
		}
		// Re-attempt whenever connectedDevice changes.
		// This covers the normal pairing flow (nil → device) AND the cold-launch
		// path where deviceStatusChanged fires after onAppear.
		.onChange(of: ciqManager.connectedDevice?.uuid) { _, newUUID in
			guard newUUID != nil else { return }
			tryShowMetricsPopup()
		}
		// Refresh header metrics when an event is deleted from anywhere.
		.onChange(of: EventDeletionCenter.shared.lastDeletedEventId) { _, id in
			guard let id, let userId = AuthManager.shared.currentUserID else { return }
			viewModel.handleEventDeleted(eventId: id, userId: userId)
		}
	}
	
	// MARK: - Greeting Text
	
	/// Builds a time-of-day greeting with the user's first name.
	/// Falls back to "Hey" if the name is not yet loaded.
	private var greetingText: String {
		let hour = Calendar.current.component(.hour, from: Date())
		let salutation: String
		switch hour {
		case 5..<12:  salutation = "GM,"    // Good morning
		case 12..<17: salutation = "GA,"    // Good afternoon
		default:      salutation = "GE,"    // Good evening
		}
		let name = AuthManager.shared.userDetails?.firstName?.trimmingCharacters(in: .whitespaces)
		return name.map { "\(salutation) \($0)" } ?? salutation
	}
	
	// MARK: - Metric Row
	
	private var metricRow: some View {
		HStack {
			ForEach(viewModel.metrics) { metric in
				if metric.id != viewModel.metrics.first?.id { Spacer() }
				// Always rendered in the green (high-performance) style.
				HomeMetricCard(metric: metric, isHighPerformance: true) {
					viewModel.didTapMetric(metric)
				}
				// Borderless so each capsule stays tappable inside the List row.
				.buttonStyle(.borderless)
				if metric.id != viewModel.metrics.last?.id  { Spacer() }
			}
		}
	}
	
	// MARK: - Run Action Grid
	
	private var runActionGrid: some View {
		let spacing: CGFloat = 16
		let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)
		
		return LazyVGrid(columns: columns, alignment: .center, spacing: spacing) {
			ForEach(runActions) { action in
				Button {
					ConnectIQManager.shared.forceResync()
//					router.navigate(to: action.rout)
				} label: {
					GeometryReader { geo in
						RunActionCard(action: action)
							.frame(width: geo.size.width, height: geo.size.width)
					}
					.aspectRatio(1, contentMode: .fit)
				}
				.buttonStyle(.plain)
			}
		}
		.fixedSize(horizontal: false, vertical: true)
	}
	
	// MARK: - Upcoming Activity List

	// Whole screen scrolls in one native List: header block + swipeable upcoming rows.
	private var upCommingActivityList: some View {
		List {
			// Header — one self-sizing row, keeps the original layout.
			headerBlock
				.listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)

			// Upcoming activities — native swipe-to-delete rows.
			if ciqManager.isWatchPreviouslyPaired, !viewModel.upcomingEvents.isEmpty {
				Text(.upcomingActivities)
					.font(.semiBold16)
					.foregroundColor(.whiteApp)
					.listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
					.listRowBackground(Color.clear)
					.listRowSeparator(.hidden)

				ForEach(viewModel.upcomingEvents) { activity in
					Button {
						// Push EventDetailsScreen via shared TabNavigationState.
						tabNavState.selectedActivity = activity
					} label: {
						UpcomingActivityView(activity: activity)
					}
					.buttonStyle(.plain)
					.listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 14, trailing: 16))
					.listRowBackground(Color.clear)
					.listRowSeparator(.hidden)
					.swipeActions(edge: .trailing, allowsFullSwipe: false) {
						Button {
							AppAlertManager.shared.confirmEventDeletion {
								withAnimation {
									if let syncId = activity.syncId {
										ciqManager.deleteSyncedEvent(id: syncId)
									}
								}
							}
						} label: {
							Image(systemName: "trash.fill")
						}
						.tint(.redBoho)
					}
				}
			}
		}
		.listStyle(.plain)
		.scrollContentBackground(.hidden)
		.scrollBounceBehavior(.basedOnSize)
	}

	// MARK: - Header Block

	// Greeting + sync status, then metrics/actions (or the pair-watch prompt).
	private var headerBlock: some View {
		VStack(alignment: .leading, spacing: 0) {

			// Greeting + sync status
			VStack(alignment: .leading) {
				Text(greetingText)
					.font(.bold28)
					.foregroundColor(.whiteApp)
				Text(ciqManager.lastSyncLabel)
					.font(.medium14)
					.foregroundColor(.white50)
			}

			// Home data & Pair watch view
			if !ciqManager.isWatchPreviouslyPaired {
				PairWatchView {
					router.navigate(to: .manageWatch)
				}
			} else {
				VStack(alignment: .leading, spacing: 18) {
					// Metrics — latest completed event; hidden until one exists.
					if !viewModel.metrics.isEmpty {
						metricRow
					}

					// Run Actions
					runActionGrid
				}
				.padding(.top, 16)
				.padding(.bottom, 8)
			}
		}
	}
	
	// MARK: - Metrics Popup Gate
	
	/// Shows the one-time metrics onboarding popup when:
	/// 1. A watch is currently connected.
	/// 2. AppSession.canShowMetricsOnboarding is still true.
	///
	/// Called from both .onAppear (covers already-connected state) and
	/// .onChange(of: connectedDevice) (covers the async restore / pairing path).
	private func tryShowMetricsPopup() {
		guard ciqManager.connectedDevice != nil else { return }
		guard !viewModel.metrics.isEmpty else { return }

		Task { @MainActor in
			try? await Task.sleep(seconds: 1)
			viewModel.showMetricPopup = AppSession.canShowMetricsOnboarding
			if viewModel.showMetricPopup {
				AppSession.canShowMetricsOnboarding = false
			}
		}
	}
}

// MARK: - Preview

#Preview {
	NavigationStack {
		HomeScreen()
			.environment(Router())
	}
}
