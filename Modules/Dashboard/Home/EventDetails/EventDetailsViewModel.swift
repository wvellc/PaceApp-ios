//
//  EventDetailsViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI
import CoreLocation
import MapKit

// MARK: - EventDetailsViewModel
//
// Drives the EventDetailsScreen with real data from ActivityData.
// For active events (upcoming), shows planned distance/goal/segments.
// For completed events (history), shows actual time, variance, heart rate, etc.

@Observable
final class EventDetailsViewModel {
	
	// MARK: Input
	var activityData: ActivityData?
	
	// MARK: Section Expansion
	var isAnalysisExpanded: Bool  = true
	var isIntervalsExpanded: Bool = false
	var isSegmentsExpanded: Bool  = false
	
	// MARK: Toggle States
	var isFavorite: Bool = false
	var showEditScreen: Bool?
	
	// MARK: Init
	init(activityData: ActivityData? = nil) {
		self.activityData = activityData
	}
	
	// MARK: - Computed: Whether this is a completed event
	
	/// True if the event has actual completion data (actualTime, actualDist, etc.)
	var isCompletedEvent: Bool {
		guard let data = activityData else { return false }
		return !data.actualDist.isEmpty || !data.timeVar.isEmpty
	}
	
	// MARK: - Computed: Time Delta
	
	// TODO: Sample hardcoded values for reference — uncomment when needed for testing
	// var timeDeltaSeconds: Int { -70 }
	// var completionPercent: Int { 97 }
	
	/// Parses the time variance string (e.g. "-01:10", "+00:30") into seconds.
	var timeDeltaSeconds: Int {
		guard let data = activityData else { return 0 }
		let raw = data.timeVar.trimmingCharacters(in: .whitespaces)
		guard !raw.isEmpty else { return 0 }
		return Self.parseTimeString(raw)
	}
	
	var timeDeltaIsNegative: Bool { timeDeltaSeconds < 0 }
	
	var timeDeltaFormatted: String {
		guard let data = activityData, !data.timeVar.isEmpty else { return "--:--" }
		// If the payload already has a formatted string, use it directly
		return data.timeVar
	}
	
	/// Completion percentage: (goal - variance) / goal * 100
	/// For active events with no actual data, shows 0%.
	var completionPercent: Int {
		guard isCompletedEvent else { return 0 }
		let goalSecs = Self.parseTimeString(activityData?.goal ?? "00:00:00")
		guard goalSecs > 0 else { return 0 }
		let actualSecs = abs(Self.parseTimeString(activityData?.duration ?? "00:00:00"))
		if actualSecs == 0 { return 0 }
		return min(100, max(0, Int(round(Double(min(goalSecs, actualSecs)) / Double(max(goalSecs, actualSecs)) * 100))))
	}
	
	var completionPercentText: String {
		isCompletedEvent ? "\(completionPercent)%" : "—"
	}
	
	// MARK: - Computed: Analysis
	
	// TODO: Sample hardcoded values for reference — uncomment when needed for testing
	// var eventDistance: String     { "1.00 mi" }
	// var completedDistance: String { "1.3 mi" }
	// var finishTimeGoal: String    { "00:06:00" }
	// var totalTimeTaken: String    { "00:03:51" }
	// var timeVariance: String      { "-00:02:09" }
	// var lookBackIntervals: String { "1" }
	// var segmentsCount: String     { "\(segments.count)" }
	// var averageHeartRate: String  { "157 bpm" }
	
	/// Event distance — the planned distance from the event setup
	var eventDistance: String {
		activityData?.distance ?? "—"
	}
	
	/// Completed distance — actual distance covered (only for completed events)
	var completedDistance: String {
		guard let data = activityData, !data.actualDist.isEmpty else { return "—" }
		let unit = data.measure == "Miles" ? "mi" : "km"
		// actualDist might already include unit, or just be a number
		if data.actualDist.contains("mi") || data.actualDist.contains("km") {
			return data.actualDist
		}
		return "\(data.actualDist) \(unit)"
	}
	
	/// Finish time goal — from the event setup
	var finishTimeGoal: String {
		activityData?.goal ?? "—"
	}
	
	/// Total time taken — actual time for completed, goal for active
	var totalTimeTaken: String {
		guard let data = activityData else { return "—" }
		if isCompletedEvent {
			return data.duration // duration = actualTime for completed events
		}
		return data.goal // For active, show goal as planned
	}
	
	/// Time variance — how much ahead/behind goal
	var timeVariance: String {
		guard let data = activityData, !data.timeVar.isEmpty else { return "—" }
		return data.timeVar
	}
	
	/// Look-back intervals count
	var lookBackIntervals: String {
		activityData?.intervals ?? "—"
	}
	
