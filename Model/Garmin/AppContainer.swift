//
//  AppContainer.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//


// MARK: - AppContainer.swift
// SwiftData schema registration and ModelContainer setup.
// Import this as the single source for the container throughout the app.

import SwiftData
import SwiftUI

// ─────────────────────────────────────────────
// MARK: Schema
// ─────────────────────────────────────────────

extension Schema {
    /// All SwiftData models registered in the app — add new models here ONLY.
    static var appSchema: Schema {
        Schema([
            AppEvent.self,
            PlannedSegment.self,
            CompletedSegment.self,
            GarminDeviceSettings.self
        ])
    }
}

// ─────────────────────────────────────────────
// MARK: ModelContainer factory
// ─────────────────────────────────────────────

struct AppContainer {

    static var shared: ModelContainer = {
        let config = ModelConfiguration(
            schema: Schema.appSchema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: Schema.appSchema, configurations: config)
        } catch {
            fatalError("SwiftData container failed to initialize: \(error)")
        }
    }()

    /// In-memory container for SwiftUI Previews and unit tests
    static var preview: ModelContainer = {
        let config = ModelConfiguration(
            schema: Schema.appSchema,
            isStoredInMemoryOnly: true
        )
        do {
            let container = try ModelContainer(for: Schema.appSchema, configurations: config)
            // Insert sample data for previews
            let context = ModelContext(container)
            PreviewData.insertSamples(into: context)
            return container
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }()
}

// ─────────────────────────────────────────────
// MARK: Preview sample data
// ─────────────────────────────────────────────

enum PreviewData {

    static func insertSamples(into context: ModelContext) {
        let dto = GarminEventDTO(
            date:        "May/6/2026",
            name:        "Cycle",
            activity:    "Cycle",
            distance:    2.02,
            measure:     "Miles",
            goal:        "03:00:00",
            intervals:   2,
            segmentCount: 2,
            segments:    [
                GarminSegmentDTO(eta: "01:30:00", distance: 1.01),
                GarminSegmentDTO(eta: "01:30:00", distance: 1.01)
            ],
            actualTime:  "00:15:30",
            actualDist:  2.2,
            avgHeartRate: 156,
            paces:       [442, 423, 65],
            location:    "Planet Earth",
            timeVar:     "-02:44:30",
            startAt:     1778066645,
            stopAt:      1778067575,
            completedSegments: [
                GarminCompletedSegmentDTO(
                    eta: "01:30:00",
                    completedDistance: 1.01,
                    distance: 1.01,
                    elapsedTime: "00:07:29"
                ),
                GarminCompletedSegmentDTO(
                    eta: "01:30:00",
                    completedDistance: 1.14,
                    distance: 1.01,
                    elapsedTime: "00:07:11"
                )
            ]
        )
        let event = AppEvent(from: dto, isActive: false)
        event.syncStatus   = SyncStatus.synced.rawValue
        event.lastSyncedAt = Date()
        context.insert(event)

        let settings = GarminDeviceSettings(from: GarminSettings(from: GarminSyncPayload(
            runningGaitMeasure: "ft",
            runningGait: 5.5,
            vibrateAlert: true,
            beepAlert: true,
            walkingGait: 2.4,
            walkingGaitMeasure: "ft",
            completedEvents: [],
            activeEvents: []
        )))
        context.insert(settings)

        try? context.save()
    }
}
