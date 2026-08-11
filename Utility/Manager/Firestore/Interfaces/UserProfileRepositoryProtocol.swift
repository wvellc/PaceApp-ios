//
//  UserProfileRepositoryProtocol.swift
//  PaceApp
//

import Foundation

/// Server-only profile lookup result — never read from cache, so a fresh-device cache miss
/// can't be mistaken for a missing account (which would wrongly seed/overwrite the profile).
enum ServerProfileResult {
    case found(UserModel)
    case missing      // server confirms the document does not exist
    case unreachable  // couldn't reach the server (offline / transient)
}

protocol UserProfileRepositoryProtocol: AnyObject {
	// MARK: - Users info Updates
    func fetchProfile(userId: String) async throws -> UserModel
    /// Forces a server read so "missing" is authoritative — used before creating a new profile.
    func fetchProfileFromServer(userId: String) async -> ServerProfileResult
    func upsertProfile(_ model: UserModel, userId: String) async throws

    // MARK: - Live Updates
    /// Real-time listener on the user document. Fires on every change — including
    /// settings the watch writes to Firestore — so the app reflects them live.
    func listenToProfile(userId: String, onChange: @escaping (UserModel?) -> Void) -> ListenerRegistrationToken

    // MARK: - Granular Settings Updates
    func updateGait(_ gait: GaitUserData, userId: String) async throws
    func updateIntervalVibrate(_ enabled: Bool, userId: String) async throws
    func updateIntervalBeep(_ enabled: Bool, userId: String) async throws
    func updateDistanceUnit(_ unit: MeasureUnit, userId: String) async throws
    /// Merges body metrics synced from the watch. Writes only the values present.
    func updateBodyMetrics(heightCm: Double?, weightKg: Double?, userId: String) async throws
}

enum UserProfileRepository {
    static let shared: UserProfileRepositoryProtocol = FirestoreUserProfileRepository.shared
}