	/// Number of segments
	var segmentsCount: String {
		guard let data = activityData else { return "0" }
		return "\(data.segmentCount)"
	}
	
	/// Average heart rate (completed events only)
	var averageHeartRate: String {
		guard let data = activityData, data.avgHeartRate > 0 else { return "—" }
		return "\(data.avgHeartRate) bpm"
	}
	
	// MARK: - Computed: Intervals (Paces)
	//
	// For completed events, the watch sends a "paces" array with per-interval data.
	// Each entry may have { "interval": N, "time": "MM:SS" } or similar.
	// For active events, we generate placeholders based on the intervals count.
	
	// TODO: Sample hardcoded intervals for reference — uncomment when needed for testing
	// var intervals: [RunInterval] {
	//     (1...7).map { RunInterval(label: "Interval \($0)", time: "03:02") }
	// }
	
	var intervals: [RunInterval] {
		guard let data = activityData else { return [] }
		
		// For completed events with pace data from the watch
		if !data.paces.isEmpty {
			return data.paces.enumerated().map { index, pace in
				let label = (pace["label"] as? String) ?? "Interval \(index + 1)"
				let time: String
				if let t = pace["time"] as? String {
					time = t
				} else if let t = pace["pace"] as? String {
					time = t
				} else {
					time = "—"
				}
				return RunInterval(label: label, time: time)
			}
		}
		
		// For active events, show interval count as placeholder
		let count = Int(data.intervals) ?? 0
		guard count > 0 else { return [] }
		return (1...count).map { RunInterval(label: "Interval \($0)", time: "—") }
	}
	
	// MARK: - Computed: Segments
	//
	// Converts the raw segment dictionaries from the payload into RunSegment models.
	// For completed events, uses completedSegments if available.
	
	// TODO: Sample hardcoded segments for reference — uncomment when needed for testing
	// var segments: [RunSegment] {[
	//     RunSegment(id: 1, distance: 0.10, goalHours: 0, goalMinutes: 0,  goalSeconds: 23),
	//     RunSegment(id: 2, distance: 0.25, goalHours: 0, goalMinutes: 1,  goalSeconds: 5),
	//     RunSegment(id: 3, distance: 0.50, goalHours: 0, goalMinutes: 2,  goalSeconds: 15),
	//     RunSegment(id: 4, distance: 0.75, goalHours: 0, goalMinutes: 3,  goalSeconds: 40),
	// ]}
	
	var segments: [RunSegment] {
		guard let data = activityData else { return [] }
		
		let segSource = isCompletedEvent && !data.completedSegments.isEmpty
			? data.completedSegments
			: data.segments
		
		guard !segSource.isEmpty else { return [] }
		
		return segSource.enumerated().map { index, seg in
			// Distance
			let dist: Float
			if let d = seg["distance"] as? Float {
				dist = d
			} else if let d = seg["distance"] as? NSNumber {
				dist = d.floatValue
			} else if let d = seg["distance"] as? String, let df = Float(d) {
				dist = df
			} else {
				dist = 0
			}
			
			// ETA / goal time — might be "HH:MM:SS" or "MM:SS"
			let etaStr = (seg["eta"] as? String) ?? (seg["goalTime"] as? String) ?? "00:00:00"
			let parts = etaStr.split(separator: ":").compactMap { Int($0) }
			let hours: Int, minutes: Int, seconds: Int
			if parts.count >= 3 {
				hours = parts[0]; minutes = parts[1]; seconds = parts[2]
			} else if parts.count == 2 {
				hours = 0; minutes = parts[0]; seconds = parts[1]
			} else {
				hours = 0; minutes = 0; seconds = parts.first ?? 0
			}
			
			return RunSegment(
				id: index,
				distance: dist,
				goalHours: hours,
				goalMinutes: minutes,
				goalSeconds: seconds
			)
		}
	}
	
	// MARK: - Route Coordinates
	//
	// TODO: Once the watch sends GPS data, parse it here.
	// For now, returns empty so the map is hidden when no route data exists.
	
