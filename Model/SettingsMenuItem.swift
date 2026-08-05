//
//  SettingsMenuItem.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import DeveloperToolsSupport
import Foundation

// MARK: - Settings Menu Item

struct SettingsMenuItem: Identifiable {
    let id: SettingsMenuItemID
    let icon: ImageResource
	let title: LocalizedStringResource
}

enum SettingsMenuItemID: Hashable {
    case notifications
    case faq
    case privacyPolicy
    case termsConditions
    case licenses
    case developedBy
}
