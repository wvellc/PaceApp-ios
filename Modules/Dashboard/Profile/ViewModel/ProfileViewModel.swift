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
        didSet { persistToggle(\.isIntvlVibrateOn, value: isIntvlVibrateOn) }
    }
    var isIntvlBeepOn: Bool = false {
        didSet { persistToggle(\.isIntvlBeepOn, value: isIntvlBeepOn) }
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
        lastName = user?.lastName
        gender = user?.gender
        contactInfo = user?.contactInfo ?? ""
        // Load toggle states from cached user model (fetched from Firestore on login)
        isIntvlVibrateOn = user?.intervalVibrate ?? false
        isIntvlBeepOn    = user?.intervalBeep    ?? false
    }

    // MARK: - Update Profile Action

    func updateProfile(
        firstName: String,
        lastName: String
    ) {
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

    // MARK: - Private Helpers

    /// Persists a Bool toggle to Firestore and keeps the cached UserModel in sync.
    private func persistToggle(_ keyPath: WritableKeyPath<UserModel, Bool?>, value: Bool) {
        guard let currentUID = AuthManager.shared.currentUserID else { return }

        // Keep the in-memory model in sync so re-loading from session reflects the change
        AuthManager.shared.userDetails?[keyPath: keyPath] = value

        Task {
            do {
                switch keyPath {
                case \.intervalVibrate:
                    try await UserProfileRepository.shared.updateIntervalVibrate(value, userId: currentUID)
                case \.intervalBeep:
                    try await UserProfileRepository.shared.updateIntervalBeep(value, userId: currentUID)
                default:
                    break
                }
            } catch {
                // Non-fatal: swallow and let the next full sync correct the value
            }
        }
    }
}
