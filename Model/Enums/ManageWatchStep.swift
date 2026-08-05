//
//  ManageWatchStep.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/12/26.
//

// MARK: - ManageWatchStep

/// Ordered steps for the Manage Watch flow.
enum ManageWatchStep: Int, CaseIterable {
    /// Shows the currently connected watch (or "no watch" placeholder).
    case currentConnected
    /// Prompts the user to open Garmin Connect for device selection.
    case pairWatch
    /// Lists discovered watches so the user can choose one to pair.
    case chooseYourModel

    // MARK: - Navigation helpers

    var next: ManageWatchStep?     { ManageWatchStep(rawValue: rawValue + 1) }
    var previous: ManageWatchStep? { ManageWatchStep(rawValue: rawValue - 1) }

    // MARK: - Nav-bar title

    var title: String {
        switch self {
        case .currentConnected: return "Manage your watch"
        case .pairWatch:        return "Pair Watch"
        case .chooseYourModel:  return "Choose your model"
        }
    }

    // MARK: - Footer button label
    // The .currentConnected label is dynamic — see ManageWatchViewModel.footerButtonTitle

    var footerButtonTitle: String {
        switch self {
        case .currentConnected: return "Disconnect Device"   // overridden dynamically in VM
        case .pairWatch:        return "Start Pairing"
        case .chooseYourModel:  return "Pair"
        }
    }

    // MARK: - Visibility flags

    var showsBack: Bool { true }
}
