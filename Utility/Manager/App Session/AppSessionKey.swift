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
    case isUserCanViewMetricsPopUp

    // Primary UUID of the last successfully paired Garmin watch.
    // Used as a quick "has the user ever paired?" check on cold launch.
    case pairedWatchUUID

    // Full identity snapshot of all known IQDevices (UUID + model + friendly name).
    // Used by ConnectIQManager.restoreSessionIfNeeded() to reconstruct IQDevice
    // objects and re-register for device events after a cold launch, so
    // deviceStatusChanged fires without requiring Garmin Connect to be reopened.
    case pairedDevices

    // Timestamp of the last successful watch → phone sync.
    // Persisted so the greeting line survives app restarts.
    case lastWatchSyncDate

    // Watch event ids whose Firestore write was permission-denied (doc owned by a
    // previous account). Skipped on later syncs so the denial isn't retried forever.
    case foreignEventIds

    // Phone event changes (create/edit/delete) the watch hasn't confirmed yet.
    // Cleared with the rest of the session on sign-out.
    case watchOutbox
}
