//
//  ActivityType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//


// MARK: - AppEnums.swift
// Centralized enums for both Create Event and View Event flows
// Some enums are shared; flow-specific ones are clearly marked.

import Foundation
import SwiftUI

// ─────────────────────────────────────────────
// MARK: Shared – used by BOTH Create & View flows
// ─────────────────────────────────────────────

/// Alert / notification style from Garmin settings
enum AlertStyle: String, Codable, CaseIterable {
    case vibrate = "vibrate"
    case beep    = "beep"
    case both    = "both"
    case none    = "none"

    /// Build from raw Garmin booleans
    init(vibrate: Bool, beep: Bool) {
        switch (vibrate, beep) {
        case (true, true):   self = .both
        case (true, false):  self = .vibrate
        case (false, true):  self = .beep
        default:             self = .none
        }
    }

    var vibrateOn: Bool { self == .vibrate || self == .both }
    var beepOn: Bool    { self == .beep    || self == .both }
}

/// Sync / persistence state of a record
enum SyncStatus: String, Codable {
    case synced     = "synced"      // confirmed saved in SwiftData
    case pending    = "pending"     // queued for sync
    case conflict   = "conflict"    // remote & local differ
    case failed     = "failed"      // sync attempt failed
}

// ─────────────────────────────────────────────
// MARK: Create-Event flow enums
// ─────────────────────────────────────────────

/// Goal type when creating a new event
enum GoalType: String, Codable, CaseIterable, Identifiable {
    case duration  = "Duration"
    case distance  = "Distance"
    case calories  = "Calories"
    case openEnded = "Open Ended"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .duration:  return "clock"
        case .distance:  return "ruler"
        case .calories:  return "flame"
        case .openEnded: return "infinity"
        }
    }
}

/// Segment split strategy for a new event
enum SegmentStrategy: String, Codable, CaseIterable, Identifiable {
    case equal     = "Equal"
    case custom    = "Custom"
    case automatic = "Automatic"

    var id: String { rawValue }
}

/// Recurrence rule for scheduled events
enum RecurrenceRule: String, Codable, CaseIterable, Identifiable {
    case never    = "Never"
    case daily    = "Daily"
    case weekly   = "Weekly"
    case monthly  = "Monthly"

    var id: String { rawValue }
}

// ─────────────────────────────────────────────
// MARK: View-Event flow enums
// ─────────────────────────────────────────────

/// Completion status of a synced event
enum EventCompletionStatus: String, Codable {
    case completed   = "completed"
    case inProgress  = "in_progress"
    case skipped     = "skipped"
    case upcoming    = "upcoming"

    var label: String {
        switch self {
        case .completed:  return "Completed"
        case .inProgress: return "In Progress"
        case .skipped:    return "Skipped"
        case .upcoming:   return "Upcoming"
        }
    }

    var color: Color {
        switch self {
        case .completed:  return .green
        case .inProgress: return .orange
        case .skipped:    return .gray
        case .upcoming:   return .blue
        }
    }
}

/// Heart-rate zone derived from avg bpm
enum HeartRateZone: Int, Codable, CaseIterable {
    case zone1 = 1, zone2, zone3, zone4, zone5

    var label: String { "Zone \(rawValue)" }

    var color: Color {
        switch self {
        case .zone1: return .blue
        case .zone2: return .green
        case .zone3: return .yellow
        case .zone4: return .orange
        case .zone5: return .red
        }
    }

    /// Classify by percentage of max heart rate (estimated max = 220 - age)
    static func classify(bpm: Int, maxBpm: Int = 190) -> HeartRateZone {
        let pct = Double(bpm) / Double(maxBpm)
        switch pct {
        case ..<0.60: return .zone1
        case 0.60..<0.70: return .zone2
        case 0.70..<0.80: return .zone3
        case 0.80..<0.90: return .zone4
        default: return .zone5
        }
    }
}

/// Sort order for event list screens
enum EventSortOrder: String, CaseIterable, Identifiable {
    case dateDescending  = "Newest First"
    case dateAscending   = "Oldest First"
    case distanceDesc    = "Longest Distance"
    case durationDesc    = "Longest Duration"

    var id: String { rawValue }
}
