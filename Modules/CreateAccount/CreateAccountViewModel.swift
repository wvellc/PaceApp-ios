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
    /// The currently active onboarding step.
    var currentStep: CreateAccountStep = .profile

    /// Slide direction used by the transition animation.
    var slideDirection: SlideDirection = .forward

    // MARK: - Step 1 — Profile

    var firstName: String = ""
    var lastName: String = ""
    /// Photo item selected from the system picker.
    var selectedPhotoItem: PhotosPickerItem? = nil
    /// Resolved image displayed in the avatar well.
    var profileImage: Image? = nil

    // MARK: - Step 2 — Connect Watch

    /// Name of the detected / paired watch (placeholder for real pairing logic).
    var watchName: String = "Forerunner® 165 Music"

    // MARK: - Step 3 — Set Gait
	var selectedGait: GaitType = .walking

    // MARK: - Step 4 — Connect Strava
    var stravaProfileURL: String = "strava.com/athletes/12345678"

    // MARK: - Navigation events (View reacts to these)
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

    /// Advance to the next step, or fire the finish event on the last step.
    func onFooterTapped() {
        if let next = currentStep.next {
            slideDirection = .forward
            withAnimation(.easeInOut(duration: 0.3)) { currentStep = next }
        } else {
            navigationEvent = .finish
			
        }
    }

    /// Go back one step, or do nothing on the first step.
    func onBack() {
        guard let previous = currentStep.previous else { return }
        slideDirection = .backward
        withAnimation(.easeInOut(duration: 0.3)) { currentStep = previous }
    }

    /// Skip the remaining steps entirely.
    func onSkip() {
        navigationEvent = .skip
    }

    // MARK: - Photo loading

    /// Loads the resolved `Image` from the selected `PhotosPickerItem`.
    @MainActor
    func loadPhoto() async {
        guard let item = selectedPhotoItem else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data)
        else { return }
        profileImage = Image(uiImage: uiImage)
    }
}
