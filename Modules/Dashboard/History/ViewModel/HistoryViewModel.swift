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

    // MARK: Properties
    var searchText: String = ""
	var hasFilteredContent: Bool {
		activities.contains(where: { $0.title.lowercased().contains(searchText.lowercased()) })
	}
	
	final var activities: [RecentActivity] = [
		RecentActivity(
			title: "Thursday Run",
			date: "29 Jan",
			distance: "5.00 mi",
			duration: "0:45",
			avgPace: "9:00 /mi",
			delta: "+01:10",
			deltaColor: .redBoho,
			location: "New York City"
		),
		RecentActivity(
			title: "Saturday Long Run",
			date: "31 Jan",
			distance: "12.00 mi",
			duration: "1:48",
			avgPace: "9:00 /mi",
			delta: "-00:15",
			deltaColor: .fluorescentMint,
			location: "Central Park"
		),
		RecentActivity(
			title: "Monday Recovery",
			date: "02 Feb",
			distance: "3.50 mi",
			duration: "0:33",
			avgPace: "9:30 /mi",
			delta: "+00:45",
			deltaColor: .redBoho,
			location: "Brooklyn"
		),
		RecentActivity(
			title: "Wednesday Tempo",
			date: "04 Feb",
			distance: "6.20 mi",
			duration: "0:49",
			avgPace: "7:55 /mi",
			delta: "-01:20",
			deltaColor: .fluorescentMint,
			location: "Queens"
		),
		RecentActivity(
			title: "Friday Easy Run",
			date: "06 Feb",
			distance: "4.00 mi",
			duration: "0:35",
			avgPace: "8:45 /mi",
			delta: "-00:10",
			deltaColor: .fluorescentMint,
			location: "Hoboken"
		),
		RecentActivity(
			title: "Sunday Long Run",
			date: "08 Feb",
			distance: "15.00 mi",
			duration: "2:10",
			avgPace: "8:40 /mi",
			delta: "-02:15",
			deltaColor: .fluorescentMint,
			location: "Twin Falls"
		),
		RecentActivity(
			title: "Tuesday Intervals",
			date: "10 Feb",
			distance: "5.50 mi",
			duration: "0:42",
			avgPace: "7:38 /mi",
			delta: "-00:30",
			deltaColor: .fluorescentMint,
			location: "Chicago"
		),
		RecentActivity(
			title: "Thursday Run",
			date: "12 Feb",
			distance: "8.00 mi",
			duration: "1:12",
			avgPace: "9:00 /mi",
			delta: "+00:25",
			deltaColor: .redBoho,
			location: "San Francisco"
		)
	]

    // MARK: Computed
    var filteredActivities: [RecentActivity] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return activities
        }
        let query = searchText.lowercased()
        return activities.filter {
            $0.title.lowercased().contains(query) ||
            $0.date.lowercased().contains(query) ||
            $0.location.lowercased().contains(query)
        }
    }
	
	//MARK: Applied filter
	func applyFilter() {
		//TODO: Applie filter from filter sheet
	}
}
