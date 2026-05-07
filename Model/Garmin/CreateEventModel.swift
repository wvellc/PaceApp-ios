//
//  so.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//


// MARK: - CreateEventModel.swift
// Transient (non-persistent) model for the Create Event flow.
// Backed by an @Observable class so it lives in the ViewModel layer.
// When the user saves, this is converted → AppEvent via EventSyncService.

import Foundation
import SwiftUI
import Observation

// ─────────────────────────────────────────────
// MARK: CreateEventDraft (Observable, NOT SwiftData)
// ─────────────────────────────────────────────

@Observable
final class CreateEventDraft {

    // MARK: Basic info
    var name: String            = ""
    var activity: ActivityType  = .cycle
    var location: String        = ""
    var date: Date              = Date()

    // MARK: Goal
    var goalType: GoalType      = .duration
    var goalDuration: TimeInterval = 3 * 3600   // 3 hours in seconds
    var goalDistance: Double    = 0.0
    var goalCalories: Int       = 0
    var measure: MeasureUnit    = .miles

    // MARK: Segments
    var segmentStrategy: SegmentStrategy = .equal
    var intervals: Int          = 1
    var customSegments: [DraftSegment] = []

    // MARK: Alerts
    var vibrateAlert: Bool      = true
    var beepAlert: Bool         = true

    // MARK: Recurrence
    var recurrence: RecurrenceRule = .never

    // MARK: Gait (pre-filled from device settings if available)
    var runningGait: Double     = 0
    var runningGaitMeasure: MeasureUnit = .feet
    var walkingGait: Double     = 0
    var walkingGaitMeasure: MeasureUnit = .feet

    // ─────────────────────────────────────
    // MARK: Computed
    // ─────────────────────────────────────

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && hasValidGoal
    }

    var hasValidGoal: Bool {
        switch goalType {
        case .duration:  return goalDuration > 0
        case .distance:  return goalDistance > 0
        case .calories:  return goalCalories > 0
        case .openEnded: return true
        }
    }

    var goalDisplayString: String {
        switch goalType {
        case .duration:
            return TimeFormatter.toString(seconds: Int(goalDuration))
        case .distance:
            return String(format: "%.2f %@", goalDistance, measure.shortLabel)
        case .calories:
            return "\(goalCalories) kcal"
        case .openEnded:
            return "Open Ended"
        }
    }

    var alertStyle: AlertStyle {
        AlertStyle(vibrate: vibrateAlert, beep: beepAlert)
    }

    /// Computed equal segments from goal distance + interval count
    var computedSegments: [DraftSegment] {
        guard intervals > 0 else { return [] }
        switch segmentStrategy {
        case .equal:
            let segDist = goalDistance / Double(intervals)
            let segETA  = goalDuration / Double(intervals)
            return (0..<intervals).map { i in
                DraftSegment(
                    index:       i,
                    distance:    segDist,
                    etaSeconds:  Int(segETA),
                    measure:     measure
                )
            }
        case .custom:
            return customSegments
        case .automatic:
            return [] // Garmin watch decides
        }
    }

    // ─────────────────────────────────────
    // MARK: Prefill from device settings
    // ─────────────────────────────────────

    func prefill(from settings: GarminDeviceSettings) {
        runningGait        = settings.runningGait
        runningGaitMeasure = settings.runningGaitMeasure
        walkingGait        = settings.walkingGait
        walkingGaitMeasure = settings.walkingGaitMeasure
        vibrateAlert       = settings.vibrateAlert
        beepAlert          = settings.beepAlert
    }

    // ─────────────────────────────────────
    // MARK: Reset
    // ─────────────────────────────────────

    func reset() {
        name             = ""
        activity         = .cycle
        location         = ""
        date             = Date()
        goalType         = .duration
        goalDuration     = 3 * 3600
        goalDistance     = 0
        goalCalories     = 0
        measure          = .miles
        segmentStrategy  = .equal
        intervals        = 1
        customSegments   = []
        vibrateAlert     = true
        beepAlert        = true
        recurrence       = .never
    }
}

// ─────────────────────────────────────────────
// MARK: DraftSegment (transient)
// ─────────────────────────────────────────────

struct DraftSegment: Identifiable {
    let id: UUID         = UUID()
    var index: Int
    var distance: Double
    var etaSeconds: Int
    var measure: MeasureUnit

    var formattedETA: String {
        TimeFormatter.toString(seconds: etaSeconds)
    }

    var formattedDistance: String {
        String(format: "%.2f %@", distance, measure.shortLabel)
    }
}

// ─────────────────────────────────────────────
// MARK: Conversion: Draft → AppEvent
// ─────────────────────────────────────────────

extension CreateEventDraft {

    /// Convert draft to a saveable AppEvent (used before pushing to Garmin / saving offline)
    func toAppEvent() -> AppEvent {
        let dto = GarminEventDTO(
            date:              DateFormatter.garminString(from: date),
            name:              name,
            activity:          activity.rawValue,
            distance:          goalType == .distance ? goalDistance : nil,
            measure:           measure.garminRawValue,
            goal:              goalType == .duration ? TimeFormatter.toString(seconds: Int(goalDuration)) : nil,
            intervals:         intervals,
            segmentCount:      computedSegments.count,
            segments:          computedSegments.map {
                GarminSegmentDTO(eta: TimeFormatter.toString(seconds: $0.etaSeconds),
                                 distance: $0.distance)
            },
            actualTime:        nil,
            actualDist:        nil,
            avgHeartRate:      nil,
            paces:             nil,
            location:          location.isEmpty ? nil : location,
            timeVar:           nil,
            startAt:           date.timeIntervalSince1970,
            stopAt:            nil,
            completedSegments: nil
        )
        return AppEvent(from: dto, isActive: true)
    }
}

// ─────────────────────────────────────────────
// MARK: DateFormatter helper
// ─────────────────────────────────────────────

private extension DateFormatter {
    static func garminString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM/d/yyyy"
        return f.string(from: date)
    }
}
