//
//  CreateRunEventViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

import Foundation
import Observation
import Combine
import SwiftData

// MARK: - ViewModel

@Observable
class CreateRunEventViewModel {
	
	//MARK: Router
	var router: Router?
	private var modelContext: ModelContext?
	
	// MARK: Step 1 – Event Details
	var eventName: String = ""
	var location: String = ""
	var eventDate: Date = Date()
	var focusedField: EventDetailsStepViewField?
	
	var minDate: Date { Date() }
	var maxDate: Date { Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date() }
	
	// MARK: Step 2 – Distance
	var distanceType: MeasureUnit = .miles
	var distance: Float = 1.0
	
	var distanceRange: [Float] {
		switch distanceType {
			case .kilometers, .kilometersLegacy: return Array(stride(from: 0.5, through: 200.0, by: 0.5))
			case .miles: return Array(stride(from: 0.5, through: 150.0, by: 0.5))
			case .feet, .meters: return Array(stride(from: 100.0, through: 5000.0, by: 100.0))
		}
	}
	
	// MARK: Step 3 – Goal Time
	var goalHours: Int = 0
	var goalMinutes: Int = 0
	var goalSeconds: Int = 0
	
	var goalTimeFormatted: String {
		String(format: "%02d:%02d:%02d", goalHours, goalMinutes, goalSeconds)
	}
	
	var totalGoalSeconds: Int {
		(goalHours * 3600) + (goalMinutes * 60) + goalSeconds
	}
	
	// MARK: Step 4 – Segment Choice
	var wantsSegments: Bool = false
	
	// MARK: Step 5 – Segment Count
	var segmentCount: Int = 2
	let minSegments = 2
	let maxSegments = 20
	
	// MARK: Step 6+ – Segment Details
	var segments: [RunSegment] = []
	var currentSegmentIndex: Int = 0
	var segmentValidationError: String? = nil
	
	// MARK: Step – Look-Back Intervals
	var lookBackIntervals: Int = 13
	var eventType: ActivityType = .run
	
	// MARK: Navigation
	var currentStep: CreateRunStep = .eventDetails
	
	
	//MARK: Initializer
	init() {
		#if DEBUG
			eventName = "Pace event"
			location = "London"
		#endif
		
		distanceType = AppSession.userDistanceUnit
	}

	func configure(modelContext: ModelContext) {
		self.modelContext = modelContext
		prefillFromDeviceSettings()
	}
	
	
	// MARK: - Navigation Logic
	
	func goNext() {
		segmentValidationError = nil
		switch currentStep {
			case .eventDetails:
				if validateEventDetails() {
					currentStep = .distance
				}
				
			case .distance:
				currentStep = .goalTime
				
			case .goalTime:
				if validateGoalTime() {
					currentStep = .segmentChoice
				}
				
			case .segmentChoice:
				currentStep = wantsSegments ? .segmentCount : .lookBackIntervals
				
			case .segmentCount:
				buildSegments()
				currentSegmentIndex = 0
				currentStep = .segmentDetails
				
			case .segmentDetails:
				if validateCurrentSegment() {
					if currentSegmentIndex < segments.count - 1 {
						// Redistribute remaining distance & time across pending segments
						redistributeRemaining(after: currentSegmentIndex)
						currentSegmentIndex += 1
					} else {
						currentStep = .lookBackIntervals
					}
				}
				
			case .lookBackIntervals:
				submitForm()
		}
	}
	
	func goBack() {
		segmentValidationError = nil
		switch currentStep {
			case .eventDetails:
				break // handled by screen dismiss
			case .distance:
				currentStep = .eventDetails
			case .goalTime:
				currentStep = .distance
			case .segmentChoice:
				currentStep = .goalTime
			case .segmentCount:
				currentStep = .segmentChoice
			case .segmentDetails:
				if currentSegmentIndex > 0 {
					currentSegmentIndex -= 1
				} else {
					currentStep = .segmentCount
				}
			case .lookBackIntervals:
				if wantsSegments == true {
					currentSegmentIndex = segments.count - 1
					currentStep = .segmentDetails
				} else {
					currentStep = .segmentChoice
				}
		}
	}
	
