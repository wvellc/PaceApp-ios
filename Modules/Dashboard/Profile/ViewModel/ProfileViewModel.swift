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
	var firstName: String? = "Jason"
	var lastName: String? = "Holder"
    var userEmail: String = "hjasaon@gmail.com"
    var avatarURL: String = "www.https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=880&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"

    // MARK: - Toggle States
    var isIntvlVibrateOn: Bool = true
    var isIntvlBeepOn: Bool = true

    // MARK: - Menu Items
    var menuItems: [ProfileMenuItem] {
        [
            ProfileMenuItem(
                id: .manageWatch,
                icon: .icWatch,
                title: "Manage your watch!",
                type: .navigation
            ),
            ProfileMenuItem(
                id: .intvlVibrate,
                icon: .icVibrate,
                title: "Intvl Vibrate",
                type: .toggle(binding: { [weak self] val in
                    self?.isIntvlVibrateOn = val
                }, value: isIntvlVibrateOn)
            ),
            ProfileMenuItem(
                id: .intvlBeep,
                icon: .icBeep,
                title: "Intvl Beep",
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
		lastName: String,
		selectedImage: UIImage?
	) {
		self.firstName = firstName.trimmingCharacters(in: .whitespaces)
		self.lastName = lastName.trimmingCharacters(in: .whitespaces)
		
		if let image = selectedImage,
		   let data = image.jpegData(compressionQuality: 0.8) {
			// In a real app: upload data to server, then update avatarURL
			_ = data
		}
	}
}

