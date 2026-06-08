//
//  EventDocumentMapper.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore
import SwiftUI

enum EventDocumentMapper {

	// MARK: - ConnectIQ Payload → Firestore

	static func document(
		from payload: [String: Any],
		userId: String,
		isCompleted: Bool,
		syncStatus: String,
		source: String
	) -> (FirestoreEventDocument, [EventSegmentDocument]) {
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
		let avgPaceSeconds = computeAvgPaceSeconds(
			actualTimeSeconds: actualTimeSeconds,
			actualDistance: actualDistance,
			paces: arrayOfDicts(from: payload["paces"])
		)
		let effortPercentage = computeEffortPercentage(
			goalTimeSeconds: goalTimeSeconds,
			actualTimeSeconds: actualTimeSeconds
		)

		let segmentPayloads = arrayOfDicts(from: payload["segments"])
		let segments = segmentPayloads.enumerated().map { index, segment in
			EventSegmentDocument(
				documentId: String(index),
				index: index,
				distance: parseDouble(segment["distance"]) ?? 0,
				goalTimeSeconds: parseTimeString((segment["eta"] as? String) ?? "00:00:00"),
				completedAt: nil,
				actualTimeSeconds: nil
			)
		}

		let doc = FirestoreEventDocument(
			documentId: String(id),
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
			paces: mapPaces(arrayOfDicts(from: payload["paces"])),
			completedSegments: mapGenericDicts(arrayOfDicts(from: payload["completedSegments"])),
			syncStatus: syncStatus,
			source: source,
			createdAt: now,
			updatedAt: now,
			deletedAt: nil
		)
		return (doc, segments)
	}

	// MARK: - Firestore → ActivityData

	static func activityData(
		from document: FirestoreEventDocument,
		segments: [EventSegmentDocument] = []
	) -> ActivityData? {
		let unit = document.measure == "Miles" ? "mi" : "km"
		let distanceText = String(format: "%.2f %@", document.distanceValue, unit)
		let goalStr = formatTime(document.goalTimeSeconds)
		let actualTimeStr = document.actualTimeSeconds.map { formatTime($0) } ?? ""
		let durationStr = actualTimeStr.isEmpty ? goalStr : actualTimeStr
		let timeVarStr = document.timeVarianceSeconds.map { formatSignedVariance($0) } ?? ""
		let deltaColor: Color = timeVarStr.hasPrefix("-") ? .fluorescentMint : .redBoho
		let actualDistStr: String
		if let ad = document.actualDistance {
			actualDistStr = String(format: "%.2f", ad)
		} else {
			actualDistStr = ""
		}

		let segmentMaps: [[String: Any]] = segments.isEmpty
			? []
			: segments.map { seg in
				[
					"distance": seg.distance,
					"eta": formatTime(seg.goalTimeSeconds)
				]
			}

		let payload: [String: Any] = [
			"id": document.id,
			"name": document.name,
			"location": document.location,
			"date": connectIQDateString(from: document.scheduledAt.dateValue()),
			"distance": String(format: "%.2f", document.distanceValue),
			"measure": document.measure,
			"goal": goalStr,
			"intervals": "\(document.lookBackIntervals)",
			"activity": displayActivityType(document.activityType),
			"segmentCount": max(segmentMaps.count, 1),
			"segments": segmentMaps,
			"completedSegments": genericDictsToAny(document.completedSegments),
			"actualTime": actualTimeStr,
			"actualDist": actualDistStr,
			"timeVar": timeVarStr,
			"avgHeartRate": document.avgHeartRate ?? 0,
			"paces": genericDictsToAny(document.paces)
		]
		return ActivityData(connectIQPayload: payload)
	}

	// MARK: - ActivityData metadata update

	static func updatedDocument(
		_ document: FirestoreEventDocument,
		name: String,
		location: String
	) -> FirestoreEventDocument {
		var copy = document
		copy.name = name
		copy.location = location
		copy.updatedAt = Timestamp(date: Date())
		return copy
	}

	// MARK: - Analytics record

	static func analyticsRecord(from document: FirestoreEventDocument) -> EventAnalyticsRecord? {
		guard document.eventStatus == .completed,
			  let completedAt = document.completedAt?.dateValue() else { return nil }
		return EventAnalyticsRecord(
			documentId: document.firestoreDocumentId,
			completedAt: completedAt,
			avgPaceSeconds: document.avgPaceSeconds ?? 0,
			avgHeartRate: document.avgHeartRate ?? 0,
			elevationGain: document.elevationGain ?? 0,
			effortPercentage: document.effortPercentage ?? 0,
			distanceValue: document.actualDistance ?? document.distanceValue,
			measure: document.measure
		)
	}

