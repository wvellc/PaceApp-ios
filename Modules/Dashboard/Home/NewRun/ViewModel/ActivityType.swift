//
//  EventType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

import SwiftUI

// MARK: - Event Enums
enum ActivityType: String, CaseIterable, Codable {
    case run = "Run"
    case walking = "Walking"
    case cycling = "Cycling"
    case other = "Other"

    init(from value: String?) {
        guard let value = value else {
            self = .run
            return
        }
        switch value.lowercased() {
        case "walk", "walking":
            self = .walking
        case "cycle", "cycling":
            self = .cycling
        case "other":
            self = .other
        case "run", "running":
            self = .run
        default:
            self = .run
        }
    }

    var watchString: String {
        switch self {
        case .walking: return "Walk"
        case .cycling: return "Cycling"
        case .other: return "Other"
        case .run: return "Run"
        }
    }

    /// Full-word title for screen headers, e.g. "Running Details".
    var title: String {
        switch self {
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .other: return "Other"
        case .run: return "Running"
        }
    }

    /// Asset icon representing the activity, used in list/upcoming cells.
    var icon: ImageResource {
        switch self {
        case .walking: return .icWalk
        case .cycling: return .icCycle
        case .other: return .icOther
        case .run: return .icRunLeft
        }
    }
}
