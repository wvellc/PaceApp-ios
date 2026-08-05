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
            // Skip persistence when the value is being synced in from a remote
            // (watch → Firestore) update — that would echo the write straight back.
            guard !isApplyingRemote, isIntvlVibrateOn != oldValue else { return }
            persistIntervalVibrate(isIntvlVibrateOn)
        }
    }

    var isIntvlBeepOn: Bool = false {
        didSet {
            guard !isApplyingRemote, isIntvlBeepOn != oldValue else { return }
            persistIntervalBeep(isIntvlBeepOn)
        }
    }

    /// True while `loadUserInfoFromSession` is applying remote values, so the
    /// toggle `didSet`s don't persist a value that just arrived from Firestore.
    @ObservationIgnored private var isApplyingRemote = false

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
                id: .stravaIntegration,
                icon: .icSync,
                title: "Connect Strava",
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
        // Sync toggles from the live model without echoing the value back to Firestore.
        isApplyingRemote = true
        isIntvlVibrateOn = user?.intervalVibrate ?? false
        isIntvlBeepOn    = user?.intervalBeep    ?? false
        isApplyingRemote = false
    }

    // MARK: - Update Profile Action

    var isUpdatingProfile = false

    func updateProfile(firstName: String, lastName: String) async -> Bool {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName  = lastName.trimmingCharacters(in: .whitespaces)

        guard let currentUID = AuthManager.shared.currentUserID else { return false }
        var user = AuthManager.shared.userDetails ?? UserModel(uuid: currentUID)
        user.firstName = trimmedFirstName
        user.lastName  = trimmedLastName

        isUpdatingProfile = true
        defer { isUpdatingProfile = false }

        do {
            try await UserProfileRepository.shared.upsertProfile(user, userId: currentUID)
            self.firstName = trimmedFirstName
            self.lastName  = trimmedLastName
            AuthManager.shared.userDetails = user
            return true
        } catch {
            ToastManager.shared.present(.error("Couldn't update your profile. Please try again."))
            return false
        }
    }

    // MARK: - Private Persistence Helpers

    private func persistIntervalVibrate(_ enabled: Bool) {
        guard let uid = AuthManager.shared.currentUserID else { return }
        AuthManager.shared.userDetails?.intervalVibrate = enabled
        // Push the updated settings to the watch (app → watch).
        ConnectIQManager.shared.sendSettings()
        Task { try? await UserProfileRepository.shared.updateIntervalVibrate(enabled, userId: uid) }
    }

    private func persistIntervalBeep(_ enabled: Bool) {
        guard let uid = AuthManager.shared.currentUserID else { return }
        AuthManager.shared.userDetails?.intervalBeep = enabled
        // Push the updated settings to the watch (app → watch).
        ConnectIQManager.shared.sendSettings()
        Task { try? await UserProfileRepository.shared.updateIntervalBeep(enabled, userId: uid) }
    }
}
