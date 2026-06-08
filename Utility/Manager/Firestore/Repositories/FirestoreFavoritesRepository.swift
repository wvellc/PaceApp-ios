//
//  FirestoreFavoritesRepository.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore

struct FirestoreFavoriteDocument: Codable {
	var userId: String
	var eventId: String
	var createdAt: Timestamp
}

final class FirestoreFavoritesRepository: FavoritesRepositoryProtocol {

	static let shared = FirestoreFavoritesRepository()

	private let db = Firestore.firestore()

	private init() {}

	func isFavorited(userId: String, eventId: String) async throws -> Bool {
		let snap = try await favoriteRef(userId: userId, eventId: eventId).getDocument()
		return snap.exists
	}

	func toggleFavorite(userId: String, eventId: String) async throws -> Bool {
		let ref = favoriteRef(userId: userId, eventId: eventId)
		let snap = try await ref.getDocument()
		if snap.exists {
			try await ref.delete()
			return false
		}
		let document = FirestoreFavoriteDocument(
			userId: userId,
			eventId: eventId,
			createdAt: Timestamp(date: Date())
		)
		try ref.setData(from: document)
		return true
	}

	func fetchFavoriteEventIds(userId: String) async throws -> [String] {
		let snapshot = try await db.collection("favorites")
			.whereField("userId", isEqualTo: userId)
			.getDocuments()
		return snapshot.documents.compactMap { doc in
			(try? doc.data(as: FirestoreFavoriteDocument.self))?.eventId
		}
	}

	private func favoriteRef(userId: String, eventId: String) -> DocumentReference {
		db.collection("favorites").document("\(userId)_\(eventId)")
	}
}
