//
//  RunSegment.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

import Foundation

// MARK: - RunSegment
//
// Unified segment model — used in the app UI layer (CreateRunEventViewModel,
// SegmentDetailStepView, EventDetailsViewModel) and encoded/decoded directly
// to/from the `segments` array field on the Firestore event document.
// Previously split into RunSegment (app) + EventSegmentDocument (Firestore).

struct RunSegment: Identifiable, Codable {

	// MARK: - Identity

	/// Stable 0-based index — used as the sort key and display label (S1, S2…).
	let id: Int  // maps to Firestore field "index" via CodingKeys

	// MARK: - Plan (set when the event is created)

	/// Planned segment distance. Double matches Firestore precision; UI formats to 2 d.p.
	var distance: Double

	/// Hour component of the planned goal time — used by the UI time picker.
	var goalHours: Int

	/// Minute component of the planned goal time — used by the UI time picker.
	var goalMinutes: Int

	/// Second component of the planned goal time — used by the UI time picker.
	var goalSeconds: Int

	// MARK: - Completion (populated by watch sync after the event finishes)

	/// UTC timestamp when this segment was completed — nil for planned/active segments.
	var completedAt: Date?

	/// Actual elapsed seconds for this segment — nil until the segment is completed.
	var actualTimeSeconds: Int?

	// MARK: - Computed UI Helpers

	/// Formatted goal time string "HH:MM:SS" — used in segment list rows.
	var formattedGoalTime: String {
		String(format: "%02d:%02d:%02d", goalHours, goalMinutes, goalSeconds)
	}

	/// Total goal seconds derived from the H/M/S components.
	var totalGoalSeconds: Int {
		(goalHours * 3600) + (goalMinutes * 60) + goalSeconds
	}

	// MARK: - Codable
	//
	// CodingKeys maps the app-layer field names to the Firestore document shape.
	// "id" on the app side encodes as "index" in Firestore.
	// goalHours/Minutes/Seconds are app-only — Firestore stores goalTimeSeconds.

	enum CodingKeys: String, CodingKey {
		case id = "index"
		case distance, completedAt, actualTimeSeconds
		case goalTimeSeconds  // Firestore canonical seconds — derived on encode, split on decode
	}

	init(id: Int, distance: Double, goalHours: Int, goalMinutes: Int, goalSeconds: Int,
		 completedAt: Date? = nil, actualTimeSeconds: Int? = nil) {
		self.id = id
		self.distance = distance
		self.goalHours = goalHours
		self.goalMinutes = goalMinutes
		self.goalSeconds = goalSeconds
		self.completedAt = completedAt
		self.actualTimeSeconds = actualTimeSeconds
	}

	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		id           = (try? c.decode(Int.self, forKey: .id)) ?? 0
		distance     = (try? c.decode(Double.self, forKey: .distance)) ?? 0
		completedAt  = try? c.decode(Date.self, forKey: .completedAt)
		actualTimeSeconds = try? c.decode(Int.self, forKey: .actualTimeSeconds)

		// Expand goalTimeSeconds → H/M/S components for the UI pickers.
		let total    = (try? c.decode(Int.self, forKey: .goalTimeSeconds)) ?? 0
		goalHours    = total / 3600
		goalMinutes  = (total % 3600) / 60
		goalSeconds  = total % 60
	}

	func encode(to encoder: Encoder) throws {
		var c = encoder.container(keyedBy: CodingKeys.self)
		try c.encode(id,               forKey: .id)
		try c.encode(distance,         forKey: .distance)
		try c.encode(totalGoalSeconds, forKey: .goalTimeSeconds)  // collapse H/M/S → seconds
		try c.encodeIfPresent(completedAt,        forKey: .completedAt)
		try c.encodeIfPresent(actualTimeSeconds,  forKey: .actualTimeSeconds)
	}
}
