//
//  SyncResult.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//


// MARK: - EventSyncService.swift
// Processes incoming Garmin JSON payloads:
//  1. Validates each event DTO
//  2. Upserts into SwiftData (create new OR update existing by `garminStartAt`)
//  3. Updates GarminDeviceSettings
//  4. Returns a SyncResult with counts + any validation errors

import Foundation
import SwiftData

// ─────────────────────────────────────────────
// MARK: SyncResult
// ─────────────────────────────────────────────

struct SyncResult {
    var created: Int = 0
    var updated: Int = 0
    var skipped: Int = 0
    var errors: [SyncError] = []

    var totalProcessed: Int { created + updated + skipped }
    var hasErrors: Bool { !errors.isEmpty }
}

struct SyncError: Identifiable {
    let id = UUID()
    let eventName: String
    let reason: String
}

// ─────────────────────────────────────────────
// MARK: EventSyncService
// ─────────────────────────────────────────────

@MainActor
final class EventSyncService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // ─────────────────────────────────────
    // MARK: Main entry point
    // ─────────────────────────────────────

    /// Process a raw Garmin JSON Data blob
    func processGarminPayload(_ data: Data) async throws -> SyncResult {
        let decoder = JSONDecoder()
        let payload = try decoder.decode(GarminSyncPayload.self, from: data)
        return try await processPayload(payload)
    }

    /// Process a decoded payload (also used in tests)
    func processPayload(_ payload: GarminSyncPayload) async throws -> SyncResult {
        var result = SyncResult()

        // 1. Sync device settings
        syncSettings(GarminSettings(from: payload))

        // 2. Process completed events
        for dto in payload.completedEvents {
            let err = upsertEvent(dto, isActive: false, result: &result)
            if let e = err { result.errors.append(e) }
        }

        // 3. Process active events
        for dto in payload.activeEvents {
            let err = upsertEvent(dto, isActive: true, result: &result)
            if let e = err { result.errors.append(e) }
        }

        // 4. Persist
        try modelContext.save()

        return result
    }

    // ─────────────────────────────────────
    // MARK: Upsert single event
    // ─────────────────────────────────────

    @discardableResult
    private func upsertEvent(
        _ dto: GarminEventDTO,
        isActive: Bool,
        result: inout SyncResult
    ) -> SyncError? {

        // Validate
        guard let startAt = dto.startAt else {
            result.skipped += 1
            return SyncError(eventName: dto.name ?? "unknown",
                             reason: "Missing startAt timestamp — cannot upsert")
        }

        if let validationError = validate(dto) {
            result.skipped += 1
            return SyncError(eventName: dto.name ?? "unknown", reason: validationError)
        }

        // Fetch existing by unique key
        let predicate = #Predicate<AppEvent> { $0.garminStartAt == startAt }
        let descriptor = FetchDescriptor<AppEvent>(predicate: predicate)

        if let existing = try? modelContext.fetch(descriptor).first {
            // UPDATE
            existing.update(from: dto)
            existing.isActive = isActive
            result.updated += 1
        } else {
            // CREATE
            let event = AppEvent(from: dto, isActive: isActive)
            event.syncStatus    = SyncStatus.synced.rawValue
            event.lastSyncedAt  = Date()
            modelContext.insert(event)
            result.created += 1
        }

        return nil
    }

    // ─────────────────────────────────────
    // MARK: Validation
    // ─────────────────────────────────────

    private func validate(_ dto: GarminEventDTO) -> String? {
        if (dto.name ?? "").isEmpty {
            return "Event name is empty"
        }
        if let distance = dto.distance, distance < 0 {
            return "Distance cannot be negative (\(distance))"
        }
        if let actual = dto.actualDist, actual < 0 {
            return "Actual distance cannot be negative (\(actual))"
        }
        if let hr = dto.avgHeartRate, hr > 300 || hr < 0 {
            return "Heart rate out of range: \(hr)"
        }
        return nil
    }

    // ─────────────────────────────────────
    // MARK: Settings sync
    // ─────────────────────────────────────

    private func syncSettings(_ settings: GarminSettings) {
        let descriptor = FetchDescriptor<GarminDeviceSettings>()

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.update(from: settings)
        } else {
            modelContext.insert(GarminDeviceSettings(from: settings))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: Fetch helpers (used by ViewModels)
// ─────────────────────────────────────────────

extension EventSyncService {

    static func completedEventDescriptor(
        sortBy: EventSortOrder = .dateDescending
    ) -> FetchDescriptor<AppEvent> {

        let predicate = #Predicate<AppEvent> { !$0.isActive }

        var descriptor = FetchDescriptor<AppEvent>(predicate: predicate)

        switch sortBy {
        case .dateDescending:
            descriptor.sortBy = [SortDescriptor(\.garminStartAt, order: .reverse)]
        case .dateAscending:
            descriptor.sortBy = [SortDescriptor(\.garminStartAt)]
        case .distanceDesc:
            descriptor.sortBy = [SortDescriptor(\.distanceRaw, order: .reverse)]
        case .durationDesc:
            descriptor.sortBy = [SortDescriptor(\.garminStartAt, order: .reverse)]
        }

        return descriptor
    }

    static func activeEventDescriptor() -> FetchDescriptor<AppEvent> {
        let predicate = #Predicate<AppEvent> { $0.isActive }
        return FetchDescriptor<AppEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.garminStartAt, order: .reverse)]
        )
    }
}
