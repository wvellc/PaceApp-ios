//
//  HomeViewModel.swift
//  PaceApp
//

import SwiftUI

// MARK: - Home View Model

@MainActor
@Observable
final class HomeViewModel {

	// MARK: - Metrics

	/// Header metric capsules, derived from the latest completed event's real,
	/// watch-sourced values. Empty when there is no completed event yet — the
	/// Home screen then hides the metric row entirely.
	var metrics: [HomeMetric] = []
	var showMetricPopup: Bool = false
	var selectedMetricIndex: Int = 0

	// MARK: - Events

	var upcomingEvents: [ActivityData] = []
	var isLoadingEvents: Bool = false

	// MARK: - Private

	private let eventRepository: EventRepositoryProtocol
	nonisolated(unsafe) private var activeEventsListener: ListenerRegistrationToken?

	/// Guards against redundant re-attaches when .task(id:) re-fires with the same userId.
	private var activeListenerUserId: String?

	/// Latest completed event backing the metric capsules — retained so the
	/// flashing capsule can rebuild its alternate face without re-fetching.
	private var latestCompletedEvent: ActivityData?

	/// Drives the distance ⇄ finish-time flash on capsule 2.
	private var flashShowsDistance: Bool = true
	nonisolated(unsafe) private var flashTask: Task<Void, Never>?

	/// Index of the flashing (distance ⇄ finish-time) capsule in `metrics`.
	private static let flashSlotIndex = 1

	// MARK: - Init

	init(eventRepository: EventRepositoryProtocol = FirestoreEventRepository.shared) {
		self.eventRepository = eventRepository
	}

	// MARK: - Deinit

	deinit {
		flashTask?.cancel()
		activeEventsListener?.remove()
	}

	// MARK: - Listener Lifecycle

	func startObservingEvents(userId: String) {
		// Skip re-attach if already listening for this exact userId.
		guard activeListenerUserId != userId else { return }

		activeEventsListener?.remove()
		activeListenerUserId = userId
		isLoadingEvents = true

		activeEventsListener = eventRepository.observeActiveEvents(userId: userId) { [weak self] events in
			guard let self else { return }
			self.upcomingEvents = events
			self.isLoadingEvents = false
			// A run leaving the active set means one just completed — refresh the header metrics.
			self.refreshLatestCompletedMetrics(userId: userId)
		}

		// Seed the header metrics on first attach.
		refreshLatestCompletedMetrics(userId: userId)
	}

	func stopObservingEvents() {
		activeEventsListener?.remove()
		activeEventsListener = nil
		activeListenerUserId = nil
	}

	/// Reacts to an event deleted anywhere in the app. The upcoming list already
	/// updates live via the listener; this also refreshes the header metrics in
	/// case the deleted event was the latest completed one backing them.
	func handleEventDeleted(eventId: Int, userId: String) {
		upcomingEvents.removeAll { $0.id == eventId }
		refreshLatestCompletedMetrics(userId: userId)
	}

	// MARK: - Latest Completed Event → Metrics

	/// Fetches the most recent completed event and maps it into the header metric
	/// capsules. Clears the metrics (hiding the row) when there is no completed event.
	private func refreshLatestCompletedMetrics(userId: String) {
		Task { @MainActor [weak self] in
			guard let self else { return }
			do {
				let events = try await self.eventRepository.fetchCompletedEvents(userId: userId, limit: 1, cursor: nil)
				if let event = events.first {
					self.latestCompletedEvent = event
					self.metrics = self.makeMetrics(from: event)
					self.startFlashLoop()
				} else {
					self.latestCompletedEvent = nil
					self.metrics = []
					self.stopFlashLoop()
				}
			} catch {
				self.latestCompletedEvent = nil
				self.metrics = []
				self.stopFlashLoop()
			}
		}
	}

