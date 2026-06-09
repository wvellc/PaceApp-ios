
//
//  UserModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/15/26.
//

import Foundation

// MARK: - UserModel

/// Persisted user profile data stored in Firestore and cached in AuthManager.
struct UserModel: Codable, Equatable {

    // MARK: - Core Identity

    /// Unique app-level UUID assigned on first OTP verification.
    var uuid: String

    // MARK: - Profile Info

    /// User's first name — nil until CreateAccount profile step is completed.
    var firstName: String?

    /// User's last name — nil until CreateAccount profile step is completed.
    var lastName: String?

    /// User's gender — optional even after profile completion.
    var gender: Gender?

    /// Email address used to authenticate, when logging in with email.
    var email: String?

    /// Phone number used to authenticate, including the country dialing code.
    var phoneNumber: String?

    // MARK: - Settings (Firestore-backed)

    /// Gait step-length data for walking and running. Stored under `gait` map in Firestore.
    var gait: GaitUserData?

    /// Whether interval haptic vibration is enabled. Firestore key: `intervalVibrate`. Default: false.
    var intervalVibrate: Bool?

    /// Whether interval audio beep is enabled. Firestore key: `intervalBeep`. Default: false.
    var intervalBeep: Bool?

    /// Preferred distance unit. Firestore key: `distanceUnit`. Default: .miles.
    var distanceUnit: MeasureUnit?

    // MARK: - Computed Helpers

    var contactInfo: String? {
        if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines),
           !email.isEmpty {
            return email
        }

        if let phoneNumber = phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
           !phoneNumber.isEmpty {
            return phoneNumber
        }

        return nil
    }

    /// `true` when both first and last name have been filled in.
    var isProfileCompleted: Bool {
        guard let first = firstName, let last = lastName else { return false }
        return !first.trimmingCharacters(in: .whitespaces).isEmpty
            && !last.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
