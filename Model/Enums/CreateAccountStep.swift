//
//  CreateAccountStep.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import Foundation

// MARK: - CreateAccountStep

/// All steps in the Create Account onboarding flow, in display order.
enum CreateAccountStep: Int, CaseIterable {
    case profile      // Step 1 — Add photo + name
    case connectWatch // Step 2 — Pair Garmin watch
    case setGait     // Step 3 — Choose gait preferences
    case connectStrava // Step 4 — Link Strava

    // MARK: - Navigation helpers

    /// Returns the next step, or nil when already on the last step.
    var next: CreateAccountStep? {
        CreateAccountStep(rawValue: rawValue + 1)
    }

    /// Returns the previous step, or nil when already on the first step.
    var previous: CreateAccountStep? {
        CreateAccountStep(rawValue: rawValue - 1)
    }

    // MARK: - Nav-bar content

    /// Page title shown in the top navigation bar.
    var title: String {
        switch self {
        case .profile:       return "Create Account"
        case .connectWatch:  return "Connect Watch"
        case .setGait:      return "Set Gait"
        case .connectStrava: return "Connect Strava"
        }
    }

    // MARK: - Footer button

    /// Label for the primary action button at the bottom of each step.
    var footerButtonTitle: LocalizedStringResource {
        switch self {
        case .profile, .connectWatch, .setGait: return "Next"
        case .connectStrava:                     return "Connect"
        }
    }

    // MARK: - Visibility flags

    /// Whether the leading back chevron should be visible.
    var showsBack: Bool { previous != nil }

    /// Whether the trailing Skip button should be visible.
    var showsSkip: Bool { next != nil }
}
