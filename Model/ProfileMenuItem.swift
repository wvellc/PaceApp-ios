//
//  ProfileMenuItem.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import DeveloperToolsSupport


// MARK: - ProfileMenuItem Model
struct ProfileMenuItem: Identifiable {
    let id: ProfileMenuItemID
    let icon: ImageResource
    let title: String
    let type: ProfileMenuItemType
}

enum ProfileMenuItemID {
    case manageWatch
    case stravaIntegration
    case intvlVibrate
    case intvlBeep
    case setGait
}

