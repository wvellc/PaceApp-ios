
//
//  ManageWatchScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

// MARK: - ManageWatchScreen

struct ManageWatchScreen: View {

    // MARK: Environment

    @Environment(Router.self) private var router

    // MARK: State

    @State private var viewModel = ManageWatchViewModel()

    // MARK: Body

    var body: some View {
        BackgroundContainer {
            GeometryReader { geo in
                VStack(spacing: 0) {

                    // Navigation bar spacing
                    VSpace(height: geo.safeAreaInsets.top, isProportional: false)

                    // Step content with slide transition
                    stepContent
                        .transition(slideTransition)
                        .id(viewModel.currentStep)

                    // Shared footer button
                    footerButton
                        .padding(.horizontal, 16)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 32)
                }
            }
        }
        .navigationTitle(viewModel.currentStep.title)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { topToolbar }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: viewModel.navigationEvent) { _, event in
            guard let event else { return }
            handleNavigation(event)
            viewModel.navigationEvent = nil
        }
    }

    // MARK: - Top Toolbar

    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
        if viewModel.currentStep.showsBack {
            AppBackButtonToolbarContent(onTap: viewModel.onBack)
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.currentStep.title)
                .font(.medium17)
                .foregroundStyle(.whiteApp)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
            case .currentConnected:
                ConnectWatchStepView(watch: viewModel.connectedWatch)
            case .pairWatch:
                PairWatchStepView()
            case .chooseYourModel:
                ManageChooseDevicesStepView(viewModel: viewModel)
        }
    }

    // MARK: - Footer Button

    private var footerButton: some View {
        AppButton(LocalizedStringResource(stringLiteral: viewModel.currentStep.footerButtonTitle)) {
            viewModel.onFooterTapped()
        }
    }

    // MARK: - Slide Transition

    private var slideTransition: AnyTransition {
        let insertion: AnyTransition = viewModel.slideDirection == .forward
            ? .move(edge: .trailing)
            : .move(edge: .leading)
        let removal: AnyTransition = viewModel.slideDirection == .forward
            ? .move(edge: .leading)
            : .move(edge: .trailing)
        return .asymmetric(insertion: insertion, removal: removal)
    }

    // MARK: - Navigation Handler

    private func handleNavigation(_ event: ManageWatchViewModel.NavigationEvent) {
        switch event {
            case .dismiss:
                router.navigateBack()
        }
    }
}

// MARK: - ManageChooseDevicesStepView

/// Mirrors ChooseDevicesStepView but bound to ManageWatchViewModel.
private struct ManageChooseDevicesStepView: View {

    @Bindable var viewModel: ManageWatchViewModel

    var body: some View {
        VStack(spacing: 0) {
            VSpace(height: 24)

            // Device list
            VStack(spacing: 16) {
                ForEach(viewModel.discoveredDevices) { device in
                    WatchDeviceRow(
                        device: device,
                        isSelected: viewModel.selectedWatch?.id == device.id
                    ) {
                        viewModel.selectedWatch = device
                    }
                }
            }

            Spacer()
        }
        .clipped()
        .onAppear {
            if viewModel.selectedWatch == nil {
                viewModel.selectedWatch = viewModel.discoveredDevices.first
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ManageWatchScreen()
    }
    .environment(Router())
}
