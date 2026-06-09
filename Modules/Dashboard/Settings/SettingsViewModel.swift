//
//  SettingsViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI
import Observation

// MARK: - SettingsViewModel

@Observable
final class SettingsViewModel {

    // MARK: - Distance Unit (Firestore-backed, fallback = .miles)
    var selectedUnit: MeasureUnit = .miles {
        didSet {
            guard selectedUnit != oldValue else { return }
            persistDistanceUnit(selectedUnit)
        }
    }

    // MARK: - Developed By expansion
    var isDevelopedByExpanded: Bool = false

    // MARK: - Menu Items
    var menuItems: [SettingsMenuItem] {
        [
            SettingsMenuItem(id: .notifications,   icon: .icNotificationWhile, title: .notifications),
            SettingsMenuItem(id: .privacyPolicy,   icon: .icPrivacy,           title: .privacyPolicy),
            SettingsMenuItem(id: .termsConditions, icon: .icTerms,             title: .termsOfService),
            SettingsMenuItem(id: .licenses,        icon: .icLicense,           title: .licenses),
            SettingsMenuItem(id: .developedBy,     icon: .icDeveloper,         title: .developedBy),
        ]
    }

    // MARK: - Init

    init() {
        // Load from cached UserModel (fetched from Firestore on login). Fall back to .miles.
        self.selectedUnit = AuthManager.shared.userDetails?.distanceUnit ?? .miles
    }

    // MARK: - Alerts

    /// Presents the logout confirmation alert.
    func showLogoutAlert(onConfirm: @escaping () -> Void) {
        AppAlertManager.shared.present(
            AppAlertModel(
                title: "Take a quick break?",
                description: "Your events and Garmin sync will be waiting when you return.",
                primaryButton: AppAlertButton("Keep Going"),
                secondaryButton: AppAlertButton("Log Out", action: onConfirm)
            )
        )
    }

    /// Presents the delete-account confirmation alert.
    func showDeleteAccountAlert(onConfirm: @escaping () -> Void) {
        AppAlertManager.shared.present(
            AppAlertModel(
                title: "Start Fresh?",
                description: "Create a new Pace App experience anytime. Your next race adventure awaits!",
                primaryButton: AppAlertButton("Stay With Me"),
                secondaryButton: AppAlertButton("New Start", action: onConfirm),
                restrictOutsideTap: false
            )
        )
    }

    // MARK: - Private Helpers

    private func persistDistanceUnit(_ unit: MeasureUnit) {
        guard let currentUID = AuthManager.shared.currentUserID else { return }
        // Keep the in-memory model in sync
        AuthManager.shared.userDetails?.distanceUnit = unit
        Task {
            try? await UserProfileRepository.shared.updateDistanceUnit(unit, userId: currentUID)
        }
    }
}
