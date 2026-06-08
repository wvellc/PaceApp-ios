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

	func fetchProfile(userId: String) async throws -> UserModel {
		let snap = try await db.collection("users").document(userId).getDocument()
		guard snap.exists, let data = snap.data() else {
			throw NSError(domain: "UserProfileRepository", code: 404,
						  userInfo: [NSLocalizedDescriptionKey: "User profile not found."])
		}
		if let document = try? snap.data(as: FirestoreUserDocument.self) {
			return UserProfileMapper.userModel(from: document, userId: userId)
		}
		var model = UserModel(uuid: userId)
		if let v = data["firstName"] as? String { model.firstName = v.nilIfEmpty }
		if let v = data["lastName"] as? String { model.lastName = v.nilIfEmpty }
		if let v = data["gender"] as? String, let g = Gender(rawValue: v) { model.gender = g }
		if let v = data["email"] as? String { model.email = v.nilIfEmpty }
		if let v = data["phoneNumber"] as? String { model.phoneNumber = v.nilIfEmpty }
		return model
	}

	func upsertProfile(_ model: UserModel, userId: String) async throws {
		var document = UserProfileMapper.document(from: model, userId: userId)
		document.lastSyncedAt = Timestamp(date: Date())
		try db.collection("users").document(userId).setData(from: document, merge: true)
	}
}
