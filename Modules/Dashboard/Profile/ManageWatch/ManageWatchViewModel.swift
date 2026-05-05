
//
//  ManageWatchViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

// MARK: - ManageWatchStep

/// Ordered steps for the Manage Watch flow.
enum ManageWatchStep: Int, CaseIterable {
	/// Shows the currently connected watch with a "Disconnect Device" button.
	case currentConnected
	/// Prompts the user to start pairing a new watch.
	case pairWatch
	/// Lists discovered watches so the user can choose one.
	case chooseYourModel
	
	// MARK: Navigation helpers
	
	var next: ManageWatchStep? { ManageWatchStep(rawValue: rawValue + 1) }
	var previous: ManageWatchStep? { ManageWatchStep(rawValue: rawValue - 1) }
	
	// MARK: Nav-bar title
	
	var title: String {
		switch self {
			case .currentConnected:   return "Manage your watch"
			case .pairWatch:          return "Pair Watch"
			case .chooseYourModel:    return "Choose your model"
		}
	}
	
	// MARK: Footer button label
	
	var footerButtonTitle: String {
		switch self {
			case .currentConnected:   return "Disconnect Device"
			case .pairWatch:          return "Start Pairing"
			case .chooseYourModel:    return "Pair"
		}
	}
	
	// MARK: Visibility flags
	
	var showsBack: Bool { /*self != .currentConnected*/ true }
}

// MARK: - ManageWatchViewModel

@Observable
final class ManageWatchViewModel {
	
	// MARK: Step state
	
	var currentStep: ManageWatchStep = .currentConnected
	var slideDirection: SlideDirection = .forward
	
	// MARK: Watch data
	
	/// Mock discovered devices — replace with real BLE scan results.
	var discoveredDevices: [WatchDevice] = [
		WatchDevice(model: "Forerunner 245", nickname: "Jack's Watch"),
		WatchDevice(model: "Forerunner 165", nickname: "Nick Watch"),
		WatchDevice(model: "Forerunner 265", nickname: "Jack's Watch 2"),
	]
	
	/// The currently connected watch (shown on the first step).
	var connectedWatch: WatchDevice? = WatchDevice(model: "Forerunner® 165 Music", nickname: "Nick Watch")
	
	/// Watch selected on the ChooseYourModel screen.
	var selectedWatch: WatchDevice? = nil
	
	// MARK: Slide direction
	
	enum SlideDirection {
		case forward, backward
	}
	
	// MARK: Navigation events
	
	var navigationEvent: NavigationEvent?
	
	enum NavigationEvent {
		case dismiss
	}
	
	// MARK: Actions
	
	func onFooterTapped() {
		switch currentStep {
			case .currentConnected:
				// Disconnect and move to pairing flow
				connectedWatch = nil
				advance()
			case .pairWatch:
				advance()
			case .chooseYourModel:
				// Commit the selected watch as connected and dismiss
				connectedWatch = selectedWatch
				currentStep = .currentConnected
				
				ToastManager.shared
					.present(.success(String(localized: "\(connectedWatch?.model ?? "") is connected")))
				
		}
	}
	
	func onBack() {
		
		guard let previous = currentStep.previous else {
			navigationEvent = .dismiss
			return
		}
		
		if previous == .currentConnected && connectedWatch == nil {
			navigationEvent = .dismiss
			return
		}
		
		slideDirection = .backward
		withAnimation(.easeInOut(duration: 0.3)) {
			currentStep = previous
		}
	}
	
	// MARK: Private helpers
	
	private func advance() {
		guard let next = currentStep.next else {
			navigationEvent = .dismiss
			return
		}
		slideDirection = .forward
		withAnimation(.easeInOut(duration: 0.3)) {
			currentStep = next
		}
	}
}
