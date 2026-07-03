//
//  TabBarScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

import SwiftUI

/// Main tab bar controller for the app, managing navigation between key sections.
struct TabBarScreen: View {
	
	// MARK: - Tab Selection
	
	/// Tracks the currently selected tab in the tab bar.
	@State private var selectedTab: PaceTab = .home

	// MARK: - Navigation State
	/// Shared state for tab children routing, observed outside the lazy TabView.
	@State private var tabNavState = TabNavigationState()
	
	// MARK: - Stable Tab Views
	//
	// Each tab is held as a @State property so SwiftUI preserves the view identity
	// (and therefore its own @State, including the ViewModel) across tab switches.
	//
	// Without this, the TabView body re-evaluates on every selectedTab change,
	// constructing new structs like HistoryScreen() and AnalyticsScreen(), which
	// causes SwiftUI to re-create their @State — including the ViewModel — on
	// every tab switch. That is the continuous init() loop we were seeing.
	
	@State private var homeScreen      = HomeScreen()
	@State private var historyScreen   = HistoryScreen()
	@State private var analyticsScreen = AnalyticsScreen()
	@State private var profileScreen   = ProfileScreen()
	
	// MARK: - Init
	
	init() {
		let appearance = UITabBarAppearance()
		appearance.configureWithOpaqueBackground()
		appearance.backgroundColor = UIColor.clear
		appearance.backgroundEffect = .init(style: .dark)
		
		let selected = UIColor(Color.neonAquaBlue)
		let normal   = UIColor(Color.neonAquaBlue).withAlphaComponent(0.4)
		
		[appearance.stackedLayoutAppearance,
		 appearance.inlineLayoutAppearance,
		 appearance.compactInlineLayoutAppearance].forEach {
			$0.selected.iconColor = selected
			$0.selected.titleTextAttributes = [.foregroundColor: selected]
			$0.normal.iconColor = normal
			$0.normal.titleTextAttributes = [.foregroundColor: normal]
		}
		
		UITabBar.appearance().standardAppearance   = appearance
		UITabBar.appearance().scrollEdgeAppearance = appearance
	}
	
	// MARK: - Body
	
	/// Builds the tab bar interface using a TabView with multiple tabs.
	var body: some View {
		TabView(selection: $selectedTab) {
			
			// Home tab
			homeScreen
				.tabItem {
					Image(PaceTab.home.assetImage(selected: selectedTab == .home))
					Text(PaceTab.home.title)
				}
				.tag(PaceTab.home)
			
			// History tab
			historyScreen
				.tabItem {
					Image(PaceTab.history.assetImage(selected: selectedTab == .history))
					Text(PaceTab.history.title)
				}
				.tag(PaceTab.history)
			
			// Analytics tab
			analyticsScreen
				.tabItem {
					Image(PaceTab.stats.assetImage(selected: selectedTab == .stats))
					Text(PaceTab.stats.title)
				}
				.tag(PaceTab.stats)
			
			// Profile tab
			profileScreen
				.tabItem {
					Image(PaceTab.profile.assetImage(selected: selectedTab == .profile))
					Text(PaceTab.profile.title)
				}
				.tag(PaceTab.profile)
		}
		// Inject navigation state so tab children can write their selection.
		.environment(tabNavState)
		// ── Navigation Destinations (placed outside TabView to satisfy SwiftUI) ──
		.navigationDestination(item: Bindable(tabNavState).selectedActivity) { activity in
			EventDetailsScreen(activityData: activity)
		}
		.navigationDestination(item: Bindable(tabNavState).selectedMetric) { metric in
			if let vm = tabNavState.analyticsViewModel {
				AnalyticsDetailScreen(
					metricType: metric,
					initialPeriod: vm.selectedPeriod,
					viewModel: vm
				)
			}
		}
	}
}

// MARK: - Preview

#Preview("Pace App") {
	TabBarScreen()
}
