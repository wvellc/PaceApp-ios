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

    private(set) var ciqManager: ConnectIQManager?

    // MARK: - Step state

    var currentStep: ManageWatchStep = .currentConnected
    var slideDirection: SlideDirection = .forward

    // MARK: - Watch state

    /// Mirrors `ciqManager.connectedDevice` — the currently live watch.
    /// Kept in sync via `syncFromManager()`, which ManageWatchScreen calls
    /// on `onChange(of: ciqManager.connectedDevice?.uuid)`.
    var connectedWatch: IQDevice? = nil

    /// Device the user has highlighted in the ChooseYourModel list.
    var selectedWatch: IQDevice? = nil

    // MARK: - Dynamic footer title

    var footerButtonTitle: String {
        switch currentStep {
        case .currentConnected:
			return selectedWatch != nil ? "Disconnect Device" : "Connect Device"
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
		syncSelectedWatch()

    }

    // MARK: - Live sync

    /// Read `ciqManager.connectedDevice` (stored var on ConnectIQManager) and
    /// mirror it into `connectedWatch`.  This is the only path that writes
    /// `connectedWatch` outside of `onFooterTapped`.
    ///
    /// Called by ManageWatchScreen's `.onChange(of: ciqManager.connectedDevice?.uuid)`
    /// which fires reliably because `connectedDevice` is now a stored @Observable var.
    func syncFromManager() {
        connectedWatch = ciqManager?.connectedDevice
    }

    /// Keep `selectedWatch` pointing at a valid entry in the current device list.
    func syncSelectedWatch() {
        guard let devices = ciqManager?.devices else { return }
        if let pick = selectedWatch, devices.contains(where: { $0.uuid == pick.uuid }) { return }
		
		if let firstDevice = devices.first {
			selectedWatch = firstDevice
			
			currentStep = devices.count == 1 ?  .currentConnected : .chooseYourModel
			
		} else {
//			if currentStep == .chooseYourModel {
//				self.onBack()
				selectedWatch = nil
				currentStep = .pairWatch
//				ToastManager.shared.present(.error("No watch connected. Pair again."))
//			}
		}
    }

    // MARK: - onFooterTapped

    /// State machine for the primary action button.
    ///
    /// .currentConnected
    ///   • watch present → Disconnect → advance to .pairWatch
    ///   • watch absent  → advance directly to .pairWatch  ("Connect Device")
    ///
    /// .pairWatch
    ///   → Open Garmin Connect, advance to .chooseYourModel
    ///
    /// .chooseYourModel
    ///   → Commit selectedWatch, re-register app, return to .currentConnected
    func onFooterTapped() {
        switch currentStep {

        case .currentConnected:
				if selectedWatch != nil {
                // Wipes all persistence + state; connectedDevice in manager → nil
                // which fires onChange in the Screen → syncFromManager() → connectedWatch = nil
                ciqManager?.disconnectFromApp()
            }
            advance()

        case .pairWatch:
            ciqManager?.findDevices()
            advance()

        case .chooseYourModel:
            guard let watch = selectedWatch else { return }
			ciqManager?.connectToApp(device: watch)
            // Optimistically mirror before deviceStatusChanged fires
            connectedWatch = watch
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
    /// .currentConnected  → dismiss (already at root)
    /// .pairWatch
    ///   • connectedWatch set → back to .currentConnected
    ///   • connectedWatch nil → dismiss (nothing to show on the "current" screen)
    /// .chooseYourModel   → always back to .pairWatch
    func onBack() {
        switch currentStep {

        case .currentConnected:
            navigationEvent = .dismiss

        case .pairWatch:
            if connectedWatch != nil {
                slideDirection = .backward
                withAnimation(.easeInOut(duration: 0.3)) { currentStep = .currentConnected }
            } else {
                navigationEvent = .dismiss
            }

        case .chooseYourModel:
            slideDirection = .backward
            withAnimation(.easeInOut(duration: 0.3)) { currentStep = .pairWatch }
        }
    }

    // MARK: - Private

    private func advance() {
        guard let next = currentStep.next else { navigationEvent = .dismiss; return }
        slideDirection = .forward
        withAnimation(.easeInOut(duration: 0.3)) { currentStep = next }
    }
}
