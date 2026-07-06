//
//  UserProfileRepositoryProtocol.swift
//  PaceApp
//

import Foundation

protocol UserProfileRepositoryProtocol: AnyObject {
	// MARK: - Users info Updates
    func fetchProfile(userId: String) async throws -> UserModel
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
}

enum UserProfileRepository {
    static let shared: UserProfileRepositoryProtocol = FirestoreUserProfileRepository.shared
}
