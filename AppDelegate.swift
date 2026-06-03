//
//  AppDelegate.swift
//  PaceApp
//
//  Created by Wve Developer on 13/04/26.
//

import SwiftUI
import ConnectIQ
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("App launched with options: \(String(describing: launchOptions))")
		
		//Configure firebase
		FirebaseApp.configure()
        
		return true
    }
}
