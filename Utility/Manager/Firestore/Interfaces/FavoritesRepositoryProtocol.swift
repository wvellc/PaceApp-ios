//
//  FavoritesRepositoryProtocol.swift
//  PaceApp
//

import Foundation

protocol FavoritesRepositoryProtocol: AnyObject {
	func isFavorited(userId: String, eventId: String) async throws -> Bool
	func toggleFavorite(userId: String, eventId: String) async throws -> Bool
	func fetchFavoriteEventIds(userId: String) async throws -> [String]
}

enum FavoritesRepository {
	static let shared: FavoritesRepositoryProtocol = FirestoreFavoritesRepository.shared
}
