//
//  AppSessionKey.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

// MARK: - App Session Keys
// String raw value maps exactly to UserDefaults keys.
// CaseIterable allows us to loop through them in removeAllData().
enum AppSessionKey: String, CaseIterable {
    case isUserAuthenticated
//    case isUserProfileCompleted
    case userDetails
    case isUserCanViewMetricsPopUp
    case userId
    case userGait
    case distanceUnit

    // Primary UUID of the last successfully paired Garmin watch.
    // Used as a quick "has the user ever paired?" check on cold launch.
    case pairedWatchUUID

    // Full identity snapshot of all known IQDevices (UUID + model + friendly name).
    // Used by ConnectIQManager.restoreSessionIfNeeded() to reconstruct IQDevice
    // objects and re-register for device events after a cold launch, so
    // deviceStatusChanged fires without requiring Garmin Connect to be reopened.
    case pairedDevices
}
