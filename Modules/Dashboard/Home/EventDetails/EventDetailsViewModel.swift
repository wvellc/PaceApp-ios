//
//  EventDetailsViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI
import CoreLocation
import MapKit
import Logging

// MARK: - SegmentRow
//
// Display model for one row in RunSegmentsSectionView.
// Active events: goalTime + plannedDistance only.
// Completed events: both goal and actual fields populated.
// Used exclusively in the view layer — not stored or encoded.

struct SegmentRow: Identifiable {
	let id: Int                   // 0-based index → displayed as "S1", "S2"…
	let goalTime: String          // Planned goal time "HH:MM:SS"
	let plannedDistance: String   // Planned distance "1.83 mi"
	var actualTime: String?       // Actual elapsed time from watch — nil for active events
	var actualDistance: String?   // Actual distance covered — nil when 0.00 or not yet completed

	/// True when the watch has sent completion data for this segment.
	var isCompleted: Bool { actualTime != nil }
}

// MARK: - EventDetailsViewModel
//
// Drives the EventDetailsScreen with real data from ActivityData.
// For active events (upcoming), shows planned distance/goal/segments.
// For completed events (history), shows actual time, variance, heart rate, etc.

@Observable
final class EventDetailsViewModel {

	// MARK: - Input
	var activityData: ActivityData?

	// MARK: - Section Expansion
	var isAnalysisExpanded: Bool  = true
	var isIntervalsExpanded: Bool = false
	var isSegmentsExpanded: Bool  = false

	// MARK: - Toggle States
	var isFavorite: Bool = false
	var isLoadingFavorite: Bool = false
	var showEditScreen: ActivityData?   // Matches navigationDestination binding

	private let favoritesRepository: FavoritesRepositoryProtocol

	// MARK: - Init
	init(
		activityData: ActivityData? = nil,
		favoritesRepository: FavoritesRepositoryProtocol = FirestoreFavoritesRepository.shared
	) {
		self.activityData = activityData
		self.favoritesRepository = favoritesRepository
		Task { await fetchInitialFavoriteStatus() }
	}

	// MARK: - Computed: Whether this is a completed event

	/// True if the event has actual completion data (actualTime, actualDist, etc.)
	var isCompletedEvent: Bool {
		guard let data = activityData else { return false }
		return !data.actualDist.isEmpty || !data.timeVar.isEmpty
	}

	// MARK: - Computed: Time Delta
	// ... (all your existing computed properties unchanged - timeDeltaSeconds, completionPercent, etc.)

	var timeDeltaSeconds: Int {
		guard let data = activityData else { return 0 }
		let raw = data.timeVar.trimmingCharacters(in: .whitespaces)
		guard !raw.isEmpty else { return 0 }
		return Self.parseTimeString(raw)
	}

	var timeDeltaIsNegative: Bool { timeDeltaSeconds < 0 }

	var timeDeltaFormatted: String {
		guard let data = activityData, !data.timeVar.isEmpty else { return "--:--" }
		return data.timeVar
	}

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
	// ... (eventDistance, completedDistance, finishTimeGoal, etc. - unchanged)

	var eventDistance: String {
		activityData?.distance ?? "—"
	}

	var completedDistance: String {
		guard let data = activityData, !data.actualDist.isEmpty else { return "—" }
		let unit = data.measure == "Miles" ? "mi" : "km"
		if data.actualDist.contains("mi") || data.actualDist.contains("km") {
			return data.actualDist
		}
		return "\(data.actualDist) \(unit)"
	}

	var finishTimeGoal: String {
		activityData?.goal ?? "—"
	}

	var totalTimeTaken: String {
		guard let data = activityData else { return "—" }
		if isCompletedEvent {
			return data.duration
		}
		return data.goal
	}

	var timeVariance: String {
		guard let data = activityData, !data.timeVar.isEmpty else { return "—" }
		return data.timeVar
	}

	var lookBackIntervals: String {
		activityData?.intervals ?? "—"
	}

	var segmentsCount: String {
		guard let data = activityData else { return "0" }
		return "\(data.segmentCount)"
	}

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

