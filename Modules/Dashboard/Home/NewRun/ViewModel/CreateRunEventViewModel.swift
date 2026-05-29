//
//  CreateRunEventViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

import Foundation
import Observation
import Combine

// MARK: - ViewModel

@Observable
class CreateRunEventViewModel {
	
	//MARK: Required properties
	let type: CreateEventType

	
	//MARK: Router
	var router: Router?
	
	// MARK: Step 1 – Event Details
    var id: Int = Int(Date().timeIntervalSince1970)
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
			case .km:    return Array(stride(from: 0.5, through: 200.0, by: 0.5))
			case .miles: return Array(stride(from: 0.5, through: 150.0, by: 0.5))
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
	init(type:CreateEventType = .new) {
		#if DEBUG
			eventName = "Pace event"
			location = "NY City"
		#endif
		
		distanceType = AppSession.userDistanceUnit
		
		self.type = type
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
		let h = totalSeconds / 3600
		let m = (totalSeconds % 3600) / 60
		let s = totalSeconds % 60
		return String(format: "%02d:%02d:%02d", h, m, s)
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
		//Duplicate event
		if type == .duplicate {
			return .save
		}
		
		//New event
		return currentStep == .lookBackIntervals ? LocalizedStringResource.create : LocalizedStringResource.next
	}
	
	// MARK: - Submit
	
	private func submitForm() {
		// TODO: Pass to coordinator / API layer
		let eventPayload = connectIQEventPayload()
		ConnectIQManager.shared.sendMessage(["event": eventPayload])
		ConnectIQManager.shared.upsertSyncedActivity(from: eventPayload)
		print("Form submitted: \(eventName), \(location), \(eventDate)")

		ToastManager.shared.present(.success("\(eventType.rawValue) event created"))
		router?.navigateToRoot()
	}

	private func connectIQEventPayload() -> [String: Any] {
		[
            "id": id,
			"name": eventName,
			"location": location,
			"date": Self.connectIQDateFormatter.string(from: eventDate),
			"distance": String(format: "%.2f", distance),
			"measure": distanceType == .miles ? "Miles" : "Kilometers",
			"intervals": "\(lookBackIntervals)",
			"goal": goalTimeFormatted,
			"activity": eventType.rawValue,
			"segmentCount": wantsSegments ? segments.count : 1,
			"segments": wantsSegments ? segments.map { segment in
				[
					"distance": segment.distance,
					"eta": segment.formattedGoalTime
				]
			} : [[String: Any]](),
			"completedSegments": [[String: Any]]()
		]
	}

	private static let connectIQDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "MMM/d/yyyy"
		return formatter
	}()
}
