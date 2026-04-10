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
    var activities: [RecentActivity] = RecentActivity.historyTestData

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
}

// MARK: - Extended Test Data
extension RecentActivity {

    static let historyTestData: [RecentActivity] = [
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
            title: "Saturday Run",
            date: "31 Jan",
            distance: "15.00 mi",
            duration: "0:50",
            avgPace: "3:20 /mi",
            delta: "-02:15",
            deltaColor: .fluorescentMint,
            location: "Twin Falls"
        ),
        RecentActivity(
            title: "Saturday Run",
            date: "31 Jan",
            distance: "15.00 mi",
            duration: "0:50",
            avgPace: "3:20 /mi",
            delta: "-02:15",
            deltaColor: .fluorescentMint,
            location: "Central Park"
        ),
        RecentActivity(
            title: "Saturday Run",
            date: "31 Jan",
            distance: "15.00 mi",
            duration: "0:50",
            avgPace: "3:20 /mi",
            delta: "-02:15",
            deltaColor: .fluorescentMint,
            location: "Brooklyn"
        ),
        RecentActivity(
            title: "Saturday Run",
            date: "31 Jan",
            distance: "15.00 mi",
            duration: "0:50",
            avgPace: "3:20 /mi",
            delta: "-02:15",
            deltaColor: .fluorescentMint,
            location: "Queens"
        ),
        RecentActivity(
            title: "Monday Run",
            date: "02 Feb",
            distance: "8.50 mi",
            duration: "1:12",
            avgPace: "8:28 /mi",
            delta: "-00:45",
            deltaColor: .fluorescentMint,
            location: "Chicago"
        ),
        RecentActivity(
            title: "Wednesday Run",
            date: "04 Feb",
            distance: "3.10 mi",
            duration: "0:28",
            avgPace: "9:02 /mi",
            delta: "+00:30",
            deltaColor: .redBoho,
            location: "Los Angeles"
        ),
        RecentActivity(
            title: "Friday Run",
            date: "06 Feb",
            distance: "10.00 mi",
            duration: "1:30",
            avgPace: "9:00 /mi",
            delta: "-01:05",
            deltaColor: .fluorescentMint,
            location: "San Francisco"
        )
    ]
}