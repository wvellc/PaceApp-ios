//
//  FavoritesViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/5/26.
//

import Observation

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

	func loadFavorites(userId: String) async {
		isLoading = true
		defer { isLoading = false }
		do {
			let favoriteIds = try await favoritesRepository.fetchFavoriteEventIds(userId: userId)
			let completed = try await eventRepository.fetchCompletedEvents(userId: userId, limit: 100, cursor: nil)
			let active = try await eventRepository.fetchActiveEvents(userId: userId)
			let allEvents = active + completed
			favRuns = allEvents.filter { event in
				guard let syncId = event.syncId else { return false }
				return favoriteIds.contains(String(syncId))
			}
		} catch {
			favRuns = []
		}
	}

	func unFavorite(run: ActivityData, userId: String) async {
		guard let syncId = run.syncId else {
			favRuns.removeAll { $0.id == run.id }
			return
		}
		_ = try? await favoritesRepository.toggleFavorite(userId: userId, eventId: String(syncId))
		favRuns.removeAll { $0.id == run.id }
	}
}
