//
//  covers.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//


// MARK: - AppEvent.swift
// SwiftData persistent model — single source of truth for all event data.
// Stores BOTH the raw Garmin values AND pre-computed display properties.
//
// Design decisions:
//  • One @Model class covers completed + active events (discriminated by `isActive`)
//  • Segments stored as child @Model so they can be queried independently
//  • All display-formatted strings are computed, NOT stored (saves space, always fresh)
//  • `garminStartAt` (Unix timestamp) is the natural unique key for upsert logic

import Foundation
import SwiftData
import SwiftUI

// ─────────────────────────────────────────────
// MARK: AppEvent (root persistent model)
// ─────────────────────────────────────────────

@Model
final class AppEvent {

    // MARK: Identity / sync
    @Attribute(.unique) var garminStartAt: TimeInterval   // Unix ts — used as upsert key
    var garminStopAt: TimeInterval?
    var syncStatus: String = SyncStatus.pending.rawValue   // stored as String for SwiftData
    var lastSyncedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: Core fields (raw values from Garmin)
    var name: String
    var activityRaw: String          // "Cycle", "Run", etc.
    var dateString: String           // "May/6/2026" — raw from Garmin
    var distanceRaw: Double          // 2.02 (in `measureRaw` units)
    var measureRaw: String           // "Miles"
    var goalString: String?          // "03:00:00"
    var intervals: Int               // 2
    var segmentCount: Int            // 2
    var location: String?            // "Planet Earth"

    // MARK: Actual performance (raw)
    var actualTimeString: String?    // "00:15:30"
    var actualDistRaw: Double?       // 2.2
    var avgHeartRate: Int?           // 156
    var pacesRaw: [Int]              // [442, 423, 65] — seconds per unit
    var timeVarString: String?       // "-02:44:30"

    // MARK: Relationships
    @Relationship(deleteRule: .cascade) var plannedSegments: [PlannedSegment]
    @Relationship(deleteRule: .cascade) var completedSegments: [CompletedSegment]

    // MARK: Flags
    var isActive: Bool               // false = completed event

    // ─────────────────────────────────────
    // MARK: Init from GarminEventDTO
    // ─────────────────────────────────────

    init(from dto: GarminEventDTO, isActive: Bool = false) {
        self.garminStartAt      = dto.startAt ?? Date().timeIntervalSince1970
        self.garminStopAt       = dto.stopAt
        self.name               = dto.name ?? "Unknown"
        self.activityRaw        = dto.activity ?? "Other"
        self.dateString         = dto.date ?? ""
        self.distanceRaw        = dto.distance ?? 0
        self.measureRaw         = dto.measure ?? "Miles"
        self.goalString         = dto.goal
        self.intervals          = dto.intervals ?? 1
        self.segmentCount       = dto.segmentCount ?? 0
        self.location           = dto.location
        self.actualTimeString   = dto.actualTime
        self.actualDistRaw      = dto.actualDist
        self.avgHeartRate       = dto.avgHeartRate
        self.pacesRaw           = dto.paces ?? []
        self.timeVarString      = dto.timeVar
        self.isActive           = isActive
        self.plannedSegments    = dto.segments?.map { PlannedSegment(from: $0) } ?? []
        self.completedSegments  = dto.completedSegments?.map { CompletedSegment(from: $0) } ?? []
    }

    // MARK: Update from new DTO (upsert path)
    func update(from dto: GarminEventDTO) {
        name              = dto.name ?? name
        activityRaw       = dto.activity ?? activityRaw
        dateString        = dto.date ?? dateString
        distanceRaw       = dto.distance ?? distanceRaw
        measureRaw        = dto.measure ?? measureRaw
        goalString        = dto.goal
        intervals         = dto.intervals ?? intervals
        segmentCount      = dto.segmentCount ?? segmentCount
        location          = dto.location
        actualTimeString  = dto.actualTime
        actualDistRaw     = dto.actualDist
        avgHeartRate      = dto.avgHeartRate
        pacesRaw          = dto.paces ?? pacesRaw
        timeVarString     = dto.timeVar
        garminStopAt      = dto.stopAt
        syncStatus        = SyncStatus.synced.rawValue
        updatedAt         = Date()
        lastSyncedAt      = Date()

        // Replace segments
        plannedSegments   = dto.segments?.map { PlannedSegment(from: $0) } ?? []
        completedSegments = dto.completedSegments?.map { CompletedSegment(from: $0) } ?? []
    }
}

