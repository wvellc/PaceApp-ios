//
//  ProfileViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//


//
//  ProfileViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import SwiftUI
import Observation

@Observable
final class ProfileViewModel {

    // MARK: - User Info
	var firstName: String? = "Max"
	var lastName: String? = "Well"
    var userEmail: String = "hjasaon@gmail.com"

    // MARK: - Toggle States
    var isIntvlVibrateOn: Bool = true
    var isIntvlBeepOn: Bool = true

    // MARK: - Menu Items
    var menuItems: [ProfileMenuItem] {
        [
            ProfileMenuItem(
                id: .manageWatch,
                icon: .icWatch,
                title: "Manage your watch",
                type: .navigation
            ),
            ProfileMenuItem(
                id: .intvlVibrate,
                icon: .icVibrate,
                title: "Interval Vibrate",
                type: .toggle(binding: { [weak self] val in
                    self?.isIntvlVibrateOn = val
                }, value: isIntvlVibrateOn)
            ),
            ProfileMenuItem(
                id: .intvlBeep,
                icon: .icBeep,
                title: "Interval Beep",
                type: .toggle(binding: { [weak self] val in
                    self?.isIntvlBeepOn = val
                }, value: isIntvlBeepOn)
            ),
            ProfileMenuItem(
                id: .setGait,
                icon: .icGait,
                title: "Set Gait",
                type: .navigation
            )
        ]
    }
	
	
	// MARK: - Update Profile Action
	func updateProfile(
		firstName: String,
		lastName: String
	) {
		self.firstName = firstName.trimmingCharacters(in: .whitespaces)
		self.lastName = lastName.trimmingCharacters(in: .whitespaces)
	}
}
