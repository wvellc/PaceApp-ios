//
//  CreateRunEventViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

import Foundation
import Observation

// MARK: - ViewModel

@Observable
final class CreateRunEventViewModel {

    // MARK: Step 1 – Event Details
    var eventName: String = "Fastest Pace"
    var location: String = "Gorgiana, CA"
    var eventDate: Date = Date()
    var eventDetailsError: String? = nil

    var minDate: Date { Date() }
    var maxDate: Date { Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date() }

    // MARK: Step 2 – Distance
    var distanceType: DistanceType = .miles
    var distance: Double = 12.0

    var distanceRange: [Double] {
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
    var wantsSegments: Bool? = nil

    // MARK: Step 5 – Segment Count
    var segmentCount: Int = 1
    let minSegments = 1
    let maxSegments = 99

    // MARK: Step 6+ – Segment Details
    var segments: [RunSegment] = []
    var currentSegmentIndex: Int = 0
    var segmentValidationError: String? = nil

    // MARK: Step – Look-Back Intervals
    var lookBackIntervals: Int = 13
    var eventType: EventType = .run

    // MARK: Navigation
    var currentStep: CreateRunStep = .eventDetails

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
            currentStep = .segmentChoice

        case .segmentChoice:
            guard let wants = wantsSegments else { return }
            currentStep = wants ? .segmentCount : .lookBackIntervals

        case .segmentCount:
            buildSegments()
            currentSegmentIndex = 0
            currentStep = .segmentDetails

        case .segmentDetails:
            if validateCurrentSegment() {
                if currentSegmentIndex < segments.count - 1 {
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
            eventDetailsError = "Event name is required."
            return false
        }
        if location.trimmingCharacters(in: .whitespaces).isEmpty {
            eventDetailsError = "Location is required."
            return false
        }
        eventDetailsError = nil
        return true
    }

    func validateCurrentSegment() -> Bool {
        guard currentSegmentIndex < segments.count else { return false }

        // Only validate totals on the last segment
        guard currentSegmentIndex == segments.count - 1 else { return true }

        let totalDistance  = segments.reduce(0.0) { $0 + $1.distance }
        let totalTime      = segments.reduce(0)   { $0 + $1.totalGoalSeconds }
        let roundedTotal   = (totalDistance * 10).rounded() / 10

        if roundedTotal > distance {
            segmentValidationError = "Total segment distance (\(String(format: "%.1f", roundedTotal)) \(distanceType.rawValue)) exceeds your goal distance (\(String(format: "%.1f", distance)) \(distanceType.rawValue))."
            return false
        }
        if totalTime > totalGoalSeconds {
            segmentValidationError = "Total segment time exceeds your goal time of \(goalTimeFormatted)."
            return false
        }
        return true
    }

    // MARK: - Segment Building

	func buildSegments() {
		guard segmentCount > 0 else {
			segments = []
			return
		}
		
		let perDist = (distance / Double(segmentCount) * 10).rounded() / 10
		
		let perSecs = totalGoalSeconds / segmentCount
		let perHrs = perSecs / 3600
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

    func updateSegmentDistance(_ value: Double, at index: Int) {
        guard index < segments.count else { return }
        segments[index].distance = value
    }

	func updateSegmentGoalTime(hours:Int, minutes: Int, seconds: Int, at index: Int) {
        guard index < segments.count else { return }
		segments[index].goalHours = hours
        segments[index].goalMinutes = minutes
        segments[index].goalSeconds = seconds
    }

    // MARK: - Computed Helpers

    var segmentDistanceRange: [Double] {
        Array(stride(from: 0.5, through: max(distance, 1.0), by: 0.5))
    }

    var isOnLastSegment: Bool {
        currentSegmentIndex == segments.count - 1
    }

    var isNextEnabled: Bool {
        switch currentStep {
        case .segmentChoice: return wantsSegments != nil
        default: return true
        }
    }

	var nextButtonTitle: LocalizedStringResource {
		currentStep == .lookBackIntervals ? LocalizedStringResource.submit : LocalizedStringResource.next
    }

    // MARK: - Submit

    private func submitForm() {
        // TODO: Pass to coordinator / API layer
        print("Form submitted: \(eventName), \(location), \(eventDate)")
    }
}
