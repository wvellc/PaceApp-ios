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
		// Force the app's Gilroy family — RevenueCatUI otherwise renders the
		// dashboard paywall in the system font on device.
		PaywallView(fonts: GilroyPaywallFontProvider(), displayCloseButton: true)
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
	/// Presents the Pro paywall full-screen (its close button handles dismissal).
	func proPaywall(isPresented: Binding<Bool>) -> some View {
		fullScreenCover(isPresented: isPresented) { ProPaywallView() }
	}
}

/// Maps each paywall text style to the matching Gilroy weight so headings stay
/// bold and body stays regular — keeps the paywall on-brand on device.
struct GilroyPaywallFontProvider: PaywallFontProvider {
	func font(for textStyle: Font.TextStyle) -> Font {
		let gilroy: Gilroy
		let size: CGFloat
		switch textStyle {
			case .largeTitle:  gilroy = .bold;     size = 34
			case .title:       gilroy = .bold;     size = 28
			case .title2:      gilroy = .semiBold; size = 22
			case .title3:      gilroy = .semiBold; size = 20
			case .headline:    gilroy = .semiBold; size = 17
			case .callout:     gilroy = .medium;   size = 16
			case .subheadline: gilroy = .medium;   size = 15
			case .footnote:    gilroy = .regular;  size = 13
			case .caption:     gilroy = .regular;  size = 12
			case .caption2:    gilroy = .regular;  size = 11
			default:           gilroy = .regular;  size = 17
		}
		return .custom(gilroy.rawValue, size: size, relativeTo: textStyle)
	}
}
