//
//  RecentActivity.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import SwiftUI

// MARK: - Activity Data Model
//
// Represents an event (active or completed) synced between watch and phone.
// All fields map to the ConnectIQ event payload keys.

struct ActivityData: Identifiable, Hashable {
	
	// MARK: - Identity
	//
	// Uses the stable Firestore / ConnectIQ integer event ID so that SwiftUI
	// ForEach can diff snapshots correctly. A random UUID would cause every
	// list row to be destroyed and recreated on every snapshot delivery.
	let id: Int
	
	let syncId: Int?
	var title: String
	let date: Date
	let distance: String        // e.g. "5.00 mi" or "10.00 km"
	let duration: String        // goal time for active, actual time for completed (HH:MM:SS)
	let avgPace: String
	let delta: String           // time delta display string (e.g. "+01:10")
	let deltaColor: Color
	var location: String
	let gaitType: GaitType?
	
	// --- Extended fields from ConnectIQ payload ---
	let goal: String             // goal time as HH:MM:SS
	let measure: String          // "Miles" or "Kilometers"
	let intervals: String        // look-back intervals count
	let segmentCount: Int        // number of segments
	let segments: [[String: Any]]          // segment definitions [{distance, eta}, ...]
	let completedSegments: [[String: Any]] // completed segment data from watch
	let actualDist: String       // completed: actual distance covered
	let timeVar: String          // completed: time variance string
	let avgHeartRate: Int        // completed: average heart rate (0 if unavailable)
	let paces: [[String: Any]]             // completed: per-interval pace data
	
	// MARK: - Full Initializer
	
	init(
		id: Int = 0,
		syncId: Int? = nil,
		title: String,
		date: Date,
		distance: String,
		duration: String,
		avgPace: String,
		delta: String,
		deltaColor: Color,
		location: String,
		gaitType: GaitType = .running,
		goal: String = "00:00:00",
		measure: String = "Miles",
		intervals: String = "1",
		segmentCount: Int = 0,
		segments: [[String: Any]] = [],
		completedSegments: [[String: Any]] = [],
		actualDist: String = "",
		timeVar: String = "",
		avgHeartRate: Int = 0,
		paces: [[String: Any]] = []
	) {
		self.id = id
		self.syncId = syncId
		self.title = title
		self.date = date
		self.distance = distance
		self.duration = duration
		self.avgPace = avgPace
		self.delta = delta
		self.deltaColor = deltaColor
		self.location = location
		self.gaitType = gaitType
		self.goal = goal
		self.measure = measure
		self.intervals = intervals
		self.segmentCount = segmentCount
		self.segments = segments
		self.completedSegments = completedSegments
		self.actualDist = actualDist
		self.timeVar = timeVar
		self.avgHeartRate = avgHeartRate
		self.paces = paces
	}
	
	// MARK: - ConnectIQ Payload Initializer
	//
	// Parses a raw dictionary from the watch/sync into an ActivityData.
	// Maps all known keys including completed-event fields.
	
	init?(connectIQPayload payload: [String: Any]) {
		guard
			let title = payload["name"] as? String,
			let dateText = payload["date"] as? String
		else {
			return nil
		}
		
		// --- Distance formatting ---
		let measureStr = (payload["measure"] as? String) ?? "Miles"
		let unit = measureStr == "Miles" ? "mi" : "km"
		let distanceText: String
		if let distance = payload["distance"] as? String {
			distanceText = "\(distance) \(unit)"
		} else if let distance = payload["distance"] as? NSNumber {
			distanceText = String(format: "%.2f %@", distance.floatValue, unit)
		} else {
			distanceText = "0.00 \(unit)"
		}
		
		// --- Goal & actual time ---
		let goalStr = (payload["goal"] as? String) ?? "00:00:00"
		let actualTimeStr = (payload["actualTime"] as? String) ?? ""
		// Duration: use actualTime for completed events, goal for active
		let durationStr = actualTimeStr.isEmpty ? goalStr : actualTimeStr
		
		// --- Time variance / delta ---
		let timeVarStr = (payload["timeVar"] as? String) ?? ""
		let deltaColor: Color = timeVarStr.hasPrefix("-") ? .fluorescentMint : .redBoho
		
		// --- Actual distance (completed events) ---
		let actualDistStr: String
		if let ad = payload["actualDist"] as? String {
			actualDistStr = ad
		} else if let ad = payload["actualDist"] as? NSNumber {
			actualDistStr = String(format: "%.2f", ad.floatValue)
		} else {
			actualDistStr = ""
		}
		
		// --- Heart rate ---
		let heartRate: Int
		if let hr = payload["avgHeartRate"] as? Int {
			heartRate = hr
		} else if let hr = payload["avgHeartRate"] as? NSNumber {
			heartRate = hr.intValue
		} else {
			heartRate = 0
		}
		
		// --- Segments ---
		let segArray = Self.arrayOfDicts(from: payload["segments"])
		let completedSegArray = Self.arrayOfDicts(from: payload["completedSegments"])
		let segCount: Int
		if let sc = payload["segmentCount"] as? Int {
			segCount = sc
		} else if let sc = payload["segmentCount"] as? NSNumber {
			segCount = sc.intValue
		} else {
			segCount = segArray.count
		}
		
		// --- Stable ID from payload ---
		let stableId = Self.connectIQId(from: payload["id"]) ?? 0
		
		self.init(
			id: stableId,
			syncId: stableId == 0 ? nil : stableId,
			title: title,
			date: Self.parseConnectIQDate(dateText) ?? Date(),
			distance: distanceText,
			duration: durationStr,
			avgPace: "",
			delta: timeVarStr,
			deltaColor: deltaColor,
			location: (payload["location"] as? String) ?? "",
			gaitType: Self.gaitType(from: payload["activity"] as? String),
			goal: goalStr,
			measure: measureStr,
			intervals: (payload["intervals"] as? String) ?? "1",
			segmentCount: segCount,
			segments: segArray,
			completedSegments: completedSegArray,
			actualDist: actualDistStr,
			timeVar: timeVarStr,
			avgHeartRate: heartRate,
			paces: Self.arrayOfDicts(from: payload["paces"])
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

	// MARK: - Hashable
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	static func == (lhs: ActivityData, rhs: ActivityData) -> Bool {
		lhs.id == rhs.id
	}
}

// MARK: - Private Helpers

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
	
	// Shared formatter — DateFormatter is expensive to allocate, cache it.
	static let connectIQDateFormatter: DateFormatter = {
		let f = DateFormatter()
		f.locale = Locale(identifier: "en_US_POSIX")
		return f
	}()
	
	static func parseConnectIQDate(_ value: String) -> Date? {
		for format in ["MMM/d/yyyy", "MMM/dd/yyyy", "yyyy-MM-dd"] {
			connectIQDateFormatter.dateFormat = format
			if let date = connectIQDateFormatter.date(from: value) {
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
	
	static func connectIQId(from value: Any?) -> Int? {
		if let value = value as? Int { return value }
		if let value = value as? NSNumber { return value.intValue }
		if let value = value as? String { return Int(value) }
		return nil
	}
	
	/// Safely converts a value to an array of dictionaries.
	/// Handles NSArray from ConnectIQ which isn't directly castable to [[String: Any]].
	static func arrayOfDicts(from value: Any?) -> [[String: Any]] {
		if let arr = value as? [[String: Any]] { return arr }
		if let nsArr = value as? NSArray {
			return nsArr.compactMap { $0 as? [String: Any] }
		}
		return []
	}
}
