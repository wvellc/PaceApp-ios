//
//  GaitUserData.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import Foundation

// MARK: - GaitUserData

/// Top-level container holding gait data for both walking and running.
struct GaitUserData: Codable, Equatable {
	var walkingData: GaitData
	var runningData: GaitData
}

// MARK: - GaitData

/// Stores the step length and unit for a single gait type (e.g. Walking / Running).
struct GaitData: Codable, Equatable {
	var stepLength: Double
	var unit: String  // "Meters" or "Feet"
}
