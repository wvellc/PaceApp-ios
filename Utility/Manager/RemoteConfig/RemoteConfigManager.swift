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
		remoteConfig.setDefaults([Keys.freeEventLimit: NSNumber(value: RevenueCatConst.freeEventLimit)])
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

	// Shared keys with Android — must match the Firebase console parameter names.
	private enum Keys {
		static let freeEventLimit = "free_event_limit"
	}
}
