//
//  FirestoreEventDocument.swift
//  PaceApp
//

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
	let deletedIds: [Int]                  // status == "deleted" — blocks re-insertion
}

// MARK: - Firestore Event Document

struct FirestoreEventDocument: Codable, Identifiable {
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
	var paces: [[String: FirestoreFlexibleValue]]?
	var completedSegments: [[String: FirestoreFlexibleValue]]?
	var syncStatus: String
	var source: String
	var createdAt: Timestamp
	var updatedAt: Timestamp
	var deletedAt: Timestamp?

	// Document ID is always derived from the integer event id.
	var firestoreDocumentId: String { String(id) }
	var eventStatus: EventStatus { EventStatus(rawValue: status) ?? .active }
}

/// Supports mixed numeric types from legacy ConnectIQ payloads when encoding nested maps.
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
