//
//  CreateAccountViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI
import ConnectIQ

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
        guard let devices = ciqManager?.devices else { return }
        if let current = selectedWatch, devices.contains(where: { $0.uuid == current.uuid }) {
            return // still valid
        }
        selectedWatch = devices.first
    }

    // MARK: - Actions

    func onFooterTapped() {
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
            navigationEvent = .skip
        }
    }

    // MARK: - Gait defaults

    private func applyDefaultGaitLengths(for gender: Gender) {
        AppSession.userGaitData = gender.defaultGaitData
    }
}
