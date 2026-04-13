//
//  RunSegment.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

import Foundation

// MARK: - Segment Model
struct RunSegment: Identifiable {
    let id: Int
    var distance: Double
	var goalHours: Int
    var goalMinutes: Int
    var goalSeconds: Int

    var formattedGoalTime: String {
        String(format: "%02d:%02d:%02d", goalHours, goalMinutes, goalSeconds)
    }

    var totalGoalSeconds: Int {
		(goalHours * 3600) + (goalMinutes * 60) + goalSeconds
    }
}
