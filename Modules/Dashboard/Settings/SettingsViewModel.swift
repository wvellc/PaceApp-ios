//
//  DistanceUnit.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI
import Observation

// MARK: - SettingsViewModel

@Observable
final class SettingsViewModel {

    // MARK: - Distance Unit
    var selectedUnit: MeasureUnit = .miles {
		didSet {
			// This runs every time selectedUnit is changed
			AppSession.userDistanceUnit = selectedUnit
		}
	}

    // MARK: - Developed By expansion
    var isDevelopedByExpanded: Bool = false

    // MARK: - Menu Items
    var menuItems: [SettingsMenuItem] {
        [
			SettingsMenuItem(id: .notifications,    icon: .icNotificationWhile,  	title: .notifications),
			SettingsMenuItem(id: .privacyPolicy,    icon: .icPrivacy,       		title: .privacyPolicy),
			SettingsMenuItem(id: .termsConditions,  icon: .icTerms,         		title: .termsOfService),
			SettingsMenuItem(id: .licenses,         icon: .icLicense,       		title: .licenses),
			SettingsMenuItem(id: .developedBy,      icon: .icDeveloper,     		title: .developedBy),
        ]
    }

	//MARK: Initializer
	init() {
		// Pull the initial state from your static persistence layer
		self.selectedUnit = AppSession.userDistanceUnit
	}
	
	// MARK: - Alerts

	/// Presents the logout confirmation alert.
	/// Pass `onConfirm` to receive the "Log Out" tap callback.
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
	/// Pass `onConfirm` to receive the "New Start" tap callback.
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
}
