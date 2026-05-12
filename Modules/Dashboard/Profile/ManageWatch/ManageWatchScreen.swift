//
//  ManageWatchScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI
import ConnectIQ

// MARK: - ManageWatchScreen

struct ManageWatchScreen: View {
	
	// MARK: - Environment
	
	@Environment(Router.self) private var router
	@Environment(ConnectIQManager.self) private var ciqManager
	
	// MARK: - State
	
	@State private var viewModel = ManageWatchViewModel()
	
	// MARK: - Body
	
	var body: some View {
		BackgroundContainer {
			GeometryReader { geo in
				VStack(spacing: 0) {
					VSpace(height: geo.safeAreaInsets.top, isProportional: false)
					
					stepContent
						.transition(slideTransition)
						.id(viewModel.currentStep)
					
					// Uses viewModel.footerButtonTitle (dynamic) instead of the
					// static ManageWatchStep.footerButtonTitle so "Connect Device"
					// vs "Disconnect Device" reflects whether a watch is paired.
					footerButton
						.padding(.horizontal, 16)
						.padding(.bottom, geo.safeAreaInsets.bottom + 32)
				}
			}
		}
		.navigationBarBackButtonHidden(true)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar { topToolbar }
		.toolbarBackground(.hidden, for: .navigationBar)
		.onChange(of: viewModel.navigationEvent) { _, event in
			guard let event else { return }
			handleNavigation(event)
			viewModel.navigationEvent = nil
		}
		// ── Live status sync ─────────────────────────────────────────────
		// deviceStatus changes whenever the SDK fires deviceStatusChanged(_:status:).
		// We mirror that into connectedWatch so the "Manage your watch" step
		// shows the real-time connection state (connected / not connected).
		.onChange(of: ciqManager.deviceStatus) { _, _ in
			viewModel.syncFromManager()
		}
		// connectedDevice is a computed property on ConnectIQManager derived from
		// deviceStatus, but observing it separately catches any edge-case where
		// the computed result changes without deviceStatus itself being reassigned.
		.onChange(of: ciqManager.connectedDevice?.uuid) { _, _ in
			viewModel.syncFromManager()
		}
		// ── Device list sync ─────────────────────────────────────────────
		// When Garmin Connect deep-link returns new devices, refresh selectedWatch.
		.onChange(of: ciqManager.devices.count) { _, _ in
			viewModel.syncSelectedWatch()
			// Also re-evaluate connectedWatch in case a newly added device is
			// already in .connected status.
			viewModel.syncFromManager()
		}
		.onAppear {
			viewModel.configure(ciqManager: ciqManager)
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
				.font(.medium16)
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
		// viewModel.footerButtonTitle is a computed var that returns
		// "Connect Device" or "Disconnect Device" based on connectedWatch.
		AppButton(LocalizedStringResource(stringLiteral: viewModel.footerButtonTitle)) {
			viewModel.onFooterTapped()
		}
	}
	
	// MARK: - Slide Transition
	
	private var slideTransition: AnyTransition {
		let insertion: AnyTransition = viewModel.slideDirection == .forward
		? .move(edge: .trailing) : .move(edge: .leading)
		let removal: AnyTransition = viewModel.slideDirection == .forward
		? .move(edge: .leading)  : .move(edge: .trailing)
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

/// Device-picker step bound to ManageWatchViewModel.
/// Reads ciqManager.devices via the ViewModel so @Observable re-renders the
/// list whenever Garmin Connect's deep-link callback populates devices.
private struct ManageChooseDevicesStepView: View {
	
	@Bindable var viewModel: ManageWatchViewModel
	
	var body: some View {
		VStack(spacing: 0) {
			VSpace(height: 24)
			
			VStack(spacing: 16) {
				let devices = viewModel.ciqManager?.devices ?? []
				ForEach(devices, id: \.uuid) { device in
					WatchDeviceRow(
						device: device,
						isSelected: viewModel.selectedWatch?.uuid == device.uuid
					) {
						viewModel.selectedWatch = device
					}
				}
			}
			
			Spacer()
		}
		.clipped()
		.onAppear {
			viewModel.syncSelectedWatch()
		}
		.onChange(of: viewModel.ciqManager?.devices.count ?? 0) { _, _ in
			viewModel.syncSelectedWatch()
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
