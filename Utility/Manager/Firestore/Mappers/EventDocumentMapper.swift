//
//  EventDocumentMapper.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore
import SwiftUI
import CoreLocation

// MARK: - EventDocumentMapper
//
// Single translation layer between raw ConnectIQ payloads, EventDocument
// (Firestore), and ActivityData (UI). All parsing logic lives here — no
// other file should parse raw [String: Any] event dicts independently.

enum EventDocumentMapper {

	// MARK: - ConnectIQ Payload → EventDocument
	// Converts the raw [String: Any] dict from the Garmin watch into an
	// EventDocument + typed RunSegment array for a single Firestore write.

	static func document(
		from payload: [String: Any],
		userId: String,
		isCompleted: Bool,
		syncStatus: String,
		source: String
	) -> (EventDocument, [RunSegment]) {
		// Parse the same canonical distances we send, so the stored value always matches the watch.
		let payload = normalizingWatchDistances(payload)
		let id = connectIQId(from: payload["id"]) ?? Int(Date().timeIntervalSince1970)
		let now = Timestamp(date: Date())
		let scheduledAt = parseConnectIQDate(payload["date"] as? String) ?? Date()
		let goalTimeSeconds = parseTimeString((payload["goal"] as? String) ?? "00:00:00")
		let distanceValue = parseDouble(payload["distance"]) ?? 0
		let measure = (payload["measure"] as? String) ?? "Miles"
		// Status comes from how the event arrived (finish_event / completedEvents), never from its fields —
		// an older watch "Duplicate" copies the original run's results onto a brand-new upcoming event.
		let status = isCompleted ? EventStatus.completed.rawValue : EventStatus.active.rawValue
		let results: [String: Any] = isCompleted ? payload : [:]
		let actualTimeStr = (results["actualTime"] as? String) ?? ""
		let actualTimeSeconds = actualTimeStr.isEmpty ? nil : parseTimeString(actualTimeStr)
		let actualDistance = parseDouble(results["actualDist"])
		let timeVarianceSeconds = parseSignedTimeVariance((results["timeVar"] as? String) ?? "")
		let avgHeartRate = parseInt(results["avgHeartRate"])
		let avgPaceSeconds = parseInt(results["avgPace"])     // watch/Firebase value only — never computed locally
		let completedSegmentPayloads = arrayOfDicts(from: results["completedSegments"])
		let effortPercentage = pacePercentage(
			goalTimeSeconds: goalTimeSeconds,
			plannedDistance: distanceValue,
			actualTimeSeconds: actualTimeSeconds,
			coveredDistance: coveredDistance(actualDistance: actualDistance, completedSegments: completedSegmentPayloads)
		)

		// Build typed RunSegment array from ConnectIQ "segments" payload.
		// Each entry has { "distance": Double, "eta": "HH:MM:SS" }.
		let segmentPayloads = arrayOfDicts(from: payload["segments"])
		let segments: [RunSegment] = segmentPayloads.enumerated().map { index, seg in
			let secs = parseTimeString((seg["eta"] as? String) ?? "00:00:00")
			return RunSegment(
				id: index,
				distance: parseDouble(seg["distance"]) ?? 0,
				goalHours: secs / 3600,
				goalMinutes: (secs % 3600) / 60,
				goalSeconds: secs % 60
			)
		}

		// Parse coordinates leniently and encode via PolylineCodec.
		var coordinates = [CLLocationCoordinate2D]()
		if let anyCoords = payload["coordinates"] as? [Any] {
			for item in anyCoords {
				if let dict = item as? [String: Any] {
					let lat = parseDouble(dict["lat"]) ?? parseDouble(dict["latitude"])
					let lng = parseDouble(dict["lng"]) ?? parseDouble(dict["longitude"])
					if let lat = lat, let lng = lng {
						coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
					}
				} else if let arr = item as? [Any], arr.count >= 2 {
					if let lat = parseDouble(arr[0]), let lng = parseDouble(arr[1]) {
						coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
					}
				}
			}
		}
		let routePolyline = coordinates.isEmpty ? nil : PolylineCodec.encode(coordinates)

		let doc = EventDocument(
			id: id,
			userId: userId,
			status: status,
			name: (payload["name"] as? String) ?? "",
			location: (payload["location"] as? String) ?? "",
			scheduledAt: Timestamp(date: scheduledAt),
			completedAt: isCompleted ? Timestamp(date: Date()) : nil,
			activityType: mapActivityType(payload["activity"] as? String),
			distanceValue: distanceValue,
			measure: measure,
			goalTimeSeconds: goalTimeSeconds,
			lookBackIntervals: parseInt(payload["intervals"]) ?? 1,
			avgPaceSeconds: avgPaceSeconds,
			avgHeartRate: avgHeartRate,
			elevationGain: 0,
			effortPercentage: effortPercentage,
			actualTimeSeconds: actualTimeSeconds,
			actualDistance: actualDistance,
			timeVarianceSeconds: timeVarianceSeconds,
			paces: arrayOfInts(from: results["paces"]),
			completedSegments: mapGenericDicts(completedSegmentPayloads),
			syncStatus: syncStatus,
			source: source,
			createdAt: now,
			updatedAt: now,
			deletedAt: nil,
			segments: segments.isEmpty ? nil : segments,
			routePolyline: routePolyline
		)
		return (doc, segments)
	}