	// MARK: - Helpers

	static func connectIQId(from value: Any?) -> Int? {
		if let value = value as? Int { return value }
		if let value = value as? NSNumber { return value.intValue }
		if let value = value as? String { return Int(value) }
		return nil
	}

	static func parseConnectIQDate(_ value: String?) -> Date? {
		guard let value else { return nil }
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		for format in ["MMM/d/yyyy", "MMM/dd/yyyy", "yyyy-MM-dd"] {
			formatter.dateFormat = format
			if let date = formatter.date(from: value) { return date }
		}
		return nil
	}

	static func connectIQDateString(from date: Date) -> String {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "MMM/d/yyyy"
		return formatter.string(from: date)
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
		if let v = value as? Double { return v }
		if let v = value as? Float { return Double(v) }
		if let v = value as? Int { return Double(v) }
		if let v = value as? NSNumber { return v.doubleValue }
		if let v = value as? String { return Double(v) }
		return nil
	}

	static func parseInt(_ value: Any?) -> Int? {
		if let v = value as? Int { return v }
		if let v = value as? NSNumber { return v.intValue }
		if let v = value as? String { return Int(v) }
		return nil
	}

	static func arrayOfDicts(from value: Any?) -> [[String: Any]] {
		if let arr = value as? [[String: Any]] { return arr }
		if let nsArr = value as? NSArray {
			return nsArr.compactMap { $0 as? [String: Any] }
		}
		return []
	}

	static func mapActivityType(_ value: String?) -> String {
		switch value {
		case "Walk", "Walking": return "walking"
		case "Cycling", "Cycle": return "cycling"
		default: return "running"
		}
	}

	static func displayActivityType(_ value: String) -> String {
		switch value {
		case "walking": return "Walking"
		case "cycling": return "Cycling"
		default: return "Run"
		}
	}

	static func computeAvgPaceSeconds(
		actualTimeSeconds: Int?,
		actualDistance: Double?,
		paces: [[String: Any]]
	) -> Int? {
		if let pace = paces.compactMap({ parseInt($0["paceSecondsPerUnit"]) ?? parseInt($0["pace"]) }).first {
			return pace
		}
		guard let time = actualTimeSeconds, let distance = actualDistance, distance > 0 else { return nil }
		return Int(Double(time) / distance)
	}

	static func computeEffortPercentage(goalTimeSeconds: Int, actualTimeSeconds: Int?) -> Double? {
		guard let actual = actualTimeSeconds, goalTimeSeconds > 0 else { return nil }
		let ratio = Double(min(goalTimeSeconds, actual)) / Double(max(goalTimeSeconds, actual))
		return min(100, max(0, ratio * 100))
	}

	static func mapPaces(_ paces: [[String: Any]]) -> [[String: FirestoreFlexibleValue]]? {
		guard !paces.isEmpty else { return nil }
		return paces.map { pace in
			var mapped: [String: FirestoreFlexibleValue] = [:]
			for (key, value) in pace {
				if let v = value as? String { mapped[key] = .string(v) }
				else if let v = value as? Int { mapped[key] = .int(v) }
				else if let v = value as? NSNumber { mapped[key] = .int(v.intValue) }
				else if let v = value as? Double { mapped[key] = .double(v) }
			}
			return mapped
		}
	}

	static func mapGenericDicts(_ dicts: [[String: Any]]) -> [[String: FirestoreFlexibleValue]]? {
		guard !dicts.isEmpty else { return nil }
		return dicts.map { dict in
			var mapped: [String: FirestoreFlexibleValue] = [:]
			for (key, value) in dict {
				if let v = value as? String { mapped[key] = .string(v) }
				else if let v = value as? Int { mapped[key] = .int(v) }
				else if let v = value as? NSNumber { mapped[key] = .int(v.intValue) }
				else if let v = value as? Double { mapped[key] = .double(v) }
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
				case .int(let v): result[pair.key] = v
				case .double(let v): result[pair.key] = v
				case .bool(let v): result[pair.key] = v
				}
			}
		}
	}
}
