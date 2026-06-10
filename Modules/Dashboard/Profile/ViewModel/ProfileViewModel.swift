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
    var firstName: String?
    var lastName: String?
    var gender: Gender?
    var contactInfo: String = ""

    // MARK: - Toggle States (Firestore-backed, fallback = false)

    var isIntvlVibrateOn: Bool = false {
        didSet {
            guard isIntvlVibrateOn != oldValue else { return }
            persistIntervalVibrate(isIntvlVibrateOn)
        }
    }

    var isIntvlBeepOn: Bool = false {
        didSet {
            guard isIntvlBeepOn != oldValue else { return }
            persistIntervalBeep(isIntvlBeepOn)
        }
    }

    // MARK: - Init

    init() {
        loadUserInfoFromSession()
    }

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

    // MARK: - Session

    func loadUserInfoFromSession() {
        let user = AuthManager.shared.userDetails
        firstName = user?.firstName
        lastName  = user?.lastName
        gender    = user?.gender
        contactInfo = user?.contactInfo ?? ""
        // Seed toggles from the Firestore-cached model; no didSet fires during init assignment
        isIntvlVibrateOn = user?.intervalVibrate ?? false
        isIntvlBeepOn    = user?.intervalBeep    ?? false
    }

    // MARK: - Update Profile Action

    func updateProfile(firstName: String, lastName: String) {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName  = lastName.trimmingCharacters(in: .whitespaces)

        self.firstName = trimmedFirstName
        self.lastName  = trimmedLastName

        guard let currentUID = AuthManager.shared.currentUserID else { return }
        var user = AuthManager.shared.userDetails ?? UserModel(uuid: currentUID)
        user.firstName = trimmedFirstName
        user.lastName  = trimmedLastName
        AuthManager.shared.userDetails = user

        Task {
            try? await UserProfileRepository.shared.upsertProfile(user, userId: currentUID)
        }
    }

    // MARK: - Private Persistence Helpers

    private func persistIntervalVibrate(_ enabled: Bool) {
        guard let uid = AuthManager.shared.currentUserID else { return }
        AuthManager.shared.userDetails?.intervalVibrate = enabled
        Task { try? await UserProfileRepository.shared.updateIntervalVibrate(enabled, userId: uid) }
    }

    private func persistIntervalBeep(_ enabled: Bool) {
        guard let uid = AuthManager.shared.currentUserID else { return }
        AuthManager.shared.userDetails?.intervalBeep = enabled
        Task { try? await UserProfileRepository.shared.updateIntervalBeep(enabled, userId: uid) }
    }
}
