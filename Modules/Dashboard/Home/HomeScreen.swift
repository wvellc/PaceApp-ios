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
				
				// MARK: Scrollable content
				ScrollView(showsIndicators: false) {
					VStack(alignment: .leading, spacing: 0) {
						
						// MARK: Greeting + sync status
						VStack(alignment: .leading) {
							Text(greetingText)
								.font(.bold28)
								.foregroundColor(.whiteApp)
							Text(ciqManager.lastSyncLabel)
								.font(.medium14)
								.foregroundColor(.white50)
						}
						
						// MARK: Home data & Pair watch view
						if !ciqManager.isWatchPreviouslyPaired {
							PairWatchView {
								router.navigate(to: .manageWatch)
							}
						} else {
							VStack(alignment: .leading, spacing: 16) {
								// Metrics — latest completed event; hidden until one exists.
								if !viewModel.metrics.isEmpty {
									metricRow
								}

								// Run Actions
								runActionGrid
								
								// Recent Activity
								UpcomingActivitySection
							}
							.padding(.vertical, 16)
						}
					}
					.padding(.horizontal, 16)
					.padding(.bottom, 18)
				}
				.scrollBounceBehavior(.basedOnSize)
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
					router.navigate(to: action.rout)
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
	
	// MARK: - Upcoming Activity
	
	private var UpcomingActivitySection: some View {
		VStack(alignment: .leading, spacing: 16) {
			if !viewModel.upcomingEvents.isEmpty {
				Text(.upcomingActivities)
					.font(.semiBold16)
					.foregroundColor(.whiteApp)
			}
			
			VStack(spacing: 16) {
				ForEach(viewModel.upcomingEvents) { activity in
					// Push EventDetailsScreen via shared TabNavigationState
					Button {
						tabNavState.selectedActivity = activity
					} label: {
						UpcomingActivityView(activity: activity)
					}
					.buttonStyle(.plain)
					.swipeActions(edge: .trailing, allowsFullSwipe: true) {
						Button(role: .destructive) {
							// Confirm before deleting — destructive and irreversible.
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