	// TODO: Sample hardcoded route coordinates for reference — uncomment when needed for testing
	// var routeCoordinates: [CLLocationCoordinate2D] {[
	//     CLLocationCoordinate2D(latitude: 40.666349, longitude: -74.214964),
	//     CLLocationCoordinate2D(latitude: 40.666351, longitude: -74.214964),
	//     CLLocationCoordinate2D(latitude: 40.666589, longitude: -74.213397),
	//     CLLocationCoordinate2D(latitude: 40.667108, longitude: -74.210215),
	//     CLLocationCoordinate2D(latitude: 40.667117, longitude: -74.210118),
	//     CLLocationCoordinate2D(latitude: 40.667105, longitude: -74.210012),
	//     CLLocationCoordinate2D(latitude: 40.667080, longitude: -74.209892),
	//     CLLocationCoordinate2D(latitude: 40.667108, longitude: -74.209878),
	//     CLLocationCoordinate2D(latitude: 40.667080, longitude: -74.209892),
	//     CLLocationCoordinate2D(latitude: 40.666565, longitude: -74.208271),
	//     CLLocationCoordinate2D(latitude: 40.666190, longitude: -74.207139),
	//     CLLocationCoordinate2D(latitude: 40.665875, longitude: -74.206130),
	//     CLLocationCoordinate2D(latitude: 40.665519, longitude: -74.205041),
	//     CLLocationCoordinate2D(latitude: 40.665062, longitude: -74.203670),
	//     CLLocationCoordinate2D(latitude: 40.662094, longitude: -74.205338),
	//     CLLocationCoordinate2D(latitude: 40.662277, longitude: -74.205923),
	//     CLLocationCoordinate2D(latitude: 40.662599, longitude: -74.206870),
	//     CLLocationCoordinate2D(latitude: 40.662651, longitude: -74.206839),
	//     CLLocationCoordinate2D(latitude: 40.662599, longitude: -74.206870),
	//     CLLocationCoordinate2D(latitude: 40.662753, longitude: -74.207334),
	//     CLLocationCoordinate2D(latitude: 40.663017, longitude: -74.208182),
	//     CLLocationCoordinate2D(latitude: 40.663376, longitude: -74.209234),
	//     CLLocationCoordinate2D(latitude: 40.663501, longitude: -74.209625),
	//     CLLocationCoordinate2D(latitude: 40.663889, longitude: -74.210708),
	//     CLLocationCoordinate2D(latitude: 40.663970, longitude: -74.210914),
	//     CLLocationCoordinate2D(latitude: 40.664047, longitude: -74.211082),
	//     CLLocationCoordinate2D(latitude: 40.664220, longitude: -74.211468),
	//     CLLocationCoordinate2D(latitude: 40.664183, longitude: -74.211498),
	//     CLLocationCoordinate2D(latitude: 40.664164, longitude: -74.211525),
	//     CLLocationCoordinate2D(latitude: 40.664175, longitude: -74.211538),
	//     CLLocationCoordinate2D(latitude: 40.664512, longitude: -74.212413),
	//     CLLocationCoordinate2D(latitude: 40.664583, longitude: -74.212379),
	//     CLLocationCoordinate2D(latitude: 40.664812, longitude: -74.212951),
	//     CLLocationCoordinate2D(latitude: 40.664901, longitude: -74.213219),
	//     CLLocationCoordinate2D(latitude: 40.665301, longitude: -74.214550),
	//     CLLocationCoordinate2D(latitude: 40.665328, longitude: -74.214768),
	//     CLLocationCoordinate2D(latitude: 40.665487, longitude: -74.214759),
	//     CLLocationCoordinate2D(latitude: 40.666346, longitude: -74.214997),
	//     CLLocationCoordinate2D(latitude: 40.666351, longitude: -74.214964),
	// ]}
	
	var routeCoordinates: [CLLocationCoordinate2D] {
		// No GPS data from watch yet — return empty
		return []
	}
	
	/// True when there's GPS route data to display on the map
	var hasRouteData: Bool {
		!routeCoordinates.isEmpty
	}

	
	// MARK: - Actions
	func toggleFavorite() {
		withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
			isFavorite.toggle()
		}
	}
	
	func toggleAnalysis() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
			isAnalysisExpanded.toggle()
		}
	}
	
	func toggleIntervals() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
			isIntervalsExpanded.toggle()
		}
	}
	
	func toggleSegments() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
			isSegmentsExpanded.toggle()
		}
	}

	//TODO: Dublicate event
	func editEvent() {
		showEditScreen = !(showEditScreen ?? false)
	}
	
	// MARK: - Private Helpers
	
	/// Parses a time string like "01:30:00", "-00:01:10", "+00:02:09" into total seconds.
	/// Handles HH:MM:SS, MM:SS, and optional leading +/- sign.
	private static func parseTimeString(_ value: String) -> Int {
		var str = value.trimmingCharacters(in: .whitespaces)
		guard !str.isEmpty else { return 0 }
		
		let isNeg = str.hasPrefix("-")
		if str.hasPrefix("-") || str.hasPrefix("+") {
			str = String(str.dropFirst())
		}
		
		let parts = str.split(separator: ":").compactMap { Int($0) }
		let totalSeconds: Int
		if parts.count >= 3 {
			totalSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2]
		} else if parts.count == 2 {
			totalSeconds = parts[0] * 60 + parts[1]
		} else {
			totalSeconds = parts.first ?? 0
		}
		
		return isNeg ? -totalSeconds : totalSeconds
	}
}
