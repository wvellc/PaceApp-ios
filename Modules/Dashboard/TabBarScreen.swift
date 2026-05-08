
//
//  DashboardView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

import SwiftUI

/// Main tab bar controller for the app, managing navigation between key sections.
struct TabBarScreen: View {

    // MARK: State
    /// Tracks the currently selected tab in the tab bar.
    @State private var selectedTab: PaceTab = .home

    // MARK: Init
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.backgroundEffect = .init(style: .systemMaterialLight)

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

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: Builder
    /// Builds the tab bar interface using a TabView with multiple tabs.
    var body: some View {
        TabView(selection: $selectedTab) {

            // Home tab
            HomeScreen()
                .tabItem {
                    Image(PaceTab.home.assetImage(selected: selectedTab == .home))
                    Text(PaceTab.home.title)
                }
                .tag(PaceTab.home)

            // History tab
			HistoryScreen()
                .tabItem {
                    Image(PaceTab.history.assetImage(selected: selectedTab == .history))
                    Text(PaceTab.history.title)
                }
                .tag(PaceTab.history)

            // Analytics tab
            AnalyticsScreen()
                .tabItem {
                    Image(PaceTab.stats.assetImage(selected: selectedTab == .stats))
                    Text(PaceTab.stats.title)
                }
                .tag(PaceTab.stats)

            // Profile tab
			ProfileScreen()
                .tabItem {
                    Image(PaceTab.profile.assetImage(selected: selectedTab == .profile))
                    Text(PaceTab.profile.title)
                }
                .tag(PaceTab.profile)
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
    TabBarScreen()
}
