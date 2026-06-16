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
		let snapshot = try await db.collection("favorites")
			.whereField("userId", isEqualTo: userId)
			.whereField("eventId", isEqualTo: eventId)
			.limit(to: 1)
			.getDocuments()
		
		return !snapshot.documents.isEmpty
	}
	
	func toggleFavorite(userId: String, eventId: String) async throws -> Bool {
		// Check if already favorited
		let query = db.collection("favorites")
			.whereField("userId", isEqualTo: userId)
			.whereField("eventId", isEqualTo: eventId)
			.limit(to: 1)
		
		let snapshot = try await query.getDocuments()
		
		if let existingDoc = snapshot.documents.first {
			// Delete
			try await existingDoc.reference.delete()
			return false
		} else {
			// Create new favorite
			let document = FirestoreFavoriteDocument(
				userId: userId,
				eventId: eventId,
				createdAt: Timestamp(date: Date())
			)
			
			let newRef = db.collection("favorites").document() // Auto ID
			try newRef.setData(from: document)
			return true
		}
	}
	
	func fetchFavoriteEventIds(userId: String) async throws -> [String] {
		let snapshot = try await db.collection("favorites")
			.whereField("userId", isEqualTo: userId)
			.getDocuments()
		
		return snapshot.documents.compactMap { doc in
			(try? doc.data(as: FirestoreFavoriteDocument.self))?.eventId
		}
	}
}