	// MARK: - EventDocument → ActivityData
	// Single mapping path from persisted data to the UI layer.
	// Segments are passed as typed [RunSegment] — no [[String: Any]] round-trip.

	static func activityData(
		from document: EventDocument,
		segments: [RunSegment] = []
	) -> ActivityData? {
		let unit = MeasureUnit(measure: document.measure).shortLabel
		let distanceText = String(format: "%.2f %@", document.distanceValue, unit)
		let goalStr = formatTime(document.goalTimeSeconds)
		let actualTimeStr = document.actualTimeSeconds.map { formatTime($0) } ?? ""
		let durationStr = actualTimeStr.isEmpty ? goalStr : actualTimeStr
		let timeVarStr = document.timeVarianceSeconds.map { formatSignedVariance($0) } ?? ""
		let deltaColor: Color = timeVarStr.hasPrefix("-") ? .fluorescentMint : .redBoho
		let actualDistStr = document.actualDistance.map { String(format: "%.2f", $0) } ?? ""
		let routeCoords = document.routePolyline.map { PolylineCodec.decode($0) } ?? []

		return ActivityData(
			id: document.id,
			syncId: document.id,
			title: document.name,
			date: document.scheduledAt.dateValue(),
			distance: distanceText,
			duration: durationStr,
			avgPace: document.avgPaceSeconds ?? 0,
			delta: timeVarStr,
			deltaColor: deltaColor,
			location: document.location,
			gaitType: gaitType(from: document.activityType),
			eventType: document.eventType,
			goal: goalStr,
			measure: document.measure,
			intervals: "\(document.lookBackIntervals)",
			segmentCount: max(segments.count, 1),
			segments: segments,                                      // typed [RunSegment] — no dict conversion
			completedSegments: genericDictsToAny(document.completedSegments),
			actualDist: actualDistStr,
			timeVar: timeVarStr,
			avgHeartRate: document.avgHeartRate ?? 0,
			pacePercentage: pacePercentage(for: document),
			paces: document.paces ?? [],
			routeCoordinates: routeCoords
		)
	}

	// MARK: - Metadata update

	static func updatedDocument(
		_ document: EventDocument,
		name: String,
		location: String
	) -> EventDocument {
		var copy = document
		copy.name = name
		copy.location = location
		copy.updatedAt = Timestamp(date: Date())
		return copy
	}

	// MARK: - Distance (watch wire format)
	// Every distance synced with the watch goes through here, e.g. 14 → "14.00", 14.0005 → "14.00".

	/// Decimal places for synced distances — the one knob (the client's "tenths" would be 1).
	static let distanceFractionDigits = 2

