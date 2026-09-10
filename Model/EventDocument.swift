//
//  EventDocument.swift
//  PaceApp
//
//  Domain model for a persisted run/walk event.
//  Encodes/decodes directly to/from the Firestore `events` collection.
//  Previously named FirestoreEventDocument — renamed to reflect that this
//  is a core domain type, not an implementation detail of the Firestore layer.

import Foundation
import FirebaseFirestore

// MARK: - Event Status

enum EventStatus: String, Codable, CaseIterable {
	case active
	case completed
	case deleted
}

// MARK: - ConnectIQ Event Snapshot
// Result of a single fetchAllEventPayloads call — partitioned client-side by status.
// e.g. snapshot.activePayloads → [["id": 1, "name": "Run", ...], ...]
struct ConnectIQEventSnapshot {
	let activePayloads: [[String: Any]]    // status == "active"
	let completedPayloads: [[String: Any]] // status == "completed"
	let deletedEvents: [Int: Date]         // status == "deleted" → when; keeps deleted events from coming back
}

// MARK: - EventDocument

struct EventDocument: Codable, Identifiable {
	var id: Int
	var userId: String
	var status: String
	var name: String
	var location: String
	var scheduledAt: Timestamp
	var completedAt: Timestamp?
	var activityType: String
	var distanceValue: Double
	var measure: String
	var goalTimeSeconds: Int
	var lookBackIntervals: Int
	var avgPaceSeconds: Int?
	var avgHeartRate: Int?
	var elevationGain: Double?
	var effortPercentage: Double?
	var actualTimeSeconds: Int?
	var actualDistance: Double?
	var timeVarianceSeconds: Int?
	var paces: [Int]?  // per-interval pace, seconds each (e.g. [256, 256, 265]) — from watch "paces" array
	var completedSegments: [[String: FirestoreFlexibleValue]]?
	var syncStatus: String
	var source: String
	var createdAt: Timestamp
	var updatedAt: Timestamp
	var deletedAt: Timestamp?

	// Flat segment array — stored on the parent document, not a subcollection.
	var segments: [RunSegment]?

	// Full-route GPS trace, Google encoded-polyline format (single field on the
	// parent document — see PolylineCodec). Keeps large coordinate datasets
	// compact enough to stay well under Firestore's 1MB document limit.
	var routePolyline: String?

	// Document ID is always derived from the integer event id.
	var firestoreDocumentId: String { String(id) }
	var eventStatus: EventStatus { EventStatus(rawValue: status) ?? .active }

	// Typed accessor for the stored `activityType` string (run/walk/cycling/other),
	// set by the mapper both when decoding from Firestore and when creating events.
	var eventType: ActivityType { ActivityType(from: activityType) }
}

// MARK: - Decode Fallback
// Rare offline writes can omit the write-once fields; default them at decode
// so the event stays visible and heals on the next online upsert.

extension EventDocument {
	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		id                  = try c.decode(Int.self, forKey: .id)
		userId              = try c.decode(String.self, forKey: .userId)
		status              = try c.decode(String.self, forKey: .status)
		name                = try c.decode(String.self, forKey: .name)
		location            = try c.decode(String.self, forKey: .location)
		scheduledAt         = try c.decode(Timestamp.self, forKey: .scheduledAt)
		completedAt         = try c.decodeIfPresent(Timestamp.self, forKey: .completedAt)
		activityType        = try c.decode(String.self, forKey: .activityType)
		distanceValue       = try c.decode(Double.self, forKey: .distanceValue)
		measure             = try c.decode(String.self, forKey: .measure)
		goalTimeSeconds     = try c.decode(Int.self, forKey: .goalTimeSeconds)
		lookBackIntervals   = try c.decode(Int.self, forKey: .lookBackIntervals)
		avgPaceSeconds      = try c.decodeIfPresent(Int.self, forKey: .avgPaceSeconds)
		avgHeartRate        = try c.decodeIfPresent(Int.self, forKey: .avgHeartRate)
		elevationGain       = try c.decodeIfPresent(Double.self, forKey: .elevationGain)
		effortPercentage    = try c.decodeIfPresent(Double.self, forKey: .effortPercentage)
		actualTimeSeconds   = try c.decodeIfPresent(Int.self, forKey: .actualTimeSeconds)
		actualDistance      = try c.decodeIfPresent(Double.self, forKey: .actualDistance)
		timeVarianceSeconds = try c.decodeIfPresent(Int.self, forKey: .timeVarianceSeconds)
		paces               = try c.decodeIfPresent([Int].self, forKey: .paces)
		completedSegments   = try c.decodeIfPresent([[String: FirestoreFlexibleValue]].self, forKey: .completedSegments)
		syncStatus          = try c.decodeIfPresent(String.self, forKey: .syncStatus) ?? "synced"
		updatedAt           = try c.decodeIfPresent(Timestamp.self, forKey: .updatedAt) ?? Timestamp(date: Date())
		source              = try c.decodeIfPresent(String.self, forKey: .source) ?? "watch"
		createdAt           = try c.decodeIfPresent(Timestamp.self, forKey: .createdAt) ?? updatedAt
		deletedAt           = try c.decodeIfPresent(Timestamp.self, forKey: .deletedAt)
		segments            = try c.decodeIfPresent([RunSegment].self, forKey: .segments)
		routePolyline       = try c.decodeIfPresent(String.self, forKey: .routePolyline)
	}
}

// MARK: - FirestoreFlexibleValue
// Supports mixed numeric types from legacy ConnectIQ payloads when encoding nested maps.

enum FirestoreFlexibleValue: Codable {
	case string(String)
	case int(Int)
	case double(Double)
	case bool(Bool)

	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if let v = try? container.decode(String.self) { self = .string(v); return }
		if let v = try? container.decode(Int.self)    { self = .int(v);    return }
		if let v = try? container.decode(Double.self) { self = .double(v); return }
		if let v = try? container.decode(Bool.self)   { self = .bool(v);   return }
		self = .string("")
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case .string(let v): try container.encode(v)
		case .int(let v):    try container.encode(v)
		case .double(let v): try container.encode(v)
		case .bool(let v):   try container.encode(v)
		}
	}
}
