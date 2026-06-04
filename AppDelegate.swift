//
//  AppDelegate.swift
//  PaceApp
//
//  Created by Wve Developer on 13/04/26.
//

import SwiftUI
import ConnectIQ
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("App launched with options: \(String(describing: launchOptions))")
		
		// Configure Firebase — MUST run before any Auth.auth() calls.
		FirebaseApp.configure()
		
		// Register the global auth-state listener now that Firebase is ready.
		AuthManager.shared.configure()

        // Firebase Phone Auth requires APNs to perform a silent device verification
        // before sending the SMS OTP. Register here so the token is available early.
        UIApplication.shared.registerForRemoteNotifications()
        
		return true
    }

    // MARK: - APNs — Required for Firebase Phone Number Auth

    /// Passes the APNs device token to Firebase Auth so it can send
    /// silent push notifications during phone number verification.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }

    /// Informs Firebase Auth that APNs registration failed.
    /// Phone auth will fall back to reCAPTCHA verification when this happens.
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    /// Forwards silent remote notifications to Firebase Auth.
    /// Firebase uses these to verify that the device can receive push notifications
    /// before issuing an SMS OTP, preventing abuse.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        // Not a Firebase notification — handle other cases here if needed.
        completionHandler(.noData)
    }
}

