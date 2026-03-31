//
//  PaceTab.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/31/26.
//

import Foundation


enum PaceTab: Int, CaseIterable {
    case home, history, stats, profile

    var systemIcon: String {
        switch self {
        case .home:    return "house.fill"
        case .history: return "clock.arrow.circlepath"
        case .stats:   return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }

	var title: LocalizedStringResource {
        switch self {
			case .home: return LocalizedStringResource.home
			case .history: return LocalizedStringResource.history
			case .stats: return LocalizedStringResource.analytics
			case .profile: return LocalizedStringResource.profile
        }
    }
	
	// ← Add this for your custom assets
	func assetImage(selected:Bool) -> String {
		if selected {
			switch self {
				case .home:    return "icTabHomeSelected"
				case .history: return "icTabHistorySelected"
				case .stats:   return "icTabAnalyticsSelected"
				case .profile: return "icTabProfileSelected"
			}

		} else {
			switch self {
				case .home:    return "icTabHome"
				case .history: return "icTabHistory"
				case .stats:   return "icTabAnalytics"
				case .profile: return "icTabProfile"
			}

		}
	}
}

