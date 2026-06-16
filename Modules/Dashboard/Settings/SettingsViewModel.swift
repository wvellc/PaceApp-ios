//
//  SettingsViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI
import Combine

/// Local view model for SettingScreen. Do not share outside this screen.
@Observable
final class SettingsViewModel {
	
	// MARK: - Properties
	var selectedUnit: MeasureUnit = .miles
	var isDevelopedByExpanded: Bool = false
	
	// MARK: - Menu Items
	let menuItems: [SettingsMenuItem] = [
		SettingsMenuItem(id: .notifications,   icon: .icNotificationWhile, title: .notifications),
		SettingsMenuItem(id: .privacyPolicy,   icon: .icPrivacy,           title: .privacyPolicy),
		SettingsMenuItem(id: .termsConditions, icon: .icTerms,             title: .termsOfService),
		SettingsMenuItem(id: .licenses,        icon: .icLicense,           title: .licenses),
		SettingsMenuItem(id: .developedBy,     icon: .icDeveloper,         title: .developedBy),
	]
	
	// MARK: - Combine
	private var cancellables = Set<AnyCancellable>()
	private let saveSubject = PassthroughSubject<MeasureUnit, Never>()
	
	// MARK: - Init
	init() {
		loadInitialValue()
		setupBindings()
	}
	
	private func loadInitialValue() {
		selectedUnit = AuthManager.shared.userDetails?.distanceUnit ?? .miles
	}
	
	private func setupBindings() {
		// Auto-save with debounce when value changes
		saveSubject
			.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
			.sink { [weak self] unit in
				self?.persistDistanceUnit(unit)
			}
			.store(in: &cancellables)
	}
	
	// MARK: - Update Method (Recommended way to change value)
	func updateDistanceUnit(_ newUnit: MeasureUnit) {
		guard newUnit != selectedUnit else { return }
		selectedUnit = newUnit
		saveSubject.send(newUnit)
	}
	
	// MARK: - Alerts
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
	
	// MARK: - Private
	private func persistDistanceUnit(_ unit: MeasureUnit) {
		guard let currentUID = AuthManager.shared.currentUserID else { return }
		
		// Keep in-memory model in sync
		AuthManager.shared.userDetails?.distanceUnit = unit
		
		Task {
			try? await UserProfileRepository.shared.updateDistanceUnit(unit, userId: currentUID)
		}
	}
	
	deinit {
		cancellables.removeAll()
	}
}
