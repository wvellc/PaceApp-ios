//
//  AppDelegate.swift
//  PaceApp
//

import SwiftUI
import ConnectIQ
import FirebaseCore
import FirebaseAuth
import Logging
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
	
	func application(_ application: UIApplication,
					 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		logger.debug("Application did finish launching")
		
		// Configure Firebase — MUST run before any Auth.auth() calls.
		FirebaseApp.configure()
		
		// Register the global auth-state listener now that Firebase is ready.
		AuthManager.shared.configure()
		
		// Get a reference to Firestore
		let db = Firestore.firestore()
		
		// Configure Firestore settings
		let settings = db.settings
		
		// --- Set your desired cache size using PersistentCacheSettings ---
		let desiredCacheSize: NSNumber = 500 * 1024 * 1024 as NSNumber // Example: 500 MB in bytes
		settings.cacheSettings = PersistentCacheSettings(sizeBytes: desiredCacheSize)
		db.settings = settings
		
		// Firebase Phone Auth requires APNs for silent device verification.
		// Register early so the token is available before the user taps Send OTP.
		UIApplication.shared.registerForRemoteNotifications()
		
		return true
	}
	
	// MARK: - APNs — Required for Firebase Phone Auth
	
	/// Passes the APNs device token to Firebase Auth.
	/// Using `.unknown` lets Firebase automatically choose sandbox vs production
	/// based on the provisioning profile — no manual #if DEBUG branching needed.
	func application(_ application: UIApplication,
					 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		Auth.auth().setAPNSToken(deviceToken, type: .unknown)
		logger.debug("APNs token registered with Firebase Auth")
	}
	
	func application(_ application: UIApplication,
					 didFailToRegisterForRemoteNotificationsWithError error: Error) {
		logger.error("APNs registration failed — Firebase will fall back to reCAPTCHA",
					 metadata: ["error": "\(error.localizedDescription)"])
	}
	
	/// Forwards Firebase silent push notifications used during phone number verification.
	func application(_ application: UIApplication,
					 didReceiveRemoteNotification userInfo: [AnyHashable: Any],
					 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		if Auth.auth().canHandleNotification(userInfo) {
			completionHandler(.newData)
			return
		}
		completionHandler(.noData)
	}
	
	// MARK: - URL Scheme — Required for Firebase reCAPTCHA fallback
	
	func application(_ app: UIApplication,
					 open url: URL,
					 options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
		
		if Auth.auth().canHandle(url) { return true }
		
		ConnectIQManager.shared.handleOpenURL(url)
		return true
	}
	
	// MARK: - Universal Links — Required for Firebase Email Sign-In
	
	func application(_ application: UIApplication,
					 continue userActivity: NSUserActivity,
					 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
		guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			  let url = userActivity.webpageURL else { return false }
		logger.debug("Received universal link", metadata: ["url": "\(url.absoluteString)"])
		return true
	}
}
