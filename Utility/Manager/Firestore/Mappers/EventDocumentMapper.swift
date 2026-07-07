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
		let id = connectIQId(from: payload["id"]) ?? Int(Date().timeIntervalSince1970)
		let now = Timestamp(date: Date())
		let scheduledAt = parseConnectIQDate(payload["date"] as? String) ?? Date()
		let goalTimeSeconds = parseTimeString((payload["goal"] as? String) ?? "00:00:00")
		let distanceValue = parseDouble(payload["distance"]) ?? 0
		let measure = (payload["measure"] as? String) ?? "Miles"
		let actualTimeStr = (payload["actualTime"] as? String) ?? ""
		let hasCompletion = isCompleted || !actualTimeStr.isEmpty || payload["actualDist"] != nil
		let status = hasCompletion ? EventStatus.completed.rawValue : EventStatus.active.rawValue
		let actualTimeSeconds = actualTimeStr.isEmpty ? nil : parseTimeString(actualTimeStr)
		let actualDistance = parseDouble(payload["actualDist"])
		let timeVarianceSeconds = parseSignedTimeVariance((payload["timeVar"] as? String) ?? "")
		let avgHeartRate = parseInt(payload["avgHeartRate"])
		let avgPaceSeconds = parseInt(payload["avgPace"])     // watch/Firebase value only — never computed locally
		let effortPercentage = computeEffortPercentage(
			goalTimeSeconds: goalTimeSeconds,
			actualTimeSeconds: actualTimeSeconds
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
			completedAt: hasCompletion ? Timestamp(date: Date()) : nil,
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
			paces: arrayOfInts(from: payload["paces"]),
			completedSegments: mapGenericDicts(arrayOfDicts(from: payload["completedSegments"])),
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
		let unit = document.measure == "Miles" ? "mi" : "km"
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

	// MARK: - EventDocument → ConnectIQ wire-format payload
	// Inverse of document(from:...) — rebuilds the [String: Any] dict the watch expects.

	static func connectIQPayload(from document: EventDocument) -> [String: Any] {
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
			effortPercentage: document.effortPercentage ?? 0,
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

	// Cached — DateFormatter is expensive to allocate.
	private static let connectIQDateFormatter: DateFormatter = {
		let f = DateFormatter()
		f.locale = Locale(identifier: "en_US_POSIX")
		return f
	}()

	static func parseConnectIQDate(_ value: String?) -> Date? {
		guard let value else { return nil }
		for format in ["MMM/d/yyyy", "MMM/dd/yyyy", "yyyy-MM-dd"] {
			connectIQDateFormatter.dateFormat = format
			if let date = connectIQDateFormatter.date(from: value) { return date }
		}
		return nil
	}

	static func connectIQDateString(from date: Date) -> String {
		connectIQDateFormatter.dateFormat = "MMM/d/yyyy"
		return connectIQDateFormatter.string(from: date)
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

	static func computeEffortPercentage(goalTimeSeconds: Int, actualTimeSeconds: Int?) -> Double? {
		guard let actual = actualTimeSeconds, goalTimeSeconds > 0 else { return nil }
		let ratio = Double(min(goalTimeSeconds, actual)) / Double(max(goalTimeSeconds, actual))
		return min(100, max(0, ratio * 100))
	}

	static func mapGenericDicts(_ dicts: [[String: Any]]) -> [[String: FirestoreFlexibleValue]]? {
		guard !dicts.isEmpty else { return nil }
		return dicts.map { dict in
			var mapped: [String: FirestoreFlexibleValue] = [:]
			for (key, value) in dict {
				if let v = value as? String        { mapped[key] = .string(v) }
				else if let v = value as? Int      { mapped[key] = .int(v) }
				else if let v = value as? NSNumber { mapped[key] = .int(v.intValue) }
				else if let v = value as? Double   { mapped[key] = .double(v) }
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
