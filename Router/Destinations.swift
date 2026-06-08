//
//  Destinations.swift
//  pace
//  Created by FURKAN VIJAPURA on 3/12/26.
//  Routing destination types — Hashable & Codable for NavigationPath
//  compatibility and optional state restoration via SceneStorage.
//

/// All push-navigation destinations in the app.
enum Destinations: Hashable, Codable {

    // MARK: - Auth flow
    case login
	case verifyOTP(phoneNumber: String, verificationID: String)
	
	// MARK: - Account creation
	case accountCreated
	
    // MARK: - Home
	case createRunEvent
	case favoritesRun
	case notifications
	
    // MARK: - Settings
	case settings
	case termsOfService
	case privacyPolicy
	case licenses

	// MARK: - User settings
	case updateGait
	case manageWatch
}
