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
	case profile
	case pairWatch
	case chooseYourModel
	case showConnectedWatch
	case setGait
	case connectStrava
	
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
			case .profile:           return "Create Account"
			case .pairWatch:         return "Pair Watch"
			case .chooseYourModel:   return "Choose your model"
			case .showConnectedWatch: return "Pair Watch"
			case .setGait:           return "Set Gait"
			case .connectStrava:     return "Connect Strava"
		}
	}
	
	// MARK: - Footer button
	/// Label for the primary action button at the bottom of each step.
	var footerButtonTitle: String {
		switch self {
			case .profile:           return "Continue"
			case .pairWatch:         return "Start Pairing"
			case .chooseYourModel:   return "Pair"
			case .showConnectedWatch: return "Next"
			case .setGait:           return "Continue"
			case .connectStrava:     return "Connect Strava"
		}
	}
	
	// MARK: - Visibility flags
	var showsBack: Bool { self != .profile }
	
	var showsSkip: Bool {
		switch self {
			case .pairWatch, .chooseYourModel, .connectStrava: return true
			default: return false
		}
	}
}
