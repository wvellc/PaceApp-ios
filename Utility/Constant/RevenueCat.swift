//
//  RevenueCat.swift
//  PaceApp
//

import Foundation

/// RevenueCat configuration — public SDK key, the single Pro entitlement, and
/// the free-plan event allowance. Mirrors the StravaConst style.
enum RevenueCatConst {

	/// Public App Store SDK key — used in all builds (debug + release). Testing goes through
	/// the App Store sandbox directly, not the RevenueCat Test Store.
	static let apiKey = "appl_JAHvQsjIJazEpifAdynyIXwPgik"

	/// Entitlement that unlocks Pro — configured in the RevenueCat dashboard.
	static let entitlementPro = "pace_app_pro"

	/// Fallback free-plan limit: this many live events (active + completed) before the paywall.
	/// The live value is remote-configurable via Firebase Remote Config ("free_event_limit");
	/// this constant is the offline/default.
	static let freeEventLimit = 15
}
