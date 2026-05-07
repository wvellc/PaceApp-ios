//
//  CreateEventViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//


// MARK: - EventViewModels.swift
// MVVM ViewModels for both flows.
//
//  ┌─────────────────────────────────────┐
//  │   CreateEventViewModel              │  ← owns CreateEventDraft
//  │   EventListViewModel                │  ← queries completed events
//  │   EventDetailViewModel              │  ← single event detail
//  │   ActiveEventViewModel              │  ← live/active event monitoring
//  └─────────────────────────────────────┘

import Foundation
import SwiftData
import Observation
import SwiftUI

// ─────────────────────────────────────────────
// MARK: CreateEventViewModel
// ─────────────────────────────────────────────

@Observable
@MainActor
final class CreateEventViewModel {

    var draft = CreateEventDraft()
    var isSaving = false
    var saveError: String?
    var didSaveSuccessfully = false

    private let modelContext: ModelContext
    private let syncService: EventSyncService

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.syncService  = EventSyncService(modelContext: modelContext)
        prefillFromDeviceSettings()
    }

    // MARK: Actions

    func save() async {
        guard draft.isValid else {
            saveError = "Please fill in all required fields."
            return
        }

        isSaving = true
        saveError = nil

        do {
            let event = draft.toAppEvent()
            event.syncStatus = SyncStatus.pending.rawValue
            modelContext.insert(event)
            try modelContext.save()
            didSaveSuccessfully = true
            draft.reset()
        } catch {
            saveError = "Failed to save event: \(error.localizedDescription)"
        }

        isSaving = false
    }

    func updateIntervals(to count: Int) {
        draft.intervals = max(1, count)
    }

    func addCustomSegment() {
        let seg = DraftSegment(
            index:      draft.customSegments.count,
            distance:   0,
            etaSeconds: 0,
            measure:    draft.measure
        )
        draft.customSegments.append(seg)
    }

    func removeCustomSegment(at offsets: IndexSet) {
        draft.customSegments.remove(atOffsets: offsets)
    }

    // MARK: Private

    private func prefillFromDeviceSettings() {
        let descriptor = FetchDescriptor<GarminDeviceSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            draft.prefill(from: settings)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: EventListViewModel
// ─────────────────────────────────────────────

@Observable
@MainActor
final class EventListViewModel {

    var events: [AppEvent] = []
    var sortOrder: EventSortOrder = .dateDescending
    var searchText: String = ""
    var selectedActivity: ActivityType? = nil
    var isLoading: Bool = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadEvents()
    }

    // MARK: Load / filter

    func loadEvents() {
        let descriptor = EventSyncService.completedEventDescriptor(sortBy: sortOrder)
        events = (try? modelContext.fetch(descriptor)) ?? []
    }

    var filteredEvents: [AppEvent] {
        events.filter { event in
            let matchesSearch = searchText.isEmpty
                || event.name.localizedCaseInsensitiveContains(searchText)
                || (event.location ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesActivity = selectedActivity == nil
                || event.activity == selectedActivity
            return matchesSearch && matchesActivity
        }
    }

    // MARK: Statistics

    var totalDistance: Double {
        filteredEvents.reduce(0) { $0 + ($1.actualDistRaw ?? $1.distanceRaw) }
    }

    var totalEvents: Int { filteredEvents.count }

    var averageHeartRate: Int? {
        let rates = filteredEvents.compactMap(\.avgHeartRate)
        guard !rates.isEmpty else { return nil }
        return rates.reduce(0, +) / rates.count
    }

    func setSortOrder(_ order: EventSortOrder) {
        sortOrder = order
        loadEvents()
    }
}

// ─────────────────────────────────────────────
// MARK: EventDetailViewModel
// ─────────────────────────────────────────────

@Observable
@MainActor
final class EventDetailViewModel {

    let event: AppEvent
    var showAllSegments: Bool = false

    init(event: AppEvent) {
        self.event = event
    }

    // MARK: Computed display data

    var summaryStats: [StatItem] {
        var stats: [StatItem] = []

        stats.append(StatItem(
            label: "Distance",
            value: event.formattedActualDistance,
            secondary: "Goal: \(event.formattedDistance)",
            icon: "ruler"
        ))

        stats.append(StatItem(
            label: "Time",
            value: event.formattedActualTime,
            secondary: "Goal: \(event.formattedGoal)",
            icon: "clock"
        ))

        if let hr = event.avgHeartRate {
            stats.append(StatItem(
                label: "Avg HR",
                value: "\(hr) bpm",
                secondary: event.heartRateZone?.label,
                icon: "heart.fill"
            ))
        }

        if let best = event.bestPace {
            stats.append(StatItem(
                label: "Best Pace",
                value: best,
                secondary: nil,
                icon: "speedometer"
            ))
        }

        return stats
    }

    var segmentsToShow: [CompletedSegment] {
        let all = event.completedSegments
        return showAllSegments ? all : Array(all.prefix(3))
    }

    var hasMoreSegments: Bool {
        event.completedSegments.count > 3 && !showAllSegments
    }

    var progressColor: Color {
        let pct = event.distanceProgress
        switch pct {
        case ..<0.5:  return .red
        case 0.5..<0.8: return .orange
        default:      return .green
        }
    }
}

// MARK: StatItem helper

struct StatItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let secondary: String?
    let icon: String
}

// ─────────────────────────────────────────────
// MARK: ActiveEventViewModel
// ─────────────────────────────────────────────

@Observable
@MainActor
final class ActiveEventViewModel {

    var activeEvents: [AppEvent] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadActiveEvents()
    }

    func loadActiveEvents() {
        let descriptor = EventSyncService.activeEventDescriptor()
        activeEvents = (try? modelContext.fetch(descriptor)) ?? []
    }

    var hasActiveEvents: Bool { !activeEvents.isEmpty }

    var currentEvent: AppEvent? { activeEvents.first }
}