	/// Builds the five header capsules from a completed event's real, watch-sourced values.
	/// Symbols and slot order match the Home screen design; capsule 2 alternates between
	/// total distance and actual finish time via `startFlashLoop()`.
	private func makeMetrics(from event: ActivityData) -> [HomeMetric] {
		let paceUnit = event.measure == "Kilometers" ? "min/km" : "min/mile"
		return [
			// 1 — Average heart rate overall
			HomeMetric(
				id: "avgHeartRate",
				symbol: "icMatricsBpm",
				value: "\(event.avgHeartRate)",
				unit: "bpm",
				title: "Average Heart Rate",
				description: "Your average heart rate recorded across the whole run."
			),
			// 2 — Total distance ⇄ actual finish time (flashes back and forth)
			flashShowsDistance ? distanceFace(event) : finishTimeFace(event),
			// 3 — Amount of time faster or slower than goal
			HomeMetric(
				id: "timeVariance",
				symbol: "icMatricsGoalTime",
				value: event.timeVar.isEmpty ? "00:00" : event.timeVar,
				unit: "m /sec",
				title: "Time Variance",
				description: "How much faster or slower you finished compared to your goal time."
			),
			// 4 — Average pace for the event
			HomeMetric(
				id: "avgPace",
				symbol: "icMatricsRemaining",
				value: event.avgPaceFormatted,
				unit: paceUnit,
				title: "Average Pace",
				description: "Your average pace for this run."
			),
			// 5 — Goal time originally entered when creating the event
			HomeMetric(
				id: "goalTime",
				symbol: "icMatricsPace",
				value: event.goal,
				unit: "h:m:s",
				title: "Goal Time",
				description: "The finish-time goal you set when you created this event."
			)
		]
	}

	/// Distance face of the flashing capsule — actual distance covered, falling
	/// back to the pre-formatted planned distance string when actuals are absent.
	private func distanceFace(_ event: ActivityData) -> HomeMetric {
		let hasActual = !event.actualDist.isEmpty
		return HomeMetric(
			id: "distanceFinishFlash",
			symbol: "icMatricsHrs",
			value: hasActual ? event.actualDist : event.distance,
			unit: hasActual ? (event.measure == "Kilometers" ? "km" : "mi") : "",
			title: "Total Distance",
			description: "The total distance you covered in this run."
		)
	}

	/// Finish-time face of the flashing capsule — the actual completion time.
	private func finishTimeFace(_ event: ActivityData) -> HomeMetric {
		HomeMetric(
			id: "distanceFinishFlash",
			symbol: "icMatricsHrs",
			value: event.duration.isEmpty ? "00:00:00" : event.duration,
			unit: "time",
			title: "Finish Time",
			description: "Your actual finishing time for this run."
		)
	}

	// MARK: - Flash Loop (distance ⇄ finish time)

	/// Alternates capsule 2 between total distance and actual finish time on a
	/// fixed cadence. Runs on MainActor (inherited) so all @Observable mutations
	/// stay on the main thread. Reassigns the slot in place — same stable id — so
	/// only that capsule crossfades while the others stay put.
	private func startFlashLoop() {
		flashTask?.cancel()
		flashTask = Task { [weak self] in
			while !Task.isCancelled {
				try? await Task.sleep(for: .seconds(2.5))
				guard !Task.isCancelled,
					  let self,
					  let event = self.latestCompletedEvent,
					  self.metrics.count > Self.flashSlotIndex else { break }

				self.flashShowsDistance.toggle()
				let face = self.flashShowsDistance ? self.distanceFace(event) : self.finishTimeFace(event)
				// Simple crossfade between the distance and finish-time faces.
				withAnimation(.easeInOut(duration: 0.35)) {
					self.metrics[Self.flashSlotIndex] = face
				}
			}
		}
	}

	private func stopFlashLoop() {
		flashTask?.cancel()
		flashTask = nil
	}

	// MARK: - Metric Tap

	func didTapMetric(_ metric: HomeMetric) {
		guard let index = metrics.firstIndex(where: { $0.id == metric.id }) else { return }
		selectedMetricIndex = index
		showMetricPopup = true
	}
}
