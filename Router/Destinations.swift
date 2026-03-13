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
	case createAccount
	
    // MARK: - Home
	case home
	
    // MARK: - Profile
    case profile

    // MARK: - Settings
	case settings

}
