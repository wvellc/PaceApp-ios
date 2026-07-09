//
//  GaitStrideCalculator.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/8/26.
//

import Foundation

// MARK: - GaitStrideCalculator
//
// Estimates walking/running stride length from user height using the industry-standard
// factors (Gait_Stride_Length_By_Height reference): walking = height × 0.413,
// running = height × 0.65. Height in cm → stride in meters, then expressed in the app's
// gait unit ("Feet"/"Meters") or in millimeters for the watch.

enum GaitStrideCalculator {

	// MARK: - Factors

	// Industry-standard stride estimates used by fitness trackers to convert steps → distance.
	static let walkingFactor = 0.413
	static let runningFactor = 0.65

	private static let feetPerMeter        = 3.280839895
	private static let millimetersPerMeter = 1000.0

	// MARK: - Height → Gait

	/// Builds both gaits from a height in centimeters, each in the given unit word.
	static func gait(heightCm: Double, walkingUnit: String, runningUnit: String) -> GaitUserData {
		GaitUserData(
			walkingData: GaitData(stepLength: stepLength(heightCm: heightCm, factor: walkingFactor, unit: walkingUnit), unit: walkingUnit),
			runningData: GaitData(stepLength: stepLength(heightCm: heightCm, factor: runningFactor, unit: runningUnit), unit: runningUnit)
		)
	}

	/// Step length in the given unit word, 2 dp. e.g. 175 cm walking → 2.37 Feet.
	static func stepLength(heightCm: Double, factor: Double, unit: String) -> Double {
		let meters = (heightCm / 100.0) * factor
		let value  = isMeters(unit) ? meters : meters * feetPerMeter
		return (value * 100).rounded() / 100
	}

	// MARK: - Gait → Watch millimeters

	/// A stored step length + unit converted to whole millimeters for the watch.
	static func millimeters(stepLength: Double, unit: String) -> Int {
		let meters = isMeters(unit) ? stepLength : stepLength / feetPerMeter
		return Int((meters * millimetersPerMeter).rounded())
	}

	// MARK: - Unit conversion

	/// Converts a step length between "Feet"/"Meters", snapped to the picker's 1-dp step.
	static func convert(_ stepLength: Double, fromUnit: String, toUnit: String) -> Double {
		guard isMeters(fromUnit) != isMeters(toUnit) else { return stepLength }
		let meters = isMeters(fromUnit) ? stepLength : stepLength / feetPerMeter
		let value  = isMeters(toUnit) ? meters : meters * feetPerMeter
		return min(9.9, max(0, (value * 10).rounded() / 10))
	}

	// MARK: - Private

	private static func isMeters(_ unit: String) -> Bool {
		unit.lowercased().hasPrefix("m")
	}
}
