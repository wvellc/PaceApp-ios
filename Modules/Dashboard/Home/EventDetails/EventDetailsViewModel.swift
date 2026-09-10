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

struct SegmentRow: Identifiable {
	let id: Int                   // 0-based index → displayed as "S1", "S2"…
	let goalTime: String          // Planned goal time "HH:MM:SS"
	let plannedDistance: String   // Planned distance "1.83 mi"
	var actualTime: String?       // Actual elapsed time from watch — nil for active events
	var actualDistance: String?   // Actual distance covered — always shown once completed (incl. 0.00)

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
	var duplicateSource: ActivityData?  // Pushes the duplicate flow seeded with this event's plan

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
	// ... (timeDeltaSeconds, completionPercentText, etc.)

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

	/// Pace % badge — goal pace ÷ actual pace from the mapper, e.g. "111%" when faster than goal pace.
	var completionPercentText: String {
		guard isCompletedEvent, let percent = activityData?.pacePercentage else { return "—" }
		return "\(Int(percent.rounded()))%"
	}

	// MARK: - Computed: Analysis
	// ... (eventDistance, completedDistance, finishTimeGoal, etc. - unchanged)

	var eventDistance: String {
		activityData?.distance ?? "—"
	}

	var completedDistance: String {
		guard let data = activityData, !data.actualDist.isEmpty else { return "—" }
		let unit = MeasureUnit(measure: data.measure).shortLabel
		if data.actualDist.contains("mi") || data.actualDist.contains("km") {
			return data.actualDist
		}
		return "\(data.actualDist) \(unit)"
	}

	var finishTimeGoal: String {
		activityData?.goal ?? "—"
	}

	/// Actual finish time — only a completed event has one, so "—" hides the stat on upcoming events.
	var totalTimeTaken: String {
		guard let data = activityData, isCompletedEvent else { return "—" }
		return data.duration
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
	// For completed events, the watch sends a "paces" array — one entry per interval,
	// each the pace for that interval in seconds (e.g. [256, 256, 265]).
	// For active events, we generate placeholders based on the look-back intervals count.

	// TODO: Sample hardcoded intervals for reference — uncomment when needed for testing
	// var intervals: [RunInterval] {
	//     (1...7).map { RunInterval(label: "Interval \($0)", time: "03:02") }
	// }

	var intervals: [RunInterval] {
		guard let data = activityData else { return [] }

		// For completed events with real pace data (seconds per interval) from the watch
		if !data.paces.isEmpty {
			return data.paces.enumerated().map { index, seconds in
				RunInterval(label: "Interval \(index + 1)", time: Self.formatPaceSeconds(seconds))
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
		let unit = MeasureUnit(measure: data.measure).shortLabel

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

			// Actual distance "completed_distance": "0.00" — always shown for completed segments,
			// matching the "0.00 km"/"0.00 mi" format used on Awaiting rows (Q1 revised: genuine
			// zero is still a real completed distance and should display, not be hidden as nil).
			let rawActual  = Self.distanceDouble(from: completed, key: "completed_distance")
			let actualDist: String? = String(format: "%.2f %@", rawActual, unit)

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
	var routeCoordinates: [CLLocationCoordinate2D] {
		// Drop invalid / (0,0) placeholder points the watch or Firebase send for events without GPS.
		(activityData?.routeCoordinates ?? []).filter {
			CLLocationCoordinate2DIsValid($0) && ($0.latitude != 0 || $0.longitude != 0)
		}
	}

	/// True when there's real GPS route data to display on the map.
	/// Needs at least two points — a single coordinate can't draw a polyline.
	var hasRouteData: Bool {
		routeCoordinates.count >= 2
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

	func duplicateEvent() {
		duplicateSource = activityData
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

	/// Formats a per-interval pace in seconds as "MM:SS" for display in the Intervals section.
	private static func formatPaceSeconds(_ seconds: Int) -> String {
		let m = seconds / 60
		let s = seconds % 60
		return String(format: "%02d:%02d", m, s)
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