	/// Watch wire string for a distance. `String(format:)` isn't localized, so the separator is always ".".
	static func watchDistanceString(_ value: Double) -> String {
		String(format: "%.\(distanceFractionDigits)f", value)
	}

	/// The value both sides calculate with — parsed back from the wire string, so the two can never disagree.
	static func canonicalDistance(_ value: Double) -> Double {
		Double(watchDistanceString(value)) ?? value
	}

	/// Rounds segment distances, giving the rounding remainder to the last one so they still sum to the total.
	/// Drift larger than rounding (a genuinely different split) is left untouched.
	static func canonicalSegmentDistances(_ distances: [Double], total: Double) -> [Double] {
		var rounded = distances.map { canonicalDistance($0) }
		guard let last = rounded.indices.last, total > 0 else { return rounded }
		let drift = canonicalDistance(total) - rounded.reduce(0, +)
		let maxRoundingDrift = Double(rounded.count) * 0.5 * pow(10, -Double(distanceFractionDigits)) + 1e-9
		let adjusted = canonicalDistance(rounded[last] + drift)
		guard abs(drift) <= maxRoundingDrift, adjusted > 0 else { return rounded }
		rounded[last] = adjusted
		return rounded
	}

	/// Rewrites "distance", "actualDist" and each segment "distance" in a watch payload as canonical wire strings.
	static func normalizingWatchDistances(_ payload: [String: Any]) -> [String: Any] {
		var result = payload
		let total = parseDouble(payload["distance"])
		if let total { result["distance"] = watchDistanceString(canonicalDistance(total)) }
		if let actual = parseDouble(payload["actualDist"]) {
			result["actualDist"] = watchDistanceString(canonicalDistance(actual))
		}
		let segments = arrayOfDicts(from: payload["segments"])
		let segmentDistances = segments.compactMap { parseDouble($0["distance"]) }
		// Only rewrite when every segment carries a distance, so the remainder lands on the right one.
		if !segments.isEmpty, segmentDistances.count == segments.count {
			let canonical = canonicalSegmentDistances(segmentDistances, total: total ?? 0)
			result["segments"] = zip(segments, canonical).map { segment, distance in
				var segment = segment
				segment["distance"] = watchDistanceString(distance)
				return segment
			}
		}
		return result
	}

	// MARK: - EventDocument → ConnectIQ wire-format payload
	// Inverse of document(from:...) — rebuilds the [String: Any] dict the watch expects.

	static func connectIQPayload(from document: EventDocument) -> [String: Any] {
		normalizingWatchDistances(rawConnectIQPayload(from: document))
	}

	private static func rawConnectIQPayload(from document: EventDocument) -> [String: Any] {
		var payload: [String: Any] = [
			"id":          document.id,
			"name":        document.name,
			"location":    document.location,
			"date":        connectIQDateString(from: document.scheduledAt.dateValue()),
			"distance":    document.distanceValue,
			"measure":     document.measure,
			"goal":        formatTime(document.goalTimeSeconds),
			"intervals":   document.lookBackIntervals,
			"activity":    reverseMapActivityType(document.activityType),
			"syncStatus":  document.syncStatus,
			"source":      document.source
		]

		// Completed-event fields — only present when the event has been finished
		if let actualTimeSeconds = document.actualTimeSeconds {
			payload["actualTime"] = formatTime(actualTimeSeconds)
		}
		if let actualDistance = document.actualDistance {
			payload["actualDist"] = actualDistance
		}
		if let timeVarianceSeconds = document.timeVarianceSeconds {
			payload["timeVar"] = formatSignedVariance(timeVarianceSeconds)
		}
		if let avgHeartRate = document.avgHeartRate, avgHeartRate > 0 {
			payload["avgHeartRate"] = avgHeartRate
		}
		if let paces = document.paces, !paces.isEmpty {
			payload["paces"] = paces
		}
		if let completedSegments = document.completedSegments, !completedSegments.isEmpty {
			payload["completedSegments"] = genericDictsToAny(completedSegments)
		}
		// Rebuild the watch-format "segments" array from the stored RunSegment array.
		if let segs = document.segments, !segs.isEmpty {
			payload["segments"] = segs.map { seg in
				["distance": seg.distance, "eta": formatTime(seg.totalGoalSeconds)] as [String: Any]
			}
		}
		if let routePolyline = document.routePolyline {
			let coords = PolylineCodec.decode(routePolyline)
			if !coords.isEmpty {
				payload["coordinates"] = coords.map { ["lat": $0.latitude, "lng": $0.longitude] }
			}
		}

		return payload
	}

