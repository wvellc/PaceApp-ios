//
//  GarminSyncPayload.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//


// MARK: - GarminPayload.swift
// Raw Decodable DTOs that mirror the exact Garmin JSON structure.
// These are NEVER stored directly — they are transformed into SwiftData models.
//
// Garmin JSON fields observed (from debug screenshot):
//   running_gait_measure, running_gait, vibrate_alert, beep_alert,
//   walking_gait, walking_gait_measure
//   completedEvents[] each containing:
//     date, name, activity, distance, measure, goal, intervals,
//     segmentCount, segments[], actualTime, actualDist, avgHeartRate,
//     paces[], location, timeVar, startAt, stopAt,
//     completedSegments[], activeEvents[]

import Foundation

// ─────────────────────────────────────────────
// MARK: Root payload
// ─────────────────────────────────────────────

struct GarminSyncPayload: Decodable {
    // Global settings
    let runningGaitMeasure: String?     // "ft"
    let runningGait: Double?            // 5.5
    let vibrateAlert: Bool?             // true
    let beepAlert: Bool?                // true
    let walkingGait: Double?            // 2.4
    let walkingGaitMeasure: String?     // "ft"

    // Events
    let completedEvents: [GarminEventDTO]
    let activeEvents: [GarminEventDTO]

    enum CodingKeys: String, CodingKey {
        case runningGaitMeasure  = "running_gait_measure"
        case runningGait         = "running_gait"
        case vibrateAlert        = "vibrate_alert"
        case beepAlert           = "beep_alert"
        case walkingGait         = "walking_gait"
        case walkingGaitMeasure  = "walking_gait_measure"
        case completedEvents     = "completedEvents"
        case activeEvents        = "activeEvents"
    }
}

// ─────────────────────────────────────────────
// MARK: Event DTO
// ─────────────────────────────────────────────

struct GarminEventDTO: Decodable {
    let date: String?               // "May/6/2026"
    let name: String?               // "Cycle"
    let activity: String?           // "Cycle"
    let distance: Double?           // 2.02
    let measure: String?            // "Miles"
    let goal: String?               // "03:00:00"
    let intervals: Int?             // 2
    let segmentCount: Int?          // 2
    let segments: [GarminSegmentDTO]?
    let actualTime: String?         // "00:15:30"
    let actualDist: Double?         // 2.2
    let avgHeartRate: Int?          // 156
    let paces: [Int]?               // [442, 423, 65]
    let location: String?           // "Planet Earth"
    let timeVar: String?            // "-02:44:30"
    let startAt: TimeInterval?      // 1778066645
    let stopAt: TimeInterval?       // 1778067575
    let completedSegments: [GarminCompletedSegmentDTO]?

    enum CodingKeys: String, CodingKey {
        case date, name, activity, distance, measure, goal
        case intervals, segmentCount, segments
        case actualTime   = "actualTime"
        case actualDist   = "actualDist"
        case avgHeartRate = "avgHeartRate"
        case paces, location, timeVar
        case startAt      = "startAt"
        case stopAt       = "stopAt"
        case completedSegments = "completedSegments"
    }
}

// ─────────────────────────────────────────────
// MARK: Segment DTOs
// ─────────────────────────────────────────────

/// Planned segment: { eta: "01:30:00", distance: 1.01 }
struct GarminSegmentDTO: Decodable {
    let eta: String?        // "01:30:00"
    let distance: Double?   // 1.01
}

/// Completed segment with actual performance
struct GarminCompletedSegmentDTO: Decodable {
    let eta: String?                // "01:30:00"
    let completedDistance: Double?  // 1.01
    let distance: Double?           // 1.01
    let elapsedTime: String?        // "00:07:29"

    enum CodingKeys: String, CodingKey {
        case eta
        case completedDistance = "completed_distance"
        case distance
        case elapsedTime       = "elapsed_time"
    }
}

// ─────────────────────────────────────────────
// MARK: Garmin Settings DTO (top-level keys)
// ─────────────────────────────────────────────

struct GarminSettings {
    let runningGait: Double
    let runningGaitMeasure: MeasureUnit
    let walkingGait: Double
    let walkingGaitMeasure: MeasureUnit
    let alertStyle: AlertStyle

    init(from payload: GarminSyncPayload) {
        runningGait        = payload.runningGait ?? 0
        runningGaitMeasure = MeasureUnit(rawValue: payload.runningGaitMeasure ?? "ft") ?? .feet
        walkingGait        = payload.walkingGait ?? 0
        walkingGaitMeasure = MeasureUnit(rawValue: payload.walkingGaitMeasure ?? "ft") ?? .feet
        alertStyle         = AlertStyle(
            vibrate: payload.vibrateAlert ?? false,
            beep:    payload.beepAlert    ?? false
        )
    }
}
