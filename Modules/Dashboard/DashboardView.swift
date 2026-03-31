//
//  DashboardView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

import SwiftUI

/// Main tab bar controller for the app, managing navigation between key sections.
struct DashboardView: View {
	
	// MARK: State
	/// Tracks the currently selected tab in the tab bar.
	@State private var selectedTab: PaceTab = .home
	
	// MARK: Builder
	/// Builds the tab bar interface using a TabView with multiple tabs.
	var body: some View {
		TabView(selection: $selectedTab) {
			// Home tab
			Tab(value: PaceTab.home) {
				HomeScreen()
			} label: {
				tabLabel(for: PaceTab.home)
			}
			
			// History tab
			Tab(value: PaceTab.history) {
				PlaceholderTabView(icon: PaceTab.history.systemIcon, title: PaceTab.history.title)
			} label: {
				tabLabel(for: PaceTab.history)
			}
			
			// Stats tab
			Tab(value: PaceTab.stats) {
				PlaceholderTabView(icon: PaceTab.stats.systemIcon, title: PaceTab.stats.title)
			} label: {
				tabLabel(for: PaceTab.stats)
			}
			
			// Profile tab
			Tab(value: PaceTab.profile) {
				PlaceholderTabView(icon: PaceTab.profile.systemIcon, title: PaceTab.profile.title)
			} label: {
				tabLabel(for: PaceTab.profile)
			}
		}
		.tint(.neonAquaBlue)
		
	}
	
	// Helper to clean up repetition
	/// Helper function for generating tab labels with conditional styling based on selection state.
	private func tabLabel(for tab: PaceTab) -> some View {
		let isSelected = selectedTab == tab
		return Label {
			Text(tab.title)
				.foregroundStyle(isSelected ? Color.white : Color.orange)
		} icon: {
			Image(tab.assetImage(selected: isSelected))
				.foregroundStyle(isSelected ? Color.white : Color.orange)
		}
		
	}
	
} // End of DashboardView


struct PlaceholderTabView: View {
	let icon: String
	let title: LocalizedStringResource
	
	var body: some View {
		VStack(spacing: 16) {
			Image(systemName: icon)
				.font(.system(size: 52, weight: .ultraLight))
				.foregroundStyle(.white.opacity(0.28))
			Text(title)
				.font(.system(size: 22, weight: .semibold, design: .rounded))
				.foregroundStyle(.white.opacity(0.40))
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.appBackground()
	}
}

#Preview("Pace App") {
	DashboardView()
}

