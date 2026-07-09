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

    /// Live gait data being built during onboarding.
    /// Seeded from the watch value (height-derived) or gender defaults; updated as the user interacts.
    var gaitData: GaitUserData = Gender.male.defaultGaitData

    /// Bumped only when gait is re-seeded (Set Gait entry / watch sync) so the pickers
    /// re-init from the new value — user wheel edits don't change it, so scrolling stays smooth.
    private(set) var gaitSeedToken = 0

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
    func configure(ciqManager: ConnectIQManager) {
        guard self.ciqManager == nil else { return }
        self.ciqManager = ciqManager
        syncSelectedWatch()
    }

    /// Re-evaluate selectedWatch against the current device list.
    func syncSelectedWatch() {
        guard let devices = ciqManager?.devices else { return }

        if let current = selectedWatch, devices.contains(where: { $0.uuid == current.uuid }) {
            return // still valid
        }

        if let firstDevice = devices.first {
            selectedWatch = firstDevice
        } else {
            if currentStep == .chooseYourModel {
                currentStep = .pairWatch
                ToastManager.shared.present(.error("No watch connected. Pair again."))
            }
            selectedWatch = nil
        }
    }

    // MARK: - Gait callbacks (forwarded from SetGaitStepView)

    func onRunningGaitChange(_ data: GaitData) {
        gaitData.runningData = data
    }

    func onWalkingGaitChange(_ data: GaitData) {
        gaitData.walkingData = data
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
            // Seed gait from the connected watch before Set Gait renders (avoids a flash of defaults).
            if next == .setGait { seedGait() }
            slideDirection = .forward
            withAnimation(.easeInOut(duration: 0.3)) { currentStep = next }
        } else {
            // Last step — persist gait before finishing
            saveGait()
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
            seedGait()
            slideDirection = .forward
            withAnimation(.easeInOut(duration: 0.3)) { currentStep = .setGait }
        default:
            // Skipping final steps — persist whatever has been collected so far
            saveUserProfile()
            saveGait()
            navigationEvent = .skip
        }
    }

    // MARK: - Gait defaults (no more AppSession)

    private func applyDefaultGaitLengths(for gender: Gender) {
        gaitData = gender.defaultGaitData
    }

    /// Seeds gait from the watch/Firestore value (height-derived) when available, else
    /// gender defaults. Called on Set Gait entry and when a live watch sync lands.
    func seedGait() {
        gaitData = AuthManager.shared.userDetails?.gait ?? selectedGender.defaultGaitData
        gaitSeedToken += 1
    }

    // MARK: - Validation

    @discardableResult
    private func validateProfile() -> Bool {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName  = lastName.trimmingCharacters(in: .whitespaces)

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

    // MARK: - Firestore Persistence

    /// Saves first name, last name, and gender into Firestore via AuthManager sync.
    private func saveUserProfile() {
        guard let currentUID = AuthManager.shared.currentUserID else { return }
        var user = AuthManager.shared.userDetails ?? UserModel(uuid: currentUID)
        user.firstName = firstName.trimmingCharacters(in: .whitespaces)
        user.lastName  = lastName.trimmingCharacters(in: .whitespaces)
        user.gender    = selectedGender
        AuthManager.shared.userDetails = user

        Task {
            await AuthManager.shared.syncUserToFirestore(userId: currentUID)
        }
    }

    /// Writes the current gait data to Firestore and keeps the in-memory model in sync.
    private func saveGait() {
        guard let currentUID = AuthManager.shared.currentUserID else { return }
        let snapshot = gaitData
        AuthManager.shared.userDetails?.gait = snapshot
        Task {
            try? await UserProfileRepository.shared.updateGait(snapshot, userId: currentUID)
        }
    }
}
