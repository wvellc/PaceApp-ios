//
//  ActivityData.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import SwiftUI

// MARK: - ActivityData
//
// UI-layer model for a run/walk event — active or completed.
// Built by EventDocumentMapper from an EventDocument (Firestore source)
// or directly from a ConnectIQ watch payload via ConnectIQManager.
// Contains pre-formatted display strings and SwiftUI types (Color),
// so it intentionally stays separate from the Codable EventDocument.

struct ActivityData: Identifiable, Hashable {

	// MARK: - Identity
	let id: Int
	let syncId: Int?
	var title: String
	let date: Date
	let distance: String        // e.g. "5.00 mi" or "10.00 km" — pre-formatted for display
	let duration: String        // goal time for active events; actual time for completed (HH:MM:SS)
	let avgPace: String?
	let delta: String?          // time delta display string e.g. "+01:10" or "-00:30"
	let deltaColor: Color       // .fluorescentMint (negative/ahead) or .redBoho (positive/behind)
	var location: String
	let gaitType: GaitType?

	// MARK: - Extended Event Fields
	let goal: String            // planned goal time as "HH:MM:SS"
	let measure: String         // "Miles" or "Kilometers"
	let intervals: String       // look-back interval count as string
	let segmentCount: Int       // number of planned segments

	// Typed planned segments — sourced from EventDocument.segments via the mapper.
	// Empty for events created before typed segment storage was introduced.
	let segments: [RunSegment]

	// Raw dicts retained for completed-segment and pace data whose shape
	// varies across watch firmware versions and is not yet typed.
	let completedSegments: [[String: Any]]  // watch actuals: { eta, distance, elapsed_time, completed_distance }
	let paces: [Int]                        // per-interval pace, seconds each (e.g. [256, 256, 265])

	// MARK: - Completion Fields (populated after watch sync)
	let actualDist: String      // actual distance covered e.g. "4.98"
	let timeVar: String         // time variance string e.g. "+01:10" or "-00:30"
	let avgHeartRate: Int       // average heart rate in BPM; 0 when unavailable

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
		segments: [RunSegment] = [],
		completedSegments: [[String: Any]] = [],
		actualDist: String = "",
		timeVar: String = "",
		avgHeartRate: Int = 0,
		paces: [Int] = []
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

	// MARK: - Display Helpers

	var displayDate: String {
		Self.displayDateFormatter.string(from: date)
	}

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

	// Cached — DateFormatter is expensive to allocate.
	static let displayDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "dd MMM"
		formatter.locale = Locale(identifier: "en_US_POSIX")
		return formatter
	}()

	static func makeDate(day: Int, month: Int, year: Int = Calendar.current.component(.year, from: Date())) -> Date {
		let calendar = Calendar(identifier: .gregorian)
		let components = DateComponents(year: year, month: month, day: day)
		guard let date = calendar.date(from: components) else {
			fatalError("Invalid ActivityData sample date.")
		}
		return date
	}
}