	// MARK: - Computed: Segment Rows
	//
	// Produces SegmentRow display models for RunSegmentsSectionView.
	// Active events  → goal fields only (data.segments).
	// Completed events → goal + actual merged positionally:
	//   data.segments[i] = plan, data.completedSegments[i] = watch actuals.

	// TODO: Sample hardcoded rows for reference — uncomment when needed for testing
	// var segmentRows: [SegmentRow] {[
	//     SegmentRow(id: 0, goalTime: "00:15:00", plannedDistance: "1.83 mi"),
	//     SegmentRow(id: 1, goalTime: "00:15:00", plannedDistance: "1.83 mi",
	//                actualTime: "00:14:22", actualDistance: "1.80 mi"),
	// ]}

	var segmentRows: [SegmentRow] {
		guard let data = activityData else { return [] }
		let unit = (data.measure == "Miles") ? "mi" : "km"

		// ── Active event — show plan only ────────────────────────────────────
		if !isCompletedEvent {
			return data.segments.map { seg in
				let distStr = String(format: "%.2f %@", seg.distance, unit)
				return SegmentRow(id: seg.id, goalTime: seg.formattedGoalTime, plannedDistance: distStr)
			}
		}

		// ── Completed event — merge plan + actuals positionally ──────────────
		// Fall back to plan-only rows when the watch hasn't sent completedSegments yet.
		guard !data.completedSegments.isEmpty else {
			return data.segments.map { seg in
				let distStr = String(format: "%.2f %@", seg.distance, unit)
				return SegmentRow(id: seg.id, goalTime: seg.formattedGoalTime, plannedDistance: distStr)
			}
		}

		return data.completedSegments.enumerated().map { index, completed in
			// Goal fields sourced from matching planned segment by position (Q2: positional order is safe).
			let planned        = index < data.segments.count ? data.segments[index] : nil
			let goalTime       = planned?.formattedGoalTime ?? "—"
			let plannedDistStr = planned.map { String(format: "%.2f %@", $0.distance, unit) } ?? "—"

			// Actual elapsed time "elapsed_time": "00:00:44"
			let actualTime = completed["elapsed_time"] as? String

			// Actual distance "completed_distance": "0.00" — treat 0.00 as nil (Q1: genuine zero = no display)
			let rawActual  = Self.distanceDouble(from: completed, key: "completed_distance")
			let actualDist: String? = rawActual > 0
				? String(format: "%.2f %@", rawActual, unit)
				: nil

			return SegmentRow(
				id: index,
				goalTime: goalTime,
				plannedDistance: plannedDistStr,
				actualTime: actualTime,
				actualDistance: actualDist
			)
		}
	}

	// MARK: - Route Coordinates
	//
	// TODO: Once the watch sends GPS data, parse it here.
	// For now, returns empty so the map is hidden when no route data exists.

