//
//  GaitType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//


// MARK: - Gait Type Enum

/// Represents the two supported gait modes: walking and running.
enum GaitType: String, CaseIterable, Identifiable {
	case walking = "Walking"
	case running = "Running"
	var id: String { rawValue }
}

