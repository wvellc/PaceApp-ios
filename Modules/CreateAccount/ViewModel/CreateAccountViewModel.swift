//
//  CreateAccountViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI
import PhotosUI

// MARK: - CreateAccountViewModel

/// Manages state and actions for the entire Create Account onboarding flow.
@Observable
final class CreateAccountViewModel {
	
	// MARK: - Step state
	
	var currentStep: CreateAccountStep = .profile
	var slideDirection: SlideDirection = .forward
	
	// MARK: - Step 1 — Profile
	
	var firstName: String = ""
	var lastName: String = ""
	var selectedPhotoItem: PhotosPickerItem? = nil
	var profileImage: Image? = nil
	
	// MARK: - Step 2 / 3 / 4 — Watch pairing
	/// Mock discovered devices — replace with real BLE scan results.
	var discoveredDevices: [WatchDevice] = [
		WatchDevice(model: "Forerunner 245", nickname: "Jack's Watch"),
		WatchDevice(model: "Forerunner 165", nickname: "Nick Watch"),
		WatchDevice(model: "Fenix 8", nickname: "Jack's Watch 2"),
	]

	/// Watch selected on the ChooseYourModel screen.
	var selectedWatch: WatchDevice? = nil
		
	// MARK: - Step 5 — Set Gait
	var selectedGait: GaitType = .walking
	
	// MARK: - Step 6 — Connect Strava
	
	var stravaProfileURL: String = "strava.com/athletes/12345678"
	
	// MARK: - Navigation events
	
	var navigationEvent: NavigationEvent?
	
	enum NavigationEvent {
		case skip
		case finish
	}
	
	// MARK: - Slide direction
	
	enum SlideDirection {
		case forward, backward
	}
	
	// MARK: - Actions
	
	func onFooterTapped() {
		if let next = currentStep.next {
			slideDirection = .forward
			withAnimation(.easeInOut(duration: 0.3)) { currentStep = next }
		} else {
			navigationEvent = .finish
		}
	}
	
	func onBack() {
		guard let previous = currentStep.previous else { return }
		slideDirection = .backward
		withAnimation(.easeInOut(duration: 0.3)) {
			switch currentStep {
				case .setGait:
					currentStep = .pairWatch
				default:
					currentStep = previous
			}
		}
		
	}
	
	/// Skip jumps past pairWatch + chooseYourModel directly to showConnectedWatch.
	func onSkip() {
		switch currentStep {
			case .pairWatch, .chooseYourModel:
				slideDirection = .forward
				withAnimation(.easeInOut(duration: 0.3)) { currentStep = .setGait }
			default:
				navigationEvent = .skip
		}
	}
	
	// MARK: - Photo loading
	
	@MainActor
	func loadPhoto() async {
		guard let item = selectedPhotoItem else { return }
		guard let data = try? await item.loadTransferable(type: Data.self),
			  let uiImage = UIImage(data: data)
		else { return }
		profileImage = Image(uiImage: uiImage)
	}
}
