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
    private let logger = Logger(label: "net.paceapp.firestore.profile")

    private init() {}

    // MARK: - Fetch

    func fetchProfile(userId: String) async throws -> UserModel {
        let snap = try await db.collection("users").document(userId).getDocument()
        guard snap.exists, let data = snap.data() else {
            throw NSError(domain: "UserProfileRepository", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "User profile not found."])
        }
        if let document = try? snap.data(as: FirestoreUserDocument.self) {
            return UserProfileMapper.userModel(from: document, userId: userId)
        }
        // Legacy fallback — documents without the typed fields
        var model = UserModel(uuid: userId)
        if let v = data["firstName"] as? String { model.firstName = v.nilIfEmpty }
        if let v = data["lastName"]  as? String { model.lastName  = v.nilIfEmpty }
        if let v = data["gender"]    as? String, let g = Gender(rawValue: v) { model.gender = g }
        if let v = data["email"]     as? String { model.email     = v.nilIfEmpty }
        if let v = data["phoneNumber"] as? String { model.phoneNumber = v.nilIfEmpty }
        return model
    }

    // MARK: - Full Upsert

    func upsertProfile(_ model: UserModel, userId: String) async throws {
        var document = UserProfileMapper.document(from: model, userId: userId)
        document.lastSyncedAt = Timestamp(date: Date())
        try db.collection("users").document(userId).setData(from: document, merge: true)
    }

    // MARK: - Granular Settings Updates

    /// Writes the gait map as a single merge-safe update.
    func updateGait(_ gait: GaitUserData, userId: String) async throws {
        let doc = UserProfileMapper.gaitDocument(from: gait)
        let gaitMap: [String: Any] = [
            "walkingStepLength": doc.walkingStepLength,
            "walkingUnit": doc.walkingUnit,
            "runningStepLength": doc.runningStepLength,
            "runningUnit": doc.runningUnit
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
            ["distanceUnit": unit.rawValue],
            merge: true
        )
    }
}
