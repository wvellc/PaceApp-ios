//
//  GaitUserData.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import Foundation


// MARK: - Data Models

/// Top-level container holding gait data for both walking and running.
struct GaitUserData: Identifiable, Codable {
	var id = UUID()
	var walkingData: GaitData
	var runningData: GaitData
	
	enum CodingKeys: String, CodingKey {
		case id, walkingData, runningData
	}
}

/// Stores the step length and unit for a single gait type.
struct GaitData: Identifiable, Codable {
	var id = UUID()
	var stepLength: Double
	var unit: String  // e.g. "Meters" or "Feet"
	
	enum CodingKeys: String, CodingKey {
		case id, stepLength, unit
	}
}
