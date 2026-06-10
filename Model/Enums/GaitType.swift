//
//  GaitType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

// MARK: - GaitType

/// Represents the two supported gait modes: walking and running.
enum GaitType: String, CaseIterable, Identifiable, Equatable {
	case walking = "Walking"
	case running = "Running"
	
	var id: String { rawValue }
	
	var label: String {
		switch self {
			case .walking: "Walk"
			case .running: "Run"
		}
	}
}
