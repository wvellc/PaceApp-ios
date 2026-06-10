//
//  Gender.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/8/26.
//

// MARK: - Gender

enum Gender: String, CaseIterable, Identifiable, Codable, Equatable {
	case male   = "Male"
	case female = "Female"
	case other  = "Other"
	
	var id: String { rawValue }
	
	var defaultGaitData: GaitUserData {
		GaitUserData(
			walkingData: GaitData(stepLength: defaultStepLength(for: .walking), unit: "Feet"),
			runningData: GaitData(stepLength: defaultStepLength(for: .running), unit: "Feet")
		)
	}
	
	func defaultStepLength(for gaitType: GaitType) -> Double {
		switch (self, gaitType) {
			case (.female, .walking):
				return 2.2
			case (.female, .running):
				return 3.5
			case (.male, .walking), (.other, .walking):
				return 2.5
			case (.male, .running), (.other, .running):
				return 4.0
		}
	}
}
