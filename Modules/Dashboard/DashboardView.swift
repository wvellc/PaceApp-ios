//
//  DashboardView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

import SwiftUI

struct DashboardView: View {
	@State private var selectedTab: PaceTab = .home
	
	/*init() {
		let appearance = UITabBarAppearance()
		appearance.configureWithOpaqueBackground()
		appearance.backgroundColor = UIColor.clear
		appearance.backgroundEffect = .init(style: .systemMaterialLight)
		
		// Selected state
		appearance.stackedLayoutAppearance.selected.iconColor = UIColor.whiteApp
		appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
			.foregroundColor: UIColor.whiteApp
		]
		
		// Unselected state — set ALL three layout types
		let unselectedColor = UIColor.fashionGray
		
		appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
		appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
			.foregroundColor: unselectedColor
		]
		appearance.inlineLayoutAppearance.normal.iconColor = unselectedColor
		appearance.inlineLayoutAppearance.normal.titleTextAttributes = [
			.foregroundColor: unselectedColor
		]
		appearance.compactInlineLayoutAppearance.normal.iconColor = unselectedColor
		appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
			.foregroundColor: unselectedColor
		]
		
		UITabBar.appearance().standardAppearance = appearance
		UITabBar.appearance().scrollEdgeAppearance = appearance
	}*/
	
	var body: some View {
		TabView(selection: $selectedTab) {
			Tab(value: PaceTab.home) {
				PlaceholderTabView(icon: PaceTab.home.systemIcon, title: PaceTab.home.title)
			} label: {
				tabLabel(for: PaceTab.home)
			}
			
			
			Tab(value: PaceTab.history) {
				PlaceholderTabView(icon: PaceTab.history.systemIcon, title: PaceTab.history.title)
			} label: {
				tabLabel(for: PaceTab.history)
			}
			
			Tab(value: PaceTab.stats) {
				PlaceholderTabView(icon: PaceTab.stats.systemIcon, title: PaceTab.stats.title)
			} label: {
				tabLabel(for: PaceTab.stats)
			}
			
			Tab(value: PaceTab.profile) {
				PlaceholderTabView(icon: PaceTab.profile.systemIcon, title: PaceTab.profile.title)
			} label: {
				tabLabel(for: PaceTab.profile)
			}
		}
		.tint(.neonAquaBlue)
		
	}
	
	// Helper to clean up repetition
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
	
	//
	//	struct PaceTabLabel: View {
	//		let tab: PaceTab
	//		let isSelected: Bool
	//		var badgeCount: Int = 0
	//
	//		var body: some View {
	//			VStack(spacing: 4) {
	//				ZStack(alignment: .topTrailing) {
	//					Image(tab.assetImage)
	//						.renderingMode(.template)
	//						.resizable()
	//						.scaledToFit()
	//						.frame(width: 24, height: 24)
	//
	//					if badgeCount > 0 {
	//						Text("\(badgeCount)")
	//							.font(.system(size: 9, weight: .bold))
	//							.foregroundStyle(.white)
	//							.padding(3)
	//							.background(Color.red, in: Circle())
	//							.offset(x: 8, y: -6)
	//					}
	//				}
	//
	//				Text(tab.title)
	//					.font(.system(size: 10, weight: isSelected ? .semibold : .regular))
	//			}
	//			.foregroundStyle(isSelected ? Color.white : Color.orange)
	//		}
	//	}
}


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


