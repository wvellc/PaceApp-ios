//
//  HistoryViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/10/26.
//

import SwiftUI

// MARK: - History ViewModel
@Observable
final class HistoryViewModel {
	
	// MARK: Search
	var searchText: String = ""
	
	var hasFilteredContent: Bool {
		isFilterActive || activities.contains(where: {
			$0.title.lowercased().contains(searchText.lowercased())
		})
	}
	
	// MARK: - Filter State
	
	/// Distance range (in miles). Absolute bounds: 0 – 150.
	var filterDistanceMin: Double = 10
	var filterDistanceMax: Double = 150
	
	/// Optional date selected by the user.
	var filterDate: Date?
	
	/// Optional city / location string.
	var filterLocation: String = ""
	
	/// Whether the filter is currently active (any value differs from defaults).
	var isFilterActive: Bool = false
	
	// MARK: - Activities Data
	
	var activities: [ActivityData] = []
	var isLoading: Bool = false
	
	private let eventRepository: EventRepositoryProtocol
	private var completedEventsListener: ListenerRegistrationToken?
	
	init(eventRepository: EventRepositoryProtocol = FirestoreEventRepository.shared) {
		self.eventRepository = eventRepository
	}
	
	deinit {
		completedEventsListener?.remove()
	}
	
	func startObservingEvents(userId: String) {
		completedEventsListener?.remove()
		isLoading = true
		completedEventsListener = eventRepository.observeCompletedEvents(userId: userId) { [weak self] events in
			self?.activities = events
			self?.isLoading = false
		}
	}
	
	func stopObservingEvents() {
		completedEventsListener?.remove()
		completedEventsListener = nil
	}
	
	// MARK: - Computed: Filtered Activities
	
	var filteredActivities: [ActivityData] {
		var result = activities
		
		// 1. Search text filter
		let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
		if !query.isEmpty {
			result = result.filter {
				$0.title.lowercased().contains(query) ||
				$0.displayDate.lowercased().contains(query) ||
				$0.location.lowercased().contains(query)
			}
		}
		
		// 2. Distance filter (only when filter is active)
		if isFilterActive {
			result = result.filter { activity in
				// Parse miles value from strings like "5.00 mi"
				let milesValue = activity.distance
					.replacingOccurrences(of: " mi", with: "")
					.replacingOccurrences(of: " km", with: "")
					.trimmingCharacters(in: .whitespaces)
				if let miles = Double(milesValue) {
					return miles >= filterDistanceMin && miles <= filterDistanceMax
				}
				return true
			}
			
			// 3. Date filter
			if let filterDate {
				let calendar = Calendar.current
				result = result.filter { activity in
					calendar.isDate(activity.date, inSameDayAs: filterDate)
				}
			}
			
			// 4. Location filter
			let locationQuery = filterLocation.trimmingCharacters(in: .whitespaces).lowercased()
			if !locationQuery.isEmpty {
				result = result.filter {
					$0.location.lowercased().contains(locationQuery)
				}
			}
		}
		
		return result
	}
	
	
	
	// MARK: - Filter Actions
	
	/// Commits the current filter state and closes the sheet.
	func applyFilter() {
		isFilterActive = true
	}
	
	/// Resets all filter values to their defaults.
	func clearFilter() {
		filterDistanceMin = 10
		filterDistanceMax = 150
		filterDate        = nil
		filterLocation    = ""
		isFilterActive    = false
	}
	
	
	// Handle the swipe-to-delete action
	func delete(event: ActivityData) {
		if let index = activities.firstIndex(where: { $0.id == event.id }) {
			activities.remove(at: index)
		}
	}
	
}
