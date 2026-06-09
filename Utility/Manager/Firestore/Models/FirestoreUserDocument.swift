//
//  FirestoreUserDocument.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore User Document

struct FirestoreUserDocument: Codable {
    var uuid: String
    var firstName: String
    var lastName: String
    var gender: String
    var email: String
    var phoneNumber: String
    var lastSyncedAt: Timestamp?

    // MARK: - Settings
    /// Gait data for walking and running stored as a nested map.
    var gait: FirestoreGaitDocument?
    /// Whether interval haptic vibration is enabled. Defaults to false.
    var intervalVibrate: Bool?
    /// Whether interval audio beep is enabled. Defaults to false.
    var intervalBeep: Bool?
    /// Preferred distance unit raw value (e.g. "Kms" or "Miles"). Defaults to "Miles".
    var distanceUnit: String?
}

// MARK: - Firestore Gait Document

struct FirestoreGaitDocument: Codable {
    var walkingStepLength: Double
    var walkingUnit: String
    var runningStepLength: Double
    var runningUnit: String
}
