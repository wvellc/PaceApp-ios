//
//  UpdateGaitScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

/// Full-screen gait editor reachable from Profile → Set Gait.
/// Reads initial values from Firestore (via AuthManager.userDetails) and
/// writes back via UpdateGaitViewModel.save() on close.
struct UpdateGaitScreen: View {

    // MARK: Environment
    @Environment(\.dismiss) var dismiss

    // MARK: ViewModel
    @State private var viewModel = UpdateGaitViewModel()

    // MARK: Body

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                SetGaitStepView(
                    gender: viewModel.gender,
                    gaitData: viewModel.gaitData,
                    onRunningChange: { viewModel.updateRunning($0) },
                    onWalkingChange: { viewModel.updateWalking($0) }
                )
            }
            .scrollBounceBehavior(.basedOnSize)

            AppButton(.close) {
                viewModel.save()
                dismiss()
            }
        }
        .padding(Constant.UI.defaultPadding)
        .appBackground()
    }
}

#Preview {
    UpdateGaitScreen()
}
