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
 
 // Reading data
 if AppSession.isUserAuthenticated {
 print("Welcome back, \(AppSession.userId ?? "Unknown")!")
 }
 
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
	private static let ignoreKeyList: [AppSessionKey] = [.configDetails]
	
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
	
	// USER AUTHENTICATION
	static var isUserAuthenticated: Bool {
		get { defaults.bool(forKey: AppSessionKey.isUserAuthenticated.rawValue) }
		set { defaults.set(newValue, forKey: AppSessionKey.isUserAuthenticated.rawValue) }
	}
	
	// USER ID
	static var userId: String? {
		get { defaults.string(forKey: AppSessionKey.userId.rawValue) }
		set { defaults.set(newValue, forKey: AppSessionKey.userId.rawValue) }
	}
	
	// USER PROFILE STATUS
	static var isUserProfileCompleted: Bool {
		get { defaults.bool(forKey: AppSessionKey.isUserProfileCompleted.rawValue) }
		set { defaults.set(newValue, forKey: AppSessionKey.isUserProfileCompleted.rawValue) }
	}
	
	// USER DISTANCE TYPE
	static var userDistanceUnit: MeasureUnit {
		get {
			MeasureUnit(
				rawValue: defaults.string(forKey: AppSessionKey.distanceUnit.rawValue) ?? MeasureUnit.miles.rawValue
			) ?? MeasureUnit.miles
		}
		set { defaults.set(newValue.rawValue, forKey: AppSessionKey.distanceUnit.rawValue) }
	}
	
	// USER GAIT DATA (Utilizing the Generic Object Handlers)
	static var userGaitData: GaitUserData? {
		get { readObject(forKey: .userGait, as: GaitUserData.self) }
		set { saveObject(newValue, forKey: .userGait) }
	}
	
	// MARK: - Watch Persistence
	
	// PAIRED WATCH UUID
	// Quick sentinel: non-nil means the user has paired at least once.
	static var pairedWatchUUID: String? {
		get { defaults.string(forKey: AppSessionKey.pairedWatchUUID.rawValue) }
		set { defaults.set(newValue, forKey: AppSessionKey.pairedWatchUUID.rawValue) }
	}
	
	// PAIRED DEVICES (full identity snapshot: UUID + modelName + friendlyName)
	//
	// The ConnectIQ SDK only produces IQDevice objects from the GCM URL callback.
	// We persist a lightweight PersistedDevice snapshot here so that on cold launch
	// ConnectIQManager.restoreSessionIfNeeded() can reconstruct IQDevice instances
	// and call register(forDeviceEvents:) — the SDK immediately fires
	// deviceStatusChanged with the real live connection status, no GCM needed.
	static var pairedDevices: [PersistedDevice] {
		get { readObject(forKey: .pairedDevices, as: [PersistedDevice].self) ?? [] }
		set { saveObject(newValue, forKey: .pairedDevices) }
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