	// MARK: - Validation
	func validateEventDetails() -> Bool {
		if eventName.trimmingCharacters(in: .whitespaces).isEmpty {
			DispatchQueue.main.async {
				self.focusedField = .eventName
			}
			ToastManager.shared.present(.warning(String(localized: .eventNameIsRequired)))
			return false
		}
		
		if location.trimmingCharacters(in: .whitespaces).isEmpty {
			DispatchQueue.main.async {
				self.focusedField = .location
			}
			ToastManager.shared.present(.warning(String(localized: .locationIsRequired)))
			return false
		}
		
		focusedField = nil
		return true
	}
	
	func validateGoalTime() -> Bool {
		if totalGoalSeconds == 0 {
			ToastManager.shared.present(.warning(String(localized: .goalTimeIsRequired)))
			return false
		}
		return true
	}
	
	func validateCurrentSegment() -> Bool {
		guard currentSegmentIndex < segments.count else { return false }
		
		let currentSegment     = segments[currentSegmentIndex]
		let completedSegments  = Array(segments.prefix(currentSegmentIndex + 1))
		let cumulativeDistance = completedSegments.reduce(0.0) { $0 + $1.distance }
		let cumulativeTime     = completedSegments.reduce(0) { $0 + $1.totalGoalSeconds }
		let totalDist          = distance
		let isLastSegment      = currentSegmentIndex == segments.count - 1
		
		// MARK: Positive value check — every segment must have distance > 0
		if currentSegment.distance >= totalDist {
			segmentValidationError = "Combined segment distance exceeds total distance."
			return false
		}
		
		// MARK: Positive value check — every segment must have time > 0
		if currentSegment.totalGoalSeconds >= totalGoalSeconds {
			segmentValidationError = "Combined segment ETA exceeds total goal."
			return false
		}
		
		// MARK: Exceeds checks — every segment
		
		if cumulativeDistance > totalDist {
			segmentValidationError = "The combined segment distance (\(formatDist(cumulativeDistance)) \(distanceType.rawValue)) exceeds total distance (\(formatDist(distance)) \(distanceType.rawValue))."
			return false
		}
		
		if cumulativeTime > totalGoalSeconds {
			segmentValidationError = "The combined segment ETA (\(formatSeconds(cumulativeTime))) exceeds total goal (\(goalTimeFormatted))."
			return false
		}
		
		// MARK: Below checks — last segment only
		
		if isLastSegment {
			if cumulativeDistance < totalDist {
				segmentValidationError = "The combined segment distance (\(formatDist(cumulativeDistance)) \(distanceType.rawValue)) is below total distance (\(formatDist(distance)) \(distanceType.rawValue))."
				return false
			}
			
			if cumulativeTime < totalGoalSeconds {
				segmentValidationError = "The combined segment ETA (\(formatSeconds(cumulativeTime))) is below total goal (\(goalTimeFormatted))."
				return false
			}
		}
		
		segmentValidationError = nil
		return true
	}

	// MARK: - Private Helpers
	/// Formats a distance value to 1 decimal place string
	private func formatDist(_ value: Float) -> String {
		String(format: "%.2f", value)
	}
	
	/// Formats total seconds as HH:MM:SS
	private func formatSeconds(_ totalSeconds: Int) -> String {
		TimeFormatter.toString(seconds: totalSeconds)
	}
	
	// MARK: - Segment Building
	
	func buildSegments() {
		guard segmentCount > 0 else {
			segments = []
			return
		}
		
		let perDist    = distance / Float(segmentCount)
		let perSecs    = totalGoalSeconds / segmentCount
		let perHrs     = perSecs / 3600
		let perMinutes = (perSecs % 3600) / 60
		let perSeconds = perSecs % 60
		
		segments = (0..<segmentCount).map { index in
			RunSegment(
				id: index,
				distance: perDist,
				goalHours: perHrs,
				goalMinutes: perMinutes,
				goalSeconds: perSeconds
			)
		}
	}
	
