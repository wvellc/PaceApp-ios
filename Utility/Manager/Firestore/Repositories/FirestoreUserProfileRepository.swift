//
//  FirestoreUserProfileRepository.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore
import Logging

final class FirestoreUserProfileRepository: UserProfileRepositoryProtocol {

	static let shared = FirestoreUserProfileRepository()

	private let db = Firestore.firestore()
	private let logger = Logger(label: "firestore.profile")

	private init() {}

	// MARK: - Fetch

	func fetchProfile(userId: String) async throws -> UserModel {
		let snap = try await db.collection("users").document(userId).getDocument()
		guard snap.exists, let _ = snap.data() else {
			throw NSError(domain: "UserProfileRepository", code: 404,
						  userInfo: [NSLocalizedDescriptionKey: "User profile not found."])
		}
		return decodeProfile(snap, userId: userId)
	}

	// MARK: - Live Updates

	func listenToProfile(userId: String, onChange: @escaping (UserModel?) -> Void) -> ListenerRegistrationToken {
		let registration = db.collection("users").document(userId)
			.addSnapshotListener { [weak self] snapshot, error in
				guard let self else { return }
				if let error {
					self.logger.error("Profile listener failed: \(error.localizedDescription)")
					return
				}
				guard let snapshot, snapshot.exists, snapshot.data() != nil else {
					onChange(nil)
					return
				}
				onChange(self.decodeProfile(snapshot, userId: userId))
			}
		return ListenerRegistrationToken { registration.remove() }
	}

	// MARK: - Decoding

	/// Decodes a user document into `UserModel`, falling back to a manual map for
	/// legacy documents written before the typed Codable shape existed.
	private func decodeProfile(_ snap: DocumentSnapshot, userId: String) -> UserModel {
		// Decode UserModel directly — Firestore Timestamp fields are auto-converted to Date.
		if var model = try? snap.data(as: UserModel.self) {
			model.uuid = userId  // ensure uuid is always the authoritative Firebase Auth UID
			return model
		}
		// Legacy fallback — documents written before the typed Codable shape existed.
		let data = snap.data() ?? [:]
		var model = UserModel(uuid: userId)
		if let v = data["firstName"] as? String  { model.firstName  = v.nilIfEmpty }
		if let v = data["lastName"]  as? String  { model.lastName   = v.nilIfEmpty }
		if let v = data["gender"]    as? String,
		   let g = Gender(rawValue: v)           { model.gender     = g }
		if let v = data["email"]     as? String  { model.email      = v.nilIfEmpty }
		if let v = data["phoneNumber"] as? String { model.phoneNumber = v.nilIfEmpty }
		return model
	}

	// MARK: - Full Upsert

	func upsertProfile(_ model: UserModel, userId: String) async throws {
		// Inject the authoritative userId and a fresh sync timestamp before writing.
		var payload = model
		payload.uuid = userId
		payload.lastSyncedAt = Date()
		try db.collection("users").document(userId).setData(from: payload, merge: true)
	}

	// MARK: - Granular Settings Updates

	/// Writes the gait map as a single merge-safe update.
	func updateGait(_ gait: GaitUserData, userId: String) async throws {
		// Build the flat gait map directly from GaitUserData fields — no mapper needed.
		let gaitMap: [String: Any] = [
			"walkingStepLength": gait.walkingData.stepLength,
			"walkingUnit":       gait.walkingData.unit,
			"runningStepLength": gait.runningData.stepLength,
			"runningUnit":       gait.runningData.unit
		]
		try await db.collection("users").document(userId).setData(
			["gait": gaitMap],
			merge: true
		)
	}

	/// Writes `intervalVibrate` as a single merge-safe update.
	func updateIntervalVibrate(_ enabled: Bool, userId: String) async throws {
		try await db.collection("users").document(userId).setData(
			["intervalVibrate": enabled],
			merge: true
		)
	}

	/// Writes `intervalBeep` as a single merge-safe update.
	func updateIntervalBeep(_ enabled: Bool, userId: String) async throws {
		try await db.collection("users").document(userId).setData(
			["intervalBeep": enabled],
			merge: true
		)
	}

	/// Writes `distanceUnit` as a single merge-safe update.
	func updateDistanceUnit(_ unit: MeasureUnit, userId: String) async throws {
		try await db.collection("users").document(userId).setData(
			["distanceUnit": unit.fullName],
			merge: true
		)
	}
}
