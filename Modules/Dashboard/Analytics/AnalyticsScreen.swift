//
//  AnalyticsScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/8/26.
//
//  The main Analytics tab screen. Shows a scrollable list of metric cards,
//  each containing a compact PaceAreaChart. Tapping navigates to the detail view.

import SwiftUI

struct AnalyticsScreen: View {
	
	// MARK: - State
	
	@State private var viewModel: AnalyticsViewModel?
	
	// Captured once when the view first appears — used as the stable .task id
	// so that @Observable re-renders on AuthManager (e.g. token refresh writing
	// the same currentUser value) do not cancel and restart the task, which was
	// causing AnalyticsViewModel.init to fire on every tab switch.
	@State private var resolvedUserId: String?

	// MARK: - Environment

	/// Shared navigation state to push destinations from TabBarScreen.
	@Environment(TabNavigationState.self) private var tabNavState
	
	// MARK: - Body
	
	var body: some View {
		// Global NavigationStack in PaceApp.swift is the single navigation host.
		VStack {
			// MARK: App Navigation bar
			AppNavigation()
			
			// MARK: Main scrollable content
			ScrollView(showsIndicators: false) {
				VStack(spacing: 16) {
					
					// Metric Cards
					ForEach(AnalyticsMetricType.allCases) { metric in
						AnalyticsMetricRow(
							metricType: metric,
							dataPoints: viewModel?.dataPointsByMetric[metric] ?? [],
							onTap: {
								// Push AnalyticsDetailScreen via shared TabNavigationState
								tabNavState.analyticsViewModel = viewModel
								tabNavState.selectedMetric = metric
							}
						)
					}
					
					Spacer(minLength: 32)
				}
				.padding(.horizontal, 16)
				.padding(.bottom, 16)
			}
		}
		.appBackground()
		// Capture userId once on first appear — never re-assigned after that.
		// This breaks the observation cycle where currentUser writes on token
		// refresh would invalidate the body, change the task id, and restart init.
		.onAppear {
			guard resolvedUserId == nil else { return }
			resolvedUserId = AuthManager.shared.currentUserID
		}
		// Task id is the stable resolvedUserId, not the live computed property.
		// Will only re-fire if the user actually signs out and back in.
		.task(id: resolvedUserId) {
			guard let userId = resolvedUserId else { return }
			// Skip if already initialised for this userId.
			if viewModel?.userId == userId { return }
			let vm = AnalyticsViewModel(userId: userId)
			viewModel = vm
			await vm.load()
		}
	}
}

// MARK: - Preview

#Preview {
	AnalyticsScreen()
}
