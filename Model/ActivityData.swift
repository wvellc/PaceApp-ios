//
//  RecentActivity.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import SwiftUI

// MARK: - Recent Activity Model
struct ActivityData: Identifiable, Hashable {
    let id = UUID()
    var title: String
    let date: Date
    let distance: String
    let duration: String
    let avgPace: String
    let delta: String
	let deltaColor: Color
	var location: String
	let gaitType : GaitType?
	
	init(
		title: String,
		date: Date,
		distance: String,
		duration: String,
		avgPace: String,
		delta: String,
		deltaColor: Color,
		location: String,
		gaitType: GaitType = .running
	) {
		self.title = title
		self.date = date
		self.distance = distance
		self.duration = duration
		self.avgPace = avgPace
		self.delta = delta
		self.deltaColor = deltaColor
		self.location = location
		self.gaitType = gaitType
	}

	init?(connectIQPayload payload: [String: Any]) {
		guard
			let title = payload["name"] as? String,
			let dateText = payload["date"] as? String
		else {
			return nil
		}

		let measure = (payload["measure"] as? String) ?? "Miles"
		let unit = measure == "Miles" ? "mi" : "km"
		let distanceText: String
		if let distance = payload["distance"] as? String {
			distanceText = "\(distance) \(unit)"
		} else if let distance = payload["distance"] as? NSNumber {
			distanceText = String(format: "%.2f %@", distance.floatValue, unit)
		} else {
			distanceText = "0.00 \(unit)"
		}

		self.init(
			title: title,
			date: Self.parseConnectIQDate(dateText) ?? Date(),
			distance: distanceText,
			duration: (payload["goal"] as? String) ?? "00:00:00",
			avgPace: "",
			delta: "",
			deltaColor: .fluorescentMint,
			location: (payload["location"] as? String) ?? "",
			gaitType: Self.gaitType(from: payload["activity"] as? String)
		)
	}

	var displayDate: String {
		Self.displayDateFormatter.string(from: date)
	}
	
    // MARK: Sample Data
    // Sample content used by the dashboard preview state.
    static let samples: [ActivityData] = [
        ActivityData(
            title: "Thursday Run",
            date: Self.makeDate(day: 29, month: 1),
            distance: "5.00 mi",
            duration: "05:35:00",
            avgPace: "9:00 /mi",
            delta: "+01:10",
			deltaColor: .redBoho,
			location: "New York City",
			gaitType: .walking
        ),
        ActivityData(
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

private extension ActivityData {
	
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

	static func parseConnectIQDate(_ value: String) -> Date? {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		for format in ["MMM/d/yyyy", "MMM/dd/yyyy", "yyyy-MM-dd"] {
			formatter.dateFormat = format
			if let date = formatter.date(from: value) {
				return date
			}
		}
		return nil
	}

	static func gaitType(from activity: String?) -> GaitType {
		switch activity {
			case "Walk", "Walking":
				return .walking
			default:
				return .running
		}
	}
}
