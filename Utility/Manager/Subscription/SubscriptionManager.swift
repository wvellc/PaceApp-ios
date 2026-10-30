//
//  SubscriptionManager.swift
//  PaceApp
//

import Foundation
import RevenueCat

/// Single source of truth for the user's subscription state (RevenueCat).
/// `isPro` drives every paywall gate; the UI observes it, so a completed
/// purchase unlocks the app instantly without a relaunch.
@Observable
@MainActor
final class SubscriptionManager {

	// MARK: - Singleton
	static let shared = SubscriptionManager()
	private init() {}

	// MARK: - State

	/// True while the `pace_app_pro` entitlement is active.
	private(set) var isPro = false

	/// Latest customer info — exposed for the Customer Center and debugging.
	private(set) var customerInfo: CustomerInfo?

	// MARK: - Plan Details

	/// The active Pace Pro entitlement, when subscribed.
	var proEntitlement: EntitlementInfo? {
		customerInfo?.entitlements[RevenueCatConst.entitlementPro]
	}

	/// Renewal (or expiry) date of the active plan.
	var renewalDate: Date? { proEntitlement?.expirationDate }

	/// True when the plan auto-renews — false once cancelled but still active.
	var willRenew: Bool { proEntitlement?.willRenew ?? false }

	/// Billing period label from the product id — "Monthly" / "Yearly".
	var planPeriodTitle: String {
		let id = proEntitlement?.productIdentifier.lowercased() ?? ""
		if id.contains("year") || id.contains("annual") { return "Yearly" }
		if id.contains("month") { return "Monthly" }
		return "Pro"
	}

	/// Streams live CustomerInfo updates; cancelled on reconfigure.
	@ObservationIgnored private var streamTask: Task<Void, Never>?

	// MARK: - Configuration

	/// Configure once at launch (AppDelegate). Seeds the current entitlement and
	/// starts listening for updates. Passes the signed-in uid when we already have one.
	func configure() {
		guard !Purchases.isConfigured else { return }
		#if DEBUG
		Purchases.logLevel = .debug
		#endif
		Purchases.configure(withAPIKey: RevenueCatConst.apiKey, appUserID: AuthManager.shared.currentUserID)
		observeCustomerInfo()
		Task { await refresh() }
	}

	// MARK: - Identity

	/// Aliases the RevenueCat customer to the Firebase uid so Pro follows the user
	/// across devices and reinstalls. Called on sign-in.
	func identify(userId: String) {
		guard Purchases.isConfigured else { return }
		Task {
			if let result = try? await Purchases.shared.logIn(userId) { apply(result.customerInfo) }
		}
	}

	/// Resets to an anonymous RevenueCat user. Called on sign-out.
	func signOut() {
		guard Purchases.isConfigured else { return }
		Task {
			if let info = try? await Purchases.shared.logOut() { apply(info) }
		}
	}

	// MARK: - Customer Info

	/// Pulls the latest entitlement state. Safe to call anytime (post-purchase, foreground).
	func refresh() async {
		guard Purchases.isConfigured else { return }
		if let info = try? await Purchases.shared.customerInfo() { apply(info) }
	}

	/// Restores purchases for a reinstalling / switching user.
	func restore() async throws {
		apply(try await Purchases.shared.restorePurchases())
	}

	// MARK: - Gating

	/// Free users may keep up to `freeEventLimit` live events; Pro is unlimited.
	/// Fails open on a count error so a genuine user is never wrongly blocked.
	func canCreateEvent() async -> Bool {
		if isPro { return true }
		guard let uid = AuthManager.shared.currentUserID else { return true }
		let count = (try? await EventRepository.shared.countActiveAndCompletedEvents(userId: uid)) ?? 0
		// Limit is remote-configurable (Firebase Remote Config), falling back to the constant.
		return count < RemoteConfigManager.shared.freeEventLimit
	}

	// MARK: - Private

	private func observeCustomerInfo() {
		streamTask?.cancel()
		streamTask = Task { [weak self] in
			for await info in Purchases.shared.customerInfoStream {
				self?.apply(info)
			}
		}
	}

	private func apply(_ info: CustomerInfo) {
		customerInfo = info
		isPro = info.entitlements[RevenueCatConst.entitlementPro]?.isActive == true
	}
}