// ─────────────────────────────────────────────
// MARK: Computed display properties (View layer)
// ─────────────────────────────────────────────

extension AppEvent {

    // MARK: Typed enums (never fail — always have a fallback)

    var activity: ActivityType {
        ActivityType(rawValue: activityRaw) ?? .other
    }

    var measure: MeasureUnit {
        MeasureUnit(rawValue: measureRaw) ?? .miles
    }

    var syncStatusEnum: SyncStatus {
        SyncStatus(rawValue: syncStatus) ?? .pending
    }

    var completionStatus: EventCompletionStatus {
        guard !isActive else { return .inProgress }
        guard actualTimeString != nil else { return .skipped }
        return .completed
    }

    var heartRateZone: HeartRateZone? {
        guard let bpm = avgHeartRate else { return nil }
        return HeartRateZone.classify(bpm: bpm)
    }

    // MARK: Dates

    /// Parsed start date from Unix timestamp
    var startDate: Date {
        Date(timeIntervalSince1970: garminStartAt)
    }

    /// Parsed stop date from Unix timestamp
    var stopDate: Date? {
        garminStopAt.map { Date(timeIntervalSince1970: $0) }
    }

    /// Human-readable date string e.g. "May 6, 2026"
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startDate)
    }

    /// Short time e.g. "9:17 AM"
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: startDate)
    }

    // MARK: Duration / time

    /// Actual elapsed duration in seconds
    var actualDurationSeconds: Int? {
        guard let timeStr = actualTimeString else { return nil }
        return TimeFormatter.toSeconds(from: timeStr)
    }

    /// Goal duration in seconds
    var goalDurationSeconds: Int? {
        guard let g = goalString else { return nil }
        return TimeFormatter.toSeconds(from: g)
    }

    /// Time variance in seconds (positive = ahead, negative = behind)
    var timeVarianceSeconds: Int? {
        guard let tStr = timeVarString else { return nil }
        return TimeFormatter.toSeconds(from: tStr)
    }

    /// Formatted actual time e.g. "15:30"
    var formattedActualTime: String {
        actualTimeString ?? "--:--"
    }

    /// Formatted goal e.g. "3:00:00"
    var formattedGoal: String {
        goalString ?? "--"
    }

    /// Time variance label e.g. "+2:44:30 ahead" or "-0:05:00 behind"
    var timeVarianceLabel: String {
        guard let secs = timeVarianceSeconds else { return "—" }
        let abs = Swift.abs(secs)
        let h = abs / 3600
        let m = (abs % 3600) / 60
        let s = abs % 60
        let sign = secs >= 0 ? "+" : "-"
        let formatted = h > 0
            ? String(format: "%@%d:%02d:%02d", sign, h, m, s)
            : String(format: "%@%d:%02d", sign, m, s)
        return secs >= 0 ? "\(formatted) ahead" : "\(formatted) behind"
    }

    // MARK: Distance

    /// Formatted planned distance e.g. "2.02 mi"
    var formattedDistance: String {
        String(format: "%.2f %@", distanceRaw, measure.shortLabel)
    }

    /// Formatted actual distance e.g. "2.2 mi"
    var formattedActualDistance: String {
        guard let d = actualDistRaw else { return "—" }
        return String(format: "%.2f %@", d, measure.shortLabel)
    }

    /// Distance completion percentage (0–1)
    var distanceProgress: Double {
        guard distanceRaw > 0, let actual = actualDistRaw else { return 0 }
        return min(actual / distanceRaw, 1.0)
    }

    // MARK: Heart rate

    var formattedHeartRate: String {
        guard let hr = avgHeartRate else { return "—" }
        return "\(hr) bpm"
    }

    // MARK: Pace

    /// Formatted paces array as readable strings e.g. ["7:22/mi", "7:03/mi"]
    var formattedPaces: [String] {
        pacesRaw.map { secs in
            let m = secs / 60
            let s = secs % 60
            return String(format: "%d:%02d/%@", m, s, measure.shortLabel)
        }
    }

    /// Best (fastest) pace
    var bestPace: String? {
        guard let fastest = pacesRaw.min() else { return nil }
        let m = fastest / 60; let s = fastest % 60
        return String(format: "%d:%02d/%@", m, s, measure.shortLabel)
    }

    // MARK: Segment helpers

    var hasSegments: Bool { !plannedSegments.isEmpty }

    var completedSegmentCount: Int { completedSegments.count }

    var segmentCompletionRate: Double {
        guard segmentCount > 0 else { return 0 }
        return Double(completedSegmentCount) / Double(segmentCount)
    }
}

