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
	
	final var activities: [ActivityData] = [
		ActivityData(
			title: "Thursday Run",
			date: makeDate(day: 29, month: 1),
			distance: "5.00 mi",
			duration: "0:45",
			avgPace: "9:00 /mi",
			delta: "+01:10",
			deltaColor: .redBoho,
			location: "New York City"
		),
		ActivityData(
			title: "Saturday Long Run",
			date: makeDate(day: 31, month: 1),
			distance: "12.00 mi",
			duration: "1:48",
			avgPace: "9:00 /mi",
			delta: "-00:15",
			deltaColor: .fluorescentMint,
			location: "Central Park"
		),
		ActivityData(
			title: "Monday Recovery",
			date: makeDate(day: 2, month: 2),
			distance: "3.50 mi",
			duration: "0:33",
			avgPace: "9:30 /mi",
			delta: "+00:45",
			deltaColor: .redBoho,
			location: "Brooklyn"
		),
		ActivityData(
			title: "Wednesday Tempo",
			date: makeDate(day: 4, month: 2),
			distance: "6.20 mi",
			duration: "0:49",
			avgPace: "7:55 /mi",
			delta: "-01:20",
			deltaColor: .fluorescentMint,
			location: "Queens"
		),
		ActivityData(
			title: "Friday Easy Run",
			date: makeDate(day: 6, month: 2),
			distance: "4.00 mi",
			duration: "0:35",
			avgPace: "8:45 /mi",
			delta: "-00:10",
			deltaColor: .fluorescentMint,
			location: "Hoboken"
		),
		ActivityData(
			title: "Sunday Long Run",
			date: makeDate(day: 8, month: 2),
			distance: "15.00 mi",
			duration: "2:10",
			avgPace: "8:40 /mi",
			delta: "-02:15",
			deltaColor: .fluorescentMint,
			location: "Twin Falls"
		),
		ActivityData(
			title: "Tuesday Intervals",
			date: makeDate(day: 10, month: 2),
			distance: "5.50 mi",
			duration: "0:42",
			avgPace: "7:38 /mi",
			delta: "-00:30",
			deltaColor: .fluorescentMint,
			location: "Chicago"
		),
		ActivityData(
			title: "Thursday Run",
			date: makeDate(day: 12, month: 2),
			distance: "8.00 mi",
			duration: "1:12",
			avgPace: "9:00 /mi",
			delta: "+00:25",
			deltaColor: .redBoho,
			location: "San Francisco"
		)
	]
	
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
