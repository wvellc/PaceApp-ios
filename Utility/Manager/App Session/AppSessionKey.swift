//
//  AppSessionKey.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//


// MARK: - App Session Keys
// String raw value maps exactly to UserDefaults keys
// CaseIterable allows us to loop through them in removeAllData()
enum AppSessionKey: String, CaseIterable {
    case isUserAuthenticated
    case isUserProfileCompleted
    case userDetails
    case configDetails
    case userId
}