// ─────────────────────────────────────────────
// MARK: PlannedSegment
// ─────────────────────────────────────────────

@Model
final class PlannedSegment {
    var etaString: String?      // "01:30:00"
    var distance: Double        // 1.01

    init(from dto: GarminSegmentDTO) {
        self.etaString = dto.eta
        self.distance  = dto.distance ?? 0
    }

    var formattedETA: String { etaString ?? "—" }
    var formattedDistance: String { String(format: "%.2f", distance) }
}

// ─────────────────────────────────────────────
// MARK: CompletedSegment
// ─────────────────────────────────────────────

@Model
final class CompletedSegment {
    var etaString: String?              // "01:30:00"
    var completedDistance: Double       // 1.01
    var plannedDistance: Double         // 1.01
    var elapsedTimeString: String?      // "00:07:29"

    init(from dto: GarminCompletedSegmentDTO) {
        self.etaString         = dto.eta
        self.completedDistance = dto.completedDistance ?? 0
        self.plannedDistance   = dto.distance ?? 0
        self.elapsedTimeString = dto.elapsedTime
    }

    // Computed
    var formattedElapsedTime: String { elapsedTimeString ?? "—" }

    var completionRate: Double {
        guard plannedDistance > 0 else { return 0 }
        return min(completedDistance / plannedDistance, 1.0)
    }

    var elapsedSeconds: Int? {
        guard let t = elapsedTimeString else { return nil }
        return TimeFormatter.toSeconds(from: t)
    }
}

// ─────────────────────────────────────────────
// MARK: GarminDeviceSettings (persistent)
// ─────────────────────────────────────────────

@Model
final class GarminDeviceSettings {
    @Attribute(.unique) var id: String = "device_settings"
    var runningGait: Double
    var runningGaitMeasureRaw: String
    var walkingGait: Double
    var walkingGaitMeasureRaw: String
    var vibrateAlert: Bool
    var beepAlert: Bool
    var lastSyncedAt: Date?

    init(from settings: GarminSettings) {
        runningGait            = settings.runningGait
        runningGaitMeasureRaw  = settings.runningGaitMeasure.rawValue
        walkingGait            = settings.walkingGait
        walkingGaitMeasureRaw  = settings.walkingGaitMeasure.rawValue
        vibrateAlert           = settings.alertStyle.vibrateOn
        beepAlert              = settings.alertStyle.beepOn
        lastSyncedAt           = Date()
    }

    func update(from settings: GarminSettings) {
        runningGait            = settings.runningGait
        runningGaitMeasureRaw  = settings.runningGaitMeasure.rawValue
        walkingGait            = settings.walkingGait
        walkingGaitMeasureRaw  = settings.walkingGaitMeasure.rawValue
        vibrateAlert           = settings.alertStyle.vibrateOn
        beepAlert              = settings.alertStyle.beepOn
        lastSyncedAt           = Date()
    }

    // Typed accessors
    var runningGaitMeasure: MeasureUnit {
        MeasureUnit(rawValue: runningGaitMeasureRaw) ?? .feet
    }
    var walkingGaitMeasure: MeasureUnit {
        MeasureUnit(rawValue: walkingGaitMeasureRaw) ?? .feet
    }
    var alertStyle: AlertStyle {
        AlertStyle(vibrate: vibrateAlert, beep: beepAlert)
    }
}
