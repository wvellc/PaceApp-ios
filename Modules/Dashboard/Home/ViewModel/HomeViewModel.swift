//
//  HomeViewModel.swift
//  PaceApp
//

import SwiftUI
import Combine

// MARK: - Home View Model

@MainActor
@Observable
final class HomeViewModel {
	
	// MARK: - Metrics
	
	var metrics: [HomeMetric]
	var isHighPerformance: Bool = false
	var showMetricPopup: Bool = false
	var selectedMetricIndex: Int = 0
	
	// MARK: - Events
	
	var upcomingEvents: [ActivityData] = []
	var isLoadingEvents: Bool = false
	
	// MARK: - Private
	
	/// Timer is held as a Task so it runs on MainActor — no cross-thread state mutation.
	private var tickTask: Task<Void, Never>?
	
	private let eventRepository: EventRepositoryProtocol
	nonisolated(unsafe) private var activeEventsListener: ListenerRegistrationToken?
	
	/// Guards against redundant re-attaches when .task(id:) re-fires with the same userId.
	private var activeListenerUserId: String?
	
	// MARK: - Init
	
	init(eventRepository: EventRepositoryProtocol = FirestoreEventRepository.shared) {
		self.eventRepository = eventRepository
		self.metrics = [
			.init(
				symbol: "icMatricsBpm",
				value: "60",
				unit: "bpm",
				title: "Heart Rate Monitor",
				description: "Tracks your heart rate during workouts and daily activities. Tap the heart icon to view your current rate and gain insights to enhance your fitness journey."
			),
			.init(
				symbol: "icMatricsHrs",
				value: "12",
				unit: "hrs",
				title: "Active Hours",
				description: "Monitors the number of active hours in your day. Stay consistent with movement goals and build healthy long-term habits."
			),
			.init(
				symbol: "icMatricsGoalTime",
				value: "-01:10",
				unit: "m /sec",
				title: "Goal Time",
				description: "Shows your remaining time to hit your target pace. Keep pushing — every second counts toward your personal best."
			),
			.init(
				symbol: "icMatricsRemaining",
				value: "7:20",
				unit: "m /sec",
				title: "Remaining Pace",
				description: "Displays your current remaining pace per segment. Use this to adjust your effort and finish strong within your goal window."
			),
			.init(
				symbol: "icMatricsPace",
				value: "9:09",
				unit: "min/mile",
				title: "Pace Tracker",
				description: "Measures your real-time pace in minutes per mile. Stay in your target zone to optimise performance and avoid burnout."
			)
		]
		
		startTickLoop()
	}
	
	// MARK: - Deinit
	
	deinit {
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
		}
	}
	
	func stopObservingEvents() {
		activeEventsListener?.remove()
		activeEventsListener = nil
		activeListenerUserId = nil
	}
	
	// MARK: - Metric Tap
	
	func didTapMetric(_ metric: HomeMetric) {
		guard let index = metrics.firstIndex(where: { $0.id == metric.id }) else { return }
		selectedMetricIndex = index
		showMetricPopup = true
	}
	
	// MARK: - Tick Loop (MainActor-safe)
	
	/// Runs the prototype metric update loop entirely on MainActor
	/// so all @Observable state mutations are on the correct thread.
	private func startTickLoop() {
		tickTask?.cancel()
		tickTask = Task { [weak self] in
			while !Task.isCancelled {
				try? await Task.sleep(for: .seconds(3))
				guard !Task.isCancelled, let self else { break }
				self.tick()
			}
		}
	}
	
	private func tick() {
		func twoDigits(_ n: Int) -> String { String(format: "%02d", n) }
		isHighPerformance.toggle()
		
		metrics = metrics.enumerated().map { index, metric in
			switch index {
				case 0: // bpm
					let bpm = Int.random(in: 55...110)
					return HomeMetric(symbol: metric.symbol, value: "\(bpm)", unit: "bpm",
									  title: metric.title, description: metric.description)
					
				case 1: // hrs
					let hrs = Int.random(in: 6...16)
					return HomeMetric(symbol: metric.symbol, value: "\(hrs)", unit: "hrs",
									  title: metric.title, description: metric.description)
					
				case 2: // goal time (signed mm:ss)
					let negative = Bool.random()
					let m = Int.random(in: 0...1)
					let s = Int.random(in: 0...59)
					let sign = negative ? "-" : ""
					return HomeMetric(symbol: metric.symbol, value: "\(sign)\(twoDigits(m)):\(twoDigits(s))", unit: "m /sec",
									  title: metric.title, description: metric.description)
					
				case 3: // remaining (mm:ss)
					let m = Int.random(in: 0...12)
					let s = Int.random(in: 0...59)
					return HomeMetric(symbol: metric.symbol, value: "\(m):\(twoDigits(s))", unit: "m /sec",
									  title: metric.title, description: metric.description)
					
				case 4: // pace (min/mile)
					let m = Int.random(in: 7...12)
					let s = Int.random(in: 0...59)
					return HomeMetric(symbol: metric.symbol, value: "\(m):\(twoDigits(s))", unit: "min/mile",
									  title: metric.title, description: metric.description)
					
				default:
					return HomeMetric(symbol: metric.symbol, value: metric.value, unit: metric.unit,
									  title: metric.title, description: metric.description)
			}
		}
	}
}