	/// After the user confirms a segment, evenly re-divides the leftover
	/// distance and time across all pending segments (confirmedIndex+1 … last).
	private func redistributeRemaining(after confirmedIndex: Int) {
		let pendingCount = segments.count - confirmedIndex - 1
		guard pendingCount > 0 else { return }
		
		// Remaining distance
		let usedDist      = segments.prefix(confirmedIndex + 1).reduce(0.0) { $0 + $1.distance }
		let remainingDist = max(0.0, distance - usedDist)
		let perDist       = remainingDist / Float(pendingCount)
		
		// Remaining time
		let usedSecs      = segments.prefix(confirmedIndex + 1).reduce(0) { $0 + $1.totalGoalSeconds }
		let remainingSecs = max(0, totalGoalSeconds - usedSecs)
		let perSecs       = remainingSecs / pendingCount
		let perHrs        = perSecs / 3600
		let perMinutes    = (perSecs % 3600) / 60
		let perSeconds    = perSecs % 60
		
		for i in (confirmedIndex + 1)..<segments.count {
			segments[i].distance    = perDist
			segments[i].goalHours   = perHrs
			segments[i].goalMinutes = perMinutes
			segments[i].goalSeconds = perSeconds
		}
	}
	
	func updateSegmentDistance(_ value: Float, at index: Int) {
		guard index < segments.count else { return }
		segments[index].distance = value
	}
	
	func updateSegmentGoalTime(hours: Int, minutes: Int, seconds: Int, at index: Int) {
		guard index < segments.count else { return }
		segments[index].goalHours   = hours
		segments[index].goalMinutes = minutes
		segments[index].goalSeconds = seconds
	}
	
	// MARK: - Computed Helpers
	var isOnLastSegment: Bool {
		currentSegmentIndex == segments.count - 1
	}
	
	var isNextEnabled: Bool {
		switch currentStep {
				//			case .segmentChoice: return wantsSegments != nil
			default: return true
		}
	}
	
	var nextButtonTitle: LocalizedStringResource {
		currentStep == .lookBackIntervals ? LocalizedStringResource.submit : LocalizedStringResource.next
	}
	
	// MARK: - Submit
	
	private func submitForm() {
		guard let modelContext else {
			ToastManager.shared.present(.warning("Event storage is not ready. Please try again."))
			return
		}

		let event = makeAppEvent()
		event.syncStatus = SyncStatus.pending.rawValue
		modelContext.insert(event)

		do {
			try modelContext.save()
			ConnectIQManager.shared.sendMessage(makeWatchPayload())
			ToastManager.shared.present(.success("Event saved and sent to watch."))
			router?.navigateToRoot()
		} catch {
			ToastManager.shared.present(.error("Failed to save event: \(error.localizedDescription)"))
		}
	}

	private func prefillFromDeviceSettings() {
		guard let modelContext else { return }
		let descriptor = FetchDescriptor<GarminDeviceSettings>()
		guard let settings = try? modelContext.fetch(descriptor).first else { return }
		distanceType = settings.runningGaitMeasure.isImperial ? .miles : .kilometers
	}

	private func makeAppEvent() -> AppEvent {
		AppEvent(from: makeGarminEventDTO(), isActive: true)
	}

	private func makeGarminEventDTO() -> GarminEventDTO {
		GarminEventDTO(
			date: DateFormatter.garminDateString(from: eventDate),
			name: eventName,
			activity: eventType.rawValue,
			distance: Double(distance),
			measure: distanceType.garminRawValue,
			goal: goalTimeFormatted,
			intervals: lookBackIntervals,
			segmentCount: wantsSegments ? segments.count : 0,
			segments: wantsSegments ? segments.map {
				GarminSegmentDTO(
					eta: $0.formattedGoalTime,
					distance: Double($0.distance)
				)
			} : [],
			actualTime: nil,
			actualDist: nil,
			avgHeartRate: nil,
			paces: nil,
			location: location,
			timeVar: nil,
			startAt: eventDate.timeIntervalSince1970,
			stopAt: nil,
			completedSegments: nil
		)
	}

	private func makeWatchPayload() -> [String: Any] {
		[
			"type": "createEvent",
			"event": [
				"date": DateFormatter.garminDateString(from: eventDate),
				"name": eventName,
				"activity": eventType.rawValue,
				"distance": Double(distance),
				"measure": distanceType.garminRawValue,
				"goal": goalTimeFormatted,
				"intervals": lookBackIntervals,
				"segmentCount": wantsSegments ? segments.count : 0,
				"segments": wantsSegments ? segments.map {
					[
						"eta": $0.formattedGoalTime,
						"distance": Double($0.distance)
					]
				} : [],
				"location": location,
				"startAt": eventDate.timeIntervalSince1970
			]
		]
	}
}

private extension DateFormatter {
	static func garminDateString(from date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM/d/yyyy"
		formatter.locale = Locale(identifier: "en_US_POSIX")
		return formatter.string(from: date)
	}
}
