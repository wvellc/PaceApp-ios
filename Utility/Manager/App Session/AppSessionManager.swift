//
//  AppSessionManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import Foundation

/*
 // Saving data
 AppSession.userId = "user_778899"
 AppSession.isUserAuthenticated = true
 
 // Clearing data on logout
 AppSession.removeAllData()
 
 SwiftUI Specific Bonus: @AppStorage
 struct MainView: View {
 // This automatically watches UserDefaults and updates the UI when it changes
 @AppStorage(AppSessionKey.isUserAuthenticated.rawValue) var isUserAuthenticated = false
 
 var body: some View {
 if isUserAuthenticated {
 DashboardView()
 } else {
 LoginView()
 }
 }
 }
 */


// MARK: App Session Manager
enum AppSession {
    // Standard iOS storage reference
    private static let defaults = UserDefaults.standard

    // Ignore keys while clearing session
    private static let ignoreKeyList: [AppSessionKey] = [.isUserCanViewMetricsPopUp]

    // MARK: - Generic Storage Add-ons
    // These generic helpers eliminate repetitive JSON encoding/decoding boilerplate

    private static func saveObject<T: Encodable>(_ object: T?, forKey key: AppSessionKey) {
        guard let object = object else {
            defaults.removeObject(forKey: key.rawValue)
            return
        }
        if let encodedData = try? JSONEncoder().encode(object) {
            defaults.set(encodedData, forKey: key.rawValue)
        }
    }

    private static func readObject<T: Decodable>(forKey key: AppSessionKey, as type: T.Type) -> T? {
        guard let savedData = defaults.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: savedData)
    }

    // MARK: - Session Operations (Using Clean Computed Properties)

    // USER CAN SHOW METRICS POPUP
    static var canShowMetricsOnboarding: Bool {
        get {
            defaults.object(forKey: AppSessionKey.isUserCanViewMetricsPopUp.rawValue) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: AppSessionKey.isUserCanViewMetricsPopUp.rawValue)
        }
    }

    // MARK: - Watch Persistence

    // PAIRED WATCH UUID
    // Quick sentinel: non-nil means the user has paired at least once.
    static var pairedWatchUUID: String? {
        get { defaults.string(forKey: AppSessionKey.pairedWatchUUID.rawValue) }
        set { defaults.set(newValue, forKey: AppSessionKey.pairedWatchUUID.rawValue) }
    }

    // PAIRED DEVICES (full identity snapshot: UUID + modelName + friendlyName)
    static var pairedDevices: [PersistedDevice] {
        get { readObject(forKey: .pairedDevices, as: [PersistedDevice].self) ?? [] }
        set { saveObject(newValue, forKey: .pairedDevices) }
    }

    // LAST WATCH SYNC DATE
    // Persisted so the greeting sync label survives app restarts.
    // Date conforms to RawRepresentable (ISO8601) via Date+Ext, so @AppStorage-style
    // round-trips work; here we store it as a Double (timeIntervalSince1970) for simplicity.
    static var lastWatchSyncDate: Date? {
        get {
            let t = defaults.double(forKey: AppSessionKey.lastWatchSyncDate.rawValue)
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set {
            if let date = newValue {
                defaults.set(date.timeIntervalSince1970, forKey: AppSessionKey.lastWatchSyncDate.rawValue)
            } else {
                defaults.removeObject(forKey: AppSessionKey.lastWatchSyncDate.rawValue)
            }
        }
    }

    // MARK: - Management Methods

    /// Remove stored session using key
    static func removeSession(for key: AppSessionKey) {
        defaults.removeObject(forKey: key.rawValue)
    }

    /// Clear all session data honoring ignored keys
    static func removeAllData() {
        for key in AppSessionKey.allCases {
            if !ignoreKeyList.contains(key) {
                defaults.removeObject(forKey: key.rawValue)
            }
        }
    }
}
