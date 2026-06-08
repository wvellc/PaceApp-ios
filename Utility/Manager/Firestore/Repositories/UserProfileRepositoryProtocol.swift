//
//  UserProfileRepositoryProtocol.swift
//  PaceApp
//

import Foundation

protocol UserProfileRepositoryProtocol: AnyObject {
	func fetchProfile(userId: String) async throws -> UserModel
	func upsertProfile(_ model: UserModel, userId: String) async throws
}

enum UserProfileRepository {
	static let shared: UserProfileRepositoryProtocol = FirestoreUserProfileRepository.shared
}
