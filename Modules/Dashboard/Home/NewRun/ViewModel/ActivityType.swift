//
//  EventType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

// MARK: - Event Enums
enum ActivityType: String, Codable, CaseIterable, Identifiable {
    case run = "Run"
    case walking = "Walking"
    case cycle = "Cycle"
    case other = "Other"

	static var allCases: [ActivityType] {
		[.run, .walking, .cycle]
	}
	
	var id: String { rawValue }
	
	var icon: String {
		switch self {
			case .cycle: return "bicycle"
			case .run:   return "figure.run"
			case .walking:  return "figure.walk"
			case .other: return "figure.mixed.cardio"
		}
	}
}
