//
//  GaitUserData.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import Foundation

// MARK: - GaitUserData
//
// Top-level container holding gait data for both walking and running.
// Encodes/decodes as a flat map matching the Firestore `gait` nested document:
//   { walkingStepLength, walkingUnit, runningStepLength, runningUnit }

struct GaitUserData: Codable, Equatable {
	var walkingData: GaitData
	var runningData: GaitData

	// MARK: - Codable (flat Firestore shape)

	enum CodingKeys: String, CodingKey {
		case walkingStepLength, walkingUnit
		case runningStepLength, runningUnit
	}

	init(walkingData: GaitData, runningData: GaitData) {
		self.walkingData = walkingData
		self.runningData = runningData
	}

	init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		walkingData = GaitData(
			stepLength: (try? c.decode(Double.self, forKey: .walkingStepLength)) ?? 0,
			unit:       (try? c.decode(String.self, forKey: .walkingUnit)) ?? "Feet"
		)
		runningData = GaitData(
			stepLength: (try? c.decode(Double.self, forKey: .runningStepLength)) ?? 0,
			unit:       (try? c.decode(String.self, forKey: .runningUnit)) ?? "Feet"
		)
	}

	func encode(to encoder: Encoder) throws {
		var c = encoder.container(keyedBy: CodingKeys.self)
		try c.encode(walkingData.stepLength, forKey: .walkingStepLength)
		try c.encode(walkingData.unit,       forKey: .walkingUnit)
		try c.encode(runningData.stepLength, forKey: .runningStepLength)
		try c.encode(runningData.unit,       forKey: .runningUnit)
	}
}

// MARK: - GaitData

/// Stores the step length and unit for a single gait type (e.g. Walking / Running).
struct GaitData: Codable, Equatable {
	var stepLength: Double
	var unit: String  // "Meters" or "Feet"
}