	// TODO: Sample hardcoded route coordinates for reference — uncomment when needed for testing
	 var routeCoordinates: [CLLocationCoordinate2D] {[
	     CLLocationCoordinate2D(latitude: 40.666349, longitude: -74.214964),
	     CLLocationCoordinate2D(latitude: 40.666351, longitude: -74.214964),
	     CLLocationCoordinate2D(latitude: 40.666589, longitude: -74.213397),
	     CLLocationCoordinate2D(latitude: 40.667108, longitude: -74.210215),
	     CLLocationCoordinate2D(latitude: 40.667117, longitude: -74.210118),
	     CLLocationCoordinate2D(latitude: 40.667105, longitude: -74.210012),
	     CLLocationCoordinate2D(latitude: 40.667080, longitude: -74.209892),
	     CLLocationCoordinate2D(latitude: 40.667108, longitude: -74.209878),
	     CLLocationCoordinate2D(latitude: 40.667080, longitude: -74.209892),
	     CLLocationCoordinate2D(latitude: 40.666565, longitude: -74.208271),
	     CLLocationCoordinate2D(latitude: 40.666190, longitude: -74.207139),
	     CLLocationCoordinate2D(latitude: 40.665875, longitude: -74.206130),
	     CLLocationCoordinate2D(latitude: 40.665519, longitude: -74.205041),
	     CLLocationCoordinate2D(latitude: 40.665062, longitude: -74.203670),
	     CLLocationCoordinate2D(latitude: 40.662094, longitude: -74.205338),
	     CLLocationCoordinate2D(latitude: 40.662277, longitude: -74.205923),
	     CLLocationCoordinate2D(latitude: 40.662599, longitude: -74.206870),
	     CLLocationCoordinate2D(latitude: 40.662651, longitude: -74.206839),
	     CLLocationCoordinate2D(latitude: 40.662599, longitude: -74.206870),
	     CLLocationCoordinate2D(latitude: 40.662753, longitude: -74.207334),
	     CLLocationCoordinate2D(latitude: 40.663017, longitude: -74.208182),
	     CLLocationCoordinate2D(latitude: 40.663376, longitude: -74.209234),
	     CLLocationCoordinate2D(latitude: 40.663501, longitude: -74.209625),
	     CLLocationCoordinate2D(latitude: 40.663889, longitude: -74.210708),
	     CLLocationCoordinate2D(latitude: 40.663970, longitude: -74.210914),
	     CLLocationCoordinate2D(latitude: 40.664047, longitude: -74.211082),
	     CLLocationCoordinate2D(latitude: 40.664220, longitude: -74.211468),
	     CLLocationCoordinate2D(latitude: 40.664183, longitude: -74.211498),
	     CLLocationCoordinate2D(latitude: 40.664164, longitude: -74.211525),
	     CLLocationCoordinate2D(latitude: 40.664175, longitude: -74.211538),
	     CLLocationCoordinate2D(latitude: 40.664512, longitude: -74.212413),
	     CLLocationCoordinate2D(latitude: 40.664583, longitude: -74.212379),
	     CLLocationCoordinate2D(latitude: 40.664812, longitude: -74.212951),
	     CLLocationCoordinate2D(latitude: 40.664901, longitude: -74.213219),
	     CLLocationCoordinate2D(latitude: 40.665301, longitude: -74.214550),
	     CLLocationCoordinate2D(latitude: 40.665328, longitude: -74.214768),
	     CLLocationCoordinate2D(latitude: 40.665487, longitude: -74.214759),
	     CLLocationCoordinate2D(latitude: 40.666346, longitude: -74.214997),
	     CLLocationCoordinate2D(latitude: 40.666351, longitude: -74.214964),
	 ]}

	/// True when there's GPS route data to display on the map
	var hasRouteData: Bool {
		!routeCoordinates.isEmpty
	}

	// MARK: - Favorites

	private func fetchInitialFavoriteStatus() async {
		guard let userId = AuthManager.shared.currentUserID,
			  let eventId = effectiveEventId else { return }

		isLoadingFavorite = true
		defer { isLoadingFavorite = false }

		do {
			isFavorite = try await favoritesRepository.isFavorited(
				userId: userId,
				eventId: String(eventId)
			)
		} catch {
			logger.error("Failed to fetch favorite status for event \(eventId): \(error)")
			isFavorite = false
		}
	}

	func toggleFavorite() {
		guard let userId = AuthManager.shared.currentUserID,
			  let eventId = effectiveEventId else { return }

		let previousState = isFavorite
		isFavorite.toggle() // Optimistic UI update

		Task {
			do {
				let newState = try await favoritesRepository.toggleFavorite(
					userId: userId,
					eventId: String(eventId)
				)
				isFavorite = newState // Sync with server result
			} catch {
				logger.error("Failed to toggle favorite: \(error)")
				isFavorite = previousState // Rollback
			}
		}
	}

	private var effectiveEventId: Int? {
		activityData?.syncId ?? activityData?.id   // Prefer syncId if available (Garmin)
	}

	// MARK: - Actions

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

	func editEvent() {
		showEditScreen = activityData
	}

	// MARK: - Private Helpers

	/// Parses a time string like "01:30:00", "-00:01:10", "+00:02:09" into total seconds.
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

	/// Extracts a Double from a raw watch dict value — handles String, Float, NSNumber.
	/// Used only for completedSegments fields which remain [[String: Any]] (variable watch shape).
	private static func distanceDouble(from dict: [String: Any], key: String) -> Double {
		if let d = dict[key] as? Double   { return d }
		if let d = dict[key] as? Float    { return Double(d) }
		if let d = dict[key] as? NSNumber { return d.doubleValue }
		if let d = dict[key] as? String   { return Double(d) ?? 0 }
		return 0
	}
}
