//
//  RevenueCat.swift
//  PaceApp
//

import Foundation

/// RevenueCat configuration — public SDK key, the single Pro entitlement, and
/// the free-plan event allowance. Mirrors the StravaConst style.
enum RevenueCatConst {

	/// Public SDK key for the RevenueCat Test Store app — lets us test the full
	/// purchase flow without App Store Connect. Swap for the App Store `appl_` key
	/// once the production app + real subscriptions exist.
	static let apiKey = "test_coTeDAnJOHJiWNNAEeLpKTHcacO"

	/// Entitlement that unlocks Pro — configured in the RevenueCat dashboard.
	static let entitlementPro = "pace_app_pro"

	/// Free plan allows this many live events (active + completed) before the paywall.
	static let freeEventLimit = 15
}
