//
//  CreateAccountViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI
import ConnectIQ

enum CreateAccountProfileField: Hashable {
    case firstName
    case lastName
}

// MARK: - CreateAccountViewModel

/// Manages state and actions for the entire Create Account onboarding flow.
@Observable
final class CreateAccountViewModel {

    // MARK: - Watch

    /// Injected after init via configure(ciqManager:) from the View's .onAppear.
    /// Because ConnectIQManager is @Observable, any View reading
    /// ciqManager.devices will automatically re-render when devices arrive —
    /// no manual Combine subscription is needed.
    private(set) var ciqManager: ConnectIQManager?

    // MARK: - Step state

    var currentStep: CreateAccountStep = .profile
    var slideDirection: SlideDirection = .forward

    // MARK: - Step 1 — Profile

    var firstName: String = ""
    var lastName: String = ""
    var focusedField: CreateAccountProfileField?
    var selectedGender: Gender = .male {
        didSet { applyDefaultGaitLengths(for: selectedGender) }
    }

    // MARK: - Step 2/3/4 — Watch pairing

    /// Watch selected on the ChooseYourModel screen.
    var selectedWatch: IQDevice? = nil

    // MARK: - Step 5 — Set Gait

    var selectedGait: GaitType = .walking

    // MARK: - Step 6 — Connect Strava

    var stravaProfileURL: String = "strava.com/athletes/12345678"

    // MARK: - Navigation events

    var navigationEvent: NavigationEvent?

    enum NavigationEvent { case skip, finish }

    // MARK: - Slide direction

    enum SlideDirection { case forward, backward }

    // MARK: - Init

    init() {
        applyDefaultGaitLengths(for: selectedGender)
    }

    // MARK: - Injection

    /// Call from the View's .onAppear.
    /// The View must read ciqManager.devices directly so @Observable
    /// re-renders the list automatically when devices arrive from Garmin Connect.
    func configure(ciqManager: ConnectIQManager) {
        guard self.ciqManager == nil else { return }
        self.ciqManager = ciqManager
        syncSelectedWatch()
    }

    /// Re-evaluate selectedWatch against the current device list.
    /// Call from ChooseDevicesStepView.onAppear / onChange(of: ciqManager.devices).
    func syncSelectedWatch() {
		guard let devices = ciqManager?.devices else {
			return
		}

		if let current = selectedWatch, devices.contains(where: { $0.uuid == current.uuid }) {
            return // still valid
        }
		
		if devices.first != nil {
			print("Watch selected \(devices.first?.modelName ?? "--")")
			selectedWatch = devices.first
//			currentStep = .chooseYourModel

		} else {
			if currentStep == .chooseYourModel {
				currentStep = .pairWatch
				ToastManager.shared.present(.error("No watch connected. Pair again."))
			}
			selectedWatch = nil

		}
    }

    // MARK: - Actions

    func onFooterTapped() {
        if currentStep == .profile {
            guard validateProfile() else { return }
            saveUserProfile()
        }

        if currentStep == .pairWatch {
            ciqManager?.findDevices()
        }

        if currentStep == .chooseYourModel, let watch = selectedWatch {
            ciqManager?.connectToApp(device: watch)
        }

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
            case .setGait: currentStep = .pairWatch
            default:       currentStep = previous
            }
        }
    }

    func onSkip() {
        switch currentStep {
        case .pairWatch, .chooseYourModel:
            slideDirection = .forward
            withAnimation(.easeInOut(duration: 0.3)) { currentStep = .setGait }
        default:
            // Skipping final steps — still persist the profile info collected so far
            saveUserProfile()
            navigationEvent = .skip
        }
    }

    // MARK: - Gait defaults

    private func applyDefaultGaitLengths(for gender: Gender) {
        AppSession.userGaitData = gender.defaultGaitData
    }

    // MARK: - Validation

    @discardableResult
    private func validateProfile() -> Bool {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)

        guard !trimmedFirstName.isEmpty,
              ValidationProvider.isValid(text: trimmedFirstName, type: .name) else {
            focusedField = .firstName
            return false
        }

        guard !trimmedLastName.isEmpty,
              ValidationProvider.isValid(text: trimmedLastName, type: .name) else {
            focusedField = .lastName
            return false
        }

        focusedField = nil
        return true
    }

    // MARK: - Session Persistence

    /// Saves first name, last name, and gender into the persisted UserModel.
    /// Profile is considered complete once both names are non-empty.
    private func saveUserProfile() {
        // Start from the existing model so we never overwrite the UUID
        var user = AppSession.userDetails ?? UserModel(uuid: UUID().uuidString)
        user.firstName = firstName.trimmingCharacters(in: .whitespaces)
        user.lastName = lastName.trimmingCharacters(in: .whitespaces)
        user.gender = selectedGender
        AppSession.userDetails = user
    }
}
