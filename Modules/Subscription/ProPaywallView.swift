//
//  ProPaywallView.swift
//  PaceApp
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// The RevenueCat paywall (its design lives in the dashboard), wrapped so a
/// completed purchase or restore refreshes `SubscriptionManager` and dismisses.
struct ProPaywallView: View {

	@Environment(\.dismiss) private var dismiss

	var body: some View {
		PaywallView(displayCloseButton: true)
			.onPurchaseCompleted { _ in
				Task { await SubscriptionManager.shared.refresh() }
				dismiss()
			}
			.onRestoreCompleted { info in
				// Dismiss only once the entitlement is actually active.
				if info.entitlements[RevenueCatConst.entitlementPro]?.isActive == true {
					dismiss()
				}
			}
	}
}

extension View {
	/// Presents the Pro paywall as a sheet.
	func proPaywall(isPresented: Binding<Bool>) -> some View {
		sheet(isPresented: isPresented) { ProPaywallView() }
	}
}
