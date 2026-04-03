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
    var goalMinutes: Int
    var goalSeconds: Int

    var formattedGoalTime: String {
        String(format: "%02d:%02d", goalMinutes, goalSeconds)
    }

    var totalGoalSeconds: Int {
        goalMinutes * 60 + goalSeconds
    }
}
