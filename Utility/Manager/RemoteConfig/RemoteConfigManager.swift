//
//  RemoteConfigManager.swift
//  PaceApp
//

import FirebaseRemoteConfig

/// Firebase Remote Config — single source for remotely-tunable values, synced to Android via
/// the shared thepaceapp project. Defaults are applied immediately, so every value is safe
/// before the first fetch; `refresh()` then activates the latest. Mirrors Android RemoteConfigManager.
@Observable
@MainActor
final class RemoteConfigManager {

	// MARK: - Singleton
	static let shared = RemoteConfigManager()

	// MARK: - State

	/// Free-tier event limit, live. Seeded from the defaults, updated after each activate.
	private(set) var freeEventLimit: Int = RevenueCatConst.freeEventLimit

	// MARK: - Private
	private let remoteConfig: RemoteConfig

	private init() {
		remoteConfig = RemoteConfig.remoteConfig()

		let settings = RemoteConfigSettings()
		// Debug fetches every launch; release honors a 1h cache so we don't hammer the backend.
		#if DEBUG
		settings.minimumFetchInterval = 0
		#else
		settings.minimumFetchInterval = 3600
		#endif
		remoteConfig.configSettings = settings

		// Fallback = the compiled constant, so the gate works offline / before the first fetch.
		remoteConfig.setDefaults([
			Keys.freeEventLimit: NSNumber(value: RevenueCatConst.freeEventLimit),
			Keys.emailLinkDomain: Self.primaryEmailLinkDomain as NSString,
		])
		freeEventLimit = readFreeEventLimit()
	}

	// MARK: - Refresh

	/// Fetch + activate the latest values, then publish them. Failures keep the last good value.
	func refresh() {
		remoteConfig.fetchAndActivate { [weak self] _, _ in
			Task { @MainActor in
				guard let self else { return }
				self.freeEventLimit = self.readFreeEventLimit()
			}
		}
	}

	// MARK: - Helpers

	/// A non-positive remote value is treated as unset — fall back to the compiled constant.
	private func readFreeEventLimit() -> Int {
		let value = remoteConfig[Keys.freeEventLimit].numberValue.intValue
		return value > 0 ? value : RevenueCatConst.freeEventLimit
	}

	/// Email sign-in continue URL, read live from Remote Config at send time. Default = the
	/// branded custom domain; set the console value to the Firebase default domain to fail over
	/// if auth.paceapp.net ever has issues. An unknown/blank value falls back to the default, so
	/// a console typo can't break sign-in. Both hosts serve /emailSignIn and are Firebase
	/// authorized domains, and both apps accept incoming links from either on the receive side.
	func emailLinkContinueURL() -> URL {
		let domain = remoteConfig[Keys.emailLinkDomain].stringValue
			.trimmingCharacters(in: .whitespacesAndNewlines)
		let host = Self.allowedEmailLinkDomains.contains(domain) ? domain : Self.primaryEmailLinkDomain
		return URL(string: "https://\(host)/emailSignIn")!
	}

	// Email sign-in continue-URL host, remotely switchable (shared key with Android). Default =
	// the branded custom domain; set the console value to the fallback host to fail over.
	static let primaryEmailLinkDomain = "auth.paceapp.net"
	static let fallbackEmailLinkDomain = "thepaceapp.firebaseapp.com"
	private static let allowedEmailLinkDomains: Set<String> = [primaryEmailLinkDomain, fallbackEmailLinkDomain]

	// Shared keys with Android — must match the Firebase console parameter names.
	private enum Keys {
		static let freeEventLimit = "free_event_limit"
		static let emailLinkDomain = "email_link_domain"
	}
}