	// MARK: - Analytics record

	static func analyticsRecord(from document: EventDocument) -> EventAnalyticsRecord? {
		guard document.eventStatus == .completed,
			  let completedAt = document.completedAt?.dateValue() else { return nil }
		return EventAnalyticsRecord(
			documentId: document.firestoreDocumentId,
			completedAt: completedAt,
			avgPaceSeconds: document.avgPaceSeconds ?? 0,
			avgHeartRate: document.avgHeartRate ?? 0,
			elevationGain: document.elevationGain ?? 0,
			// Computed from the event itself, so events stored before the pace-based formula match too.
			effortPercentage: pacePercentage(for: document) ?? 0,
			distanceValue: document.distanceValue,
			measure: document.measure
		)
	}

	// MARK: - Helpers

	static func connectIQId(from value: Any?) -> Int? {
		if let value = value as? Int      { return value }
		if let value = value as? NSNumber { return value.intValue }
		if let value = value as? String   { return Int(value) }
		return nil
	}

	// One immutable cached formatter per wire format — reassigning dateFormat on a
	// shared formatter is not thread-safe and concurrent parses could mis-parse dates.
	private static let connectIQDateFormatters: [DateFormatter] = ["MMM/d/yyyy", "MMM/dd/yyyy", "yyyy-MM-dd"].map { format in
		let f = DateFormatter()
		f.locale = Locale(identifier: "en_US_POSIX")
		f.dateFormat = format
		return f
	}

	static func parseConnectIQDate(_ value: String?) -> Date? {
		guard let value else { return nil }
		for formatter in connectIQDateFormatters {
			if let date = formatter.date(from: value) { return date }
		}
		return nil
	}

	static func connectIQDateString(from date: Date) -> String {
		connectIQDateFormatters[0].string(from: date)
	}

