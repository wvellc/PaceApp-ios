//
//  ManageWatchViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI
import ConnectIQ

// MARK: - ManageWatchViewModel

@Observable
final class ManageWatchViewModel {

    // MARK: - Watch Manager

    /// Injected once from ManageWatchScreen.onAppear via configure(ciqManager:).
    /// Views read ciqManager.devices / ciqManager.deviceStatus directly so
    /// @Observable propagates changes without any Combine subscriptions.
    private(set) var ciqManager: ConnectIQManager?

    // MARK: - Step state

    var currentStep: ManageWatchStep = .currentConnected
    var slideDirection: SlideDirection = .forward

    // MARK: - Watch state

    /// The device currently treated as "connected" by this flow.
    /// • Seeded from ciqManager.connectedDevice on configure().
    /// • Kept live by syncFromManager(), which the Screen calls on every
    ///   deviceStatus / connectedDevice change.
    var connectedWatch: IQDevice? = nil

    /// Device highlighted by the user in the ChooseYourModel list.
    var selectedWatch: IQDevice? = nil

    // MARK: - Dynamic footer title

    /// The footer label for .currentConnected changes depending on whether
    /// a watch is already paired.
    var footerButtonTitle: String {
        switch currentStep {
        case .currentConnected:
            return connectedWatch != nil ? "Disconnect Device" : "Connect Device"
        case .pairWatch:
            return ManageWatchStep.pairWatch.footerButtonTitle
        case .chooseYourModel:
            return ManageWatchStep.chooseYourModel.footerButtonTitle
        }
    }

    // MARK: - Supporting types

    enum SlideDirection { case forward, backward }

    enum NavigationEvent { case dismiss }
    var navigationEvent: NavigationEvent?

    // MARK: - Injection

    /// Call once from ManageWatchScreen.onAppear.
    func configure(ciqManager: ConnectIQManager) {
        guard self.ciqManager == nil else { return }
        self.ciqManager = ciqManager
        syncFromManager()
    }

    // MARK: - Live sync

    /// Mirror the manager's live connectedDevice into our local connectedWatch.
    /// Call from the Screen's .onChange(of: ciqManager.connectedDevice) so the
    /// "Manage your watch" step always shows the current reality.
    func syncFromManager() {
        connectedWatch = ciqManager?.connectedDevice ?? ciqManager?.devices.first
    }

    /// Keep selectedWatch pointing at a valid entry in the current device list.
    /// Called from ManageChooseDevicesStepView.onAppear and onChange(of: devices.count).
    func syncSelectedWatch() {
        guard let devices = ciqManager?.devices else { return }
        // Preserve existing choice if it is still in the list
        if let pick = selectedWatch, devices.contains(where: { $0.uuid == pick.uuid }) { return }
        selectedWatch = devices.first
    }

    // MARK: - onFooterTapped

    /// State machine for the primary action button.
    ///
    /// .currentConnected
    ///   • watch present  → Disconnect → advance to .pairWatch
    ///   • watch absent   → advance directly to .pairWatch (act as "Connect")
    ///
    /// .pairWatch
    ///   → Open Garmin Connect, then advance to .chooseYourModel
    ///
    /// .chooseYourModel
    ///   → Commit selectedWatch, re-register app, go back to .currentConnected
    func onFooterTapped() {
        switch currentStep {

        // ── Step 1: Manage current watch ──────────────────────────────────
        case .currentConnected:
            if connectedWatch != nil {
                // Disconnect: un-register listeners, wipe persistence, clear local state
                ciqManager?.disconnectFromApp()
                connectedWatch = nil
                selectedWatch  = nil
            }
            // Whether we disconnected or had no watch, proceed to pair a new one
            advance()

        // ── Step 2: Pair Watch prompt ─────────────────────────────────────
        case .pairWatch:
            // Launch Garmin Connect for device selection.
            // handleOpenURL() in PaceApp will call ciqManager.handleOpenURL(_:)
            // which populates ciqManager.devices, triggering @Observable updates.
            ciqManager?.findDevices()
            advance()

        // ── Step 3: Choose device from list ───────────────────────────────
        case .chooseYourModel:
            guard let watch = selectedWatch else { return }
            // Re-register app messaging for the newly chosen device
            ciqManager?.connectToApp(uuidString: watch.uuid.uuidString, device: watch)
            // Promote to connectedWatch
            connectedWatch = watch
            // Slide back to the summary step
            slideDirection = .backward
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .currentConnected
            }
            ToastManager.shared.present(
                .success(String(localized: "\(watch.modelName ?? "Watch") is connected"))
            )
        }
    }

    // MARK: - onBack

    /// Back-button state machine.
    ///
    /// .currentConnected → dismiss the screen (already at root)
    ///
    /// .pairWatch
    ///   • connectedWatch still set  → slide back to .currentConnected
    ///   • connectedWatch nil        → dismiss (no point showing empty "current" screen)
    ///
    /// .chooseYourModel → always slide back to .pairWatch
    func onBack() {
        switch currentStep {

        case .currentConnected:
            // Root step — dismiss the whole Manage Watch screen
            navigationEvent = .dismiss

        case .pairWatch:
            if connectedWatch != nil {
                // There is still a paired watch to show
                slideDirection = .backward
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .currentConnected
                }
            } else {
                // User disconnected and then tapped Back — nothing to show upstream
                navigationEvent = .dismiss
            }

        case .chooseYourModel:
            // Always allow going back to the "Start Pairing" screen
            slideDirection = .backward
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .pairWatch
            }
        }
    }

    // MARK: - Private helpers

    private func advance() {
        guard let next = currentStep.next else {
            navigationEvent = .dismiss
            return
        }
        slideDirection = .forward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = next
        }
    }
}
