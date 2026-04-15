//
//  RecentActivity.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import SwiftUI

// MARK: - Recent Activity Model
struct RecentActivity: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let distance: String
    let duration: String
    let avgPace: String
    let delta: String
	let deltaColor: Color
	let location: String

	var displayDate: String {
		Self.displayDateFormatter.string(from: date)
	}
	
    // MARK: Sample Data
    // Sample content used by the dashboard preview state.
    static let samples: [RecentActivity] = [
        RecentActivity(
            title: "Thursday Run",
            date: Self.makeDate(day: 29, month: 1),
            distance: "5.00 mi",
            duration: "05:35:00",
            avgPace: "9:00 /mi",
            delta: "+01:10",
			deltaColor: .redBoho,
			location: "New York City"
        ),
        RecentActivity(
            title: "Saturday Run",
            date: Self.makeDate(day: 31, month: 1),
            distance: "15.00 mi",
            duration: "12:35:03",
            avgPace: "3:20 /mi",
            delta: "-02:15",
			deltaColor: .fluorescentMint,
			location: "Twin Falls"
        )
    ]
}

private extension RecentActivity {
	
	static let displayDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "dd MMM"
		formatter.locale = Locale(identifier: "en_US_POSIX")
		return formatter
	}()

	static func makeDate(day: Int, month: Int, year: Int = 2026) -> Date {
		let calendar = Calendar(identifier: .gregorian)
		let components = DateComponents(year: year, month: month, day: day)
		guard let date = calendar.date(from: components) else {
			fatalError("Invalid RecentActivity sample date.")
		}
		return date
	}
}
