//
//  HistoryViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/10/26.
//

import SwiftUI
import Logging

// MARK: - History ViewModel

/// Drives the History tab with Firestore server-side filtering and
/// cursor-based pagination (page size 10).
@Observable
@MainActor
final class HistoryViewModel {
	
	// MARK: - Constants
	
	private static let pageSize = 10
	private static let defaultDistanceMin: Double = 0
	private static let defaultDistanceMax: Double = 150
	
	// MARK: - Pagination State
	
	/// Currently loaded events (accumulated across pages).
	var activities: [ActivityData] = []
	
	/// True during the initial page load.
	var isLoading: Bool = false
	
	/// True while a subsequent page is being fetched.
	var isLoadingMore: Bool = false
	
	/// False once a fetch returns fewer results than pageSize.
	var hasMorePages: Bool = true
	
	/// Opaque cursor from the last Firestore fetch (DocumentSnapshot).
	@ObservationIgnored
	private var lastCursor: Any? = nil
	
	/// User ID captured on first appear.
	@ObservationIgnored
	private var currentUserId: String?
	
	// MARK: - Search (client-side post-filter)
	
	/// Filters the already-loaded activities by title, date, or location substring.
	var searchText: String = ""
	
	// MARK: - Filter State (bound to FilterSheetView)
	
	/// Distance range slider values — modified live in the sheet.
	var filterDistanceMin: Double = 0
	var filterDistanceMax: Double = 150
	
	/// Optional date selected by the user.
	var filterDate: Date? = nil
	
	/// Optional city / location string.
	var filterLocation: String = ""
	
	// MARK: - Committed Filter Snapshot
	
	/// Committed values are set on "Show Results" and used for Firestore queries.
	/// The sheet-bound values above can be freely edited without triggering a query.
	@ObservationIgnored
	private var committedDistanceMin: Double = 0
	@ObservationIgnored
	private var committedDistanceMax: Double = 150
	@ObservationIgnored
	private var committedDate: Date? = nil
	@ObservationIgnored
	private var committedLocation: String = ""
	
	// MARK: - Dependencies
	
	private let eventRepository: EventRepositoryProtocol
	private let logger = Logger(label: "HistoryViewModel")
	
	init(eventRepository: EventRepositoryProtocol = FirestoreEventRepository.shared) {
		self.eventRepository = eventRepository
	}
	
	// MARK: - Computed: Filter Active
	
	/// True when any committed filter differs from its default value.
	/// Drives the filter icon swap (.icFilter vs .icFilterApplied).
	var isFilterActive: Bool {
		committedDistanceMin > Self.defaultDistanceMin ||
		committedDistanceMax < Self.defaultDistanceMax ||
		committedDate != nil ||
		!committedLocation.trimmingCharacters(in: .whitespaces).isEmpty
	}
	
	// MARK: - Computed: Filtered Activities (client-side search)
	
	/// Applies the search bar text on already-loaded events.
	var filteredActivities: [ActivityData] {
		let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
		guard !query.isEmpty else { return activities }
		return activities.filter {
			$0.title.lowercased().contains(query) ||
			$0.displayDate.lowercased().contains(query) ||
			$0.location.lowercased().contains(query)
		}
	}
	
	// MARK: - Data Loading
	
	/// Called once when the History tab first appears.
	func startLoading(userId: String) {
		guard currentUserId == nil else { return }
		currentUserId = userId
		loadFirstPage()
	}
	
	/// Resets pagination and fetches the first page with committed filters.
	func loadFirstPage() {
		guard let userId = currentUserId else { return }
		
		lastCursor = nil
		hasMorePages = true
		isLoading = true
		
		Task { @MainActor [weak self] in
			guard let self else { return }
			do {
				let result = try await self.eventRepository.fetchFilteredCompletedEvents(
					userId: userId,
					pageSize: Self.pageSize,
					cursor: nil,
					distanceMin: self.committedDistanceMin,
					distanceMax: self.committedDistanceMax,
					date: self.committedDate,
					location: self.committedLocation
				)
				self.activities = result.events
				self.lastCursor = result.nextCursor
				self.hasMorePages = result.events.count >= Self.pageSize
			} catch {
				self.logger.error("Failed to load first page: \(error.localizedDescription)")
			}
			self.isLoading = false
		}
	}
	
	/// Re-fetches page 1 from Firestore, awaitable — used by pull-to-refresh and by
	/// automatic re-sync when the watch reports a new completed event. Unlike
	/// `loadFirstPage`, this does not flip `isLoading` so it doesn't swap in the
	/// full-screen spinner over `.refreshable`'s own indicator.
	func refresh() async {
		guard let userId = currentUserId else { return }
		
		do {
			let result = try await eventRepository.fetchFilteredCompletedEvents(
				userId: userId,
				pageSize: Self.pageSize,
				cursor: nil,
				distanceMin: committedDistanceMin,
				distanceMax: committedDistanceMax,
				date: committedDate,
				location: committedLocation
			)
			activities = result.events
			lastCursor = result.nextCursor
			hasMorePages = result.events.count >= Self.pageSize
		} catch {
			logger.error("Failed to refresh history: \(error.localizedDescription)")
		}
	}
	
	/// Fetches the next page and appends results. Called when scrolling near bottom.
	func loadNextPage() {
		guard let userId = currentUserId,
			  hasMorePages,
			  !isLoadingMore,
			  !isLoading else { return }
		
		isLoadingMore = true
		
		Task { @MainActor [weak self] in
			guard let self else { return }
			do {
				let result = try await self.eventRepository.fetchFilteredCompletedEvents(
					userId: userId,
					pageSize: Self.pageSize,
					cursor: self.lastCursor,
					distanceMin: self.committedDistanceMin,
					distanceMax: self.committedDistanceMax,
					date: self.committedDate,
					location: self.committedLocation
				)
				self.activities.append(contentsOf: result.events)
				self.lastCursor = result.nextCursor
				self.hasMorePages = result.events.count >= Self.pageSize
			} catch {
				self.logger.error("Failed to load next page: \(error.localizedDescription)")
			}
			self.isLoadingMore = false
		}
	}
	
	// MARK: - Filter Actions
	
	/// Commits the current filter state and re-fetches from page 1.
	func applyFilter() {
		committedDistanceMin = filterDistanceMin
		committedDistanceMax = filterDistanceMax
		committedDate = filterDate
		committedLocation = filterLocation
		loadFirstPage()
	}
	
	/// Resets all filter values to defaults and re-fetches from page 1.
	func clearFilter() {
		// Reset sheet-bound values
		filterDistanceMin = Self.defaultDistanceMin
		filterDistanceMax = Self.defaultDistanceMax
		filterDate = nil
		filterLocation = ""
		
		// Reset committed values
		committedDistanceMin = Self.defaultDistanceMin
		committedDistanceMax = Self.defaultDistanceMax
		committedDate = nil
		committedLocation = ""
		
		loadFirstPage()
	}
	
	// MARK: - Delete
	
	/// Removes the event locally and soft-deletes it in Firestore.
	func delete(event: ActivityData) {
		guard let userId = currentUserId else { return }
		
		// Optimistic local removal
		if let index = activities.firstIndex(where: { $0.id == event.id }) {
			activities.remove(at: index)
		}
		
		// Firestore soft-delete
		Task {
			do {
				try await eventRepository.softDelete(eventId: event.id, userId: userId)
			} catch {
				logger.error("Failed to delete event \(event.id): \(error.localizedDescription)")
			}
		}
	}
}
