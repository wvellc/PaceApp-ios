//
//  FavoritesViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/5/26.
//

import Observation
import Logging
import Foundation

@Observable
final class FavoritesViewModel {
	
	var favRuns: [ActivityData] = []
	var isLoading: Bool = false
	
	private let favoritesRepository: FavoritesRepositoryProtocol
	private let eventRepository: EventRepositoryProtocol
	
	init(
		favoritesRepository: FavoritesRepositoryProtocol = FirestoreFavoritesRepository.shared,
		eventRepository: EventRepositoryProtocol = FirestoreEventRepository.shared
	) {
		self.favoritesRepository = favoritesRepository
		self.eventRepository = eventRepository
	}
	
	// MARK: - Load
	func loadFavorites(userId: String) async {
		isLoading = true
		defer { isLoading = false }
		
		do {
			let favoriteIds = try await favoritesRepository.fetchFavoriteEventIds(userId: userId)
			// Fetch ONLY favorites — much more efficient, no full history scan
			favRuns = try await eventRepository.fetchEvents(byIds: favoriteIds)
			// Optional: sort by completedAt or scheduledAt for consistent UI
//			favRuns.sort { ($0.completedAt ?? $0.scheduledAt) > ($1.completedAt ?? $1.scheduledAt) }
		} catch {
			logger.error("Failed to load favorites: \(error.localizedDescription)") // if logger injected
			favRuns = []
		}
	}
	
	// MARK: - Actions
	func unFavorite(run: ActivityData, userId: String) async {
		guard let syncId = run.syncId else {
			favRuns.removeAll { $0.id == run.id }
			return
		}
		_ = try? await favoritesRepository.toggleFavorite(userId: userId, eventId: String(syncId))
		favRuns.removeAll { $0.id == run.id }
	}
}