	static func parseTimeString(_ value: String) -> Int {
		let trimmed = value.trimmingCharacters(in: .whitespaces)
		guard !trimmed.isEmpty else { return 0 }
		let sign = trimmed.hasPrefix("-") ? -1 : 1
		let raw = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "+-"))
		let parts = raw.split(separator: ":").compactMap { Int($0) }
		switch parts.count {
			case 3: return sign * ((parts[0] * 3600) + (parts[1] * 60) + parts[2])
			case 2: return sign * ((parts[0] * 60) + parts[1])
			default: return 0
		}
	}

	static func parseSignedTimeVariance(_ value: String) -> Int? {
		let trimmed = value.trimmingCharacters(in: .whitespaces)
		guard !trimmed.isEmpty else { return nil }
		return parseTimeString(trimmed)
	}

	static func formatTime(_ seconds: Int) -> String {
		let absSeconds = abs(seconds)
		let h = absSeconds / 3600
		let m = (absSeconds % 3600) / 60
		let s = absSeconds % 60
		return String(format: "%02d:%02d:%02d", h, m, s)
	}

	static func formatSignedVariance(_ seconds: Int) -> String {
		let sign = seconds < 0 ? "-" : "+"
		return sign + formatTime(abs(seconds))
	}

	static func parseDouble(_ value: Any?) -> Double? {
		if let v = value as? Double   { return v }
		if let v = value as? Float    { return Double(v) }
		if let v = value as? Int      { return Double(v) }
		if let v = value as? NSNumber { return v.doubleValue }
		if let v = value as? String   { return Double(v) }
		return nil
	}

	static func parseInt(_ value: Any?) -> Int? {
		if let v = value as? Int      { return v }
		if let v = value as? NSNumber { return v.intValue }
		if let v = value as? String   { return Int(v) }
		return nil
	}

	static func arrayOfDicts(from value: Any?) -> [[String: Any]] {
		if let arr = value as? [[String: Any]]  { return arr }
		if let nsArr = value as? NSArray { return nsArr.compactMap { $0 as? [String: Any] } }
		return []
	}

	// Watch "paces" payload is a flat array of per-interval pace seconds, e.g. [256, 256, 265].
	static func arrayOfInts(from value: Any?) -> [Int] {
		if let arr = value as? [Int] { return arr }
		if let nsArr = value as? NSArray { return nsArr.compactMap { parseInt($0) } }
		if let arr = value as? [Any] { return arr.compactMap { parseInt($0) } }
		return []
	}

	static func mapActivityType(_ value: String?) -> String {
		return ActivityType(from: value).rawValue
	}

	static func reverseMapActivityType(_ value: String) -> String {
		return ActivityType(from: value).watchString
	}

	static func displayActivityType(_ value: String) -> String {
		return ActivityType(from: value).rawValue
	}

	static func gaitType(from activityType: String) -> GaitType {
		switch ActivityType(from: activityType) {
			case .walking: return .walking
			default:       return .running
		}
	}

	// Pace % = goal pace ÷ actual pace × 100 — 100% is right on goal pace, above 100% is faster.
	// e.g. goal 10 km in 50:00, covered 10 km in 45:00 → 111%.
	static func pacePercentage(for document: EventDocument) -> Double? {
		pacePercentage(
			goalTimeSeconds: document.goalTimeSeconds,
			plannedDistance: document.distanceValue,
			actualTimeSeconds: document.actualTimeSeconds,
			coveredDistance: coveredDistance(
				actualDistance: document.actualDistance,
				completedSegments: genericDictsToAny(document.completedSegments)
			)
		)
	}

	static func pacePercentage(goalTimeSeconds: Int, plannedDistance: Double, actualTimeSeconds: Int?, coveredDistance: Double) -> Double? {
		guard let actualTimeSeconds, actualTimeSeconds > 0, goalTimeSeconds > 0, plannedDistance > 0, coveredDistance > 0 else { return nil }
		let goalPace = Double(goalTimeSeconds) / plannedDistance
		let actualPace = Double(actualTimeSeconds) / coveredDistance
		return goalPace / actualPace * 100
	}

	/// Distance actually covered — actualDistance, else the sum of each segment's completed_distance (mirrors functions `coveredDistance`).
	static func coveredDistance(actualDistance: Double?, completedSegments: [[String: Any]]) -> Double {
		if let actualDistance, actualDistance > 0 { return actualDistance }
		return completedSegments.reduce(0) { $0 + (parseDouble($1["completed_distance"]) ?? 0) }
	}

	static func mapGenericDicts(_ dicts: [[String: Any]]) -> [[String: FirestoreFlexibleValue]]? {
		guard !dicts.isEmpty else { return nil }
		return dicts.map { dict in
			var mapped: [String: FirestoreFlexibleValue] = [:]
			for (key, value) in dict {
				if let v = value as? String        { mapped[key] = .string(v) }
				else if let v = value as? Int      { mapped[key] = .int(v) }
				else if let v = value as? Double   { mapped[key] = .double(v) }
				else if let v = value as? NSNumber {
					// Fractional NSNumbers must stay Double — intValue truncated 0.25 → 0.
					let d = v.doubleValue
					mapped[key] = d.truncatingRemainder(dividingBy: 1) == 0 ? .int(v.intValue) : .double(d)
				}
			}
			return mapped
		}
	}

	static func genericDictsToAny(_ dicts: [[String: FirestoreFlexibleValue]]?) -> [[String: Any]] {
		guard let dicts else { return [] }
		return dicts.map { dict in
			dict.reduce(into: [String: Any]()) { result, pair in
				switch pair.value {
					case .string(let v): result[pair.key] = v
					case .int(let v):    result[pair.key] = v
					case .double(let v): result[pair.key] = v
					case .bool(let v):   result[pair.key] = v
				}
			}
		}
	}
}
