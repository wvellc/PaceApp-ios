//
//  DistanceUnit.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//


//
//  SettingsViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import SwiftUI
import Observation

// MARK: - SettingsViewModel

@Observable
final class SettingsViewModel {

    // MARK: - Distance Unit
    var selectedUnit: DistanceType = .miles

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
}
