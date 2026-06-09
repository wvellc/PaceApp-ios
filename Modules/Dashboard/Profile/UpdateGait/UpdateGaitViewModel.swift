//
//  UpdateGaitViewModel.swift
//  PaceApp
//

import SwiftUI
import Observation

@Observable
final class UpdateGaitViewModel {

    // MARK: - State

    /// Live gait data being edited — initialised from Firestore-cached UserModel.
    var gaitData: GaitUserData

    /// The gender drives default step lengths in GaitSelectionView.
    var gender: Gender

    // MARK: - Init

    init() {
        let user = AuthManager.shared.userDetails
        self.gender = user?.gender ?? .male
        // Seed from the cached user model; fall back to gender defaults if no gait saved yet.
        self.gaitData = user?.gait ?? (user?.gender ?? .male).defaultGaitData
    }

    // MARK: - Actions

    /// Called by GaitSelectionView when the user changes running gait values.
    func updateRunning(_ data: GaitData) {
        gaitData.runningData = data
    }

    /// Called by GaitSelectionView when the user changes walking gait values.
    func updateWalking(_ data: GaitData) {
        gaitData.walkingData = data
    }

    /// Persists the current gaitData to Firestore and updates the in-memory UserModel.
    func save() {
        guard let currentUID = AuthManager.shared.currentUserID else { return }
        let snapshot = gaitData
        // Keep in-memory model in sync immediately
        AuthManager.shared.userDetails?.gait = snapshot
        Task {
            try? await UserProfileRepository.shared.updateGait(snapshot, userId: currentUID)
        }
    }
}
