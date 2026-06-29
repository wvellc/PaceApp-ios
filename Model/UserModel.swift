//
//  UserModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/15/26.
//

import Foundation

// MARK: - UserModel
//
// Single source of truth for user profile data — used in the app layer and
// decoded/encoded directly to/from Firestore via the Codable conformance below.
// CodingKeys mirrors the Firestore document field names exactly.

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

	/// Timestamp of last Garmin sync — written by the repository, ignored in the app layer.
	var lastSyncedAt: Date?

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

	// MARK: - Codable

	enum CodingKeys: String, CodingKey {
		case uuid, firstName, lastName, gender, email, phoneNumber
		case gait, intervalVibrate, intervalBeep, distanceUnit, lastSyncedAt
	}

	// Custom decode: empty strings stored in Firestore become nil, and raw
	// string values for Gender/MeasureUnit are mapped to their typed enums.
	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		uuid          = (try? c.decode(String.self, forKey: .uuid)) ?? ""
		firstName     = (try? c.decode(String.self, forKey: .firstName))?.nilIfEmpty
		lastName      = (try? c.decode(String.self, forKey: .lastName))?.nilIfEmpty
		email         = (try? c.decode(String.self, forKey: .email))?.nilIfEmpty
		phoneNumber   = (try? c.decode(String.self, forKey: .phoneNumber))?.nilIfEmpty
		lastSyncedAt  = try? c.decode(Date.self, forKey: .lastSyncedAt)
		intervalVibrate = try? c.decode(Bool.self, forKey: .intervalVibrate)
		intervalBeep    = try? c.decode(Bool.self, forKey: .intervalBeep)
		gait            = try? c.decode(GaitUserData.self, forKey: .gait)

		// Gender: raw string "Male"/"Female"/"Other"
		if let raw = (try? c.decode(String.self, forKey: .gender))?.nilIfEmpty {
			gender = Gender(rawValue: raw)
		}

		// distanceUnit: Firestore stores fullName ("Miles"/"Kilometers") or rawValue ("Miles"/"Kms")
		if let raw = (try? c.decode(String.self, forKey: .distanceUnit))?.nilIfEmpty {
			distanceUnit = MeasureUnit(rawValue: raw) ?? MeasureUnit(fullName: raw) ?? .miles
		} else {
			distanceUnit = .miles
		}
	}

	// Custom encode: nil optionals are written as empty strings to match the
	// existing Firestore document shape; lastSyncedAt is always refreshed by the repository.
	func encode(to encoder: Encoder) throws {
		var c = encoder.container(keyedBy: CodingKeys.self)
		try c.encode(uuid,                       forKey: .uuid)
		try c.encode(firstName ?? "",            forKey: .firstName)
		try c.encode(lastName ?? "",             forKey: .lastName)
		try c.encode(gender?.rawValue ?? "",     forKey: .gender)
		try c.encode(email ?? "",                forKey: .email)
		try c.encode(phoneNumber ?? "",          forKey: .phoneNumber)
		try c.encodeIfPresent(gait,              forKey: .gait)
		try c.encodeIfPresent(intervalVibrate,   forKey: .intervalVibrate)
		try c.encodeIfPresent(intervalBeep,      forKey: .intervalBeep)
		// Write distanceUnit as fullName ("Miles"/"Kilometers") to preserve the existing Firestore shape.
		try c.encodeIfPresent(distanceUnit?.fullName, forKey: .distanceUnit)
		// lastSyncedAt is managed exclusively by the repository — never re-encoded from the model.
	}
}

// MARK: - Memberwise Init
// Kept separate so callers constructing a UserModel in code don't need to
// worry about the Codable init above.
extension UserModel {
	init(uuid: String) {
		self.uuid = uuid
	}
}
