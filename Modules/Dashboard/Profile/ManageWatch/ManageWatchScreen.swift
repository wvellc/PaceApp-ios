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
	
	@Environment(Router.self)           private var router
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
		// connectedDevice is now a stored @Observable var — this onChange fires
		// reliably whenever deviceStatusChanged() updates it (live BT change or
		// cold-launch restore).  Syncing here keeps connectedWatch in the VM
		// always reflecting ground truth from the manager.
		.onChange(of: ciqManager.connectedDevice?.uuid) { _, _ in
			viewModel.syncFromManager()
		}
		// When GCM returns a new device list, refresh selectedWatch.
		.onChange(of: ciqManager.devices.count) { _, _ in
			viewModel.syncSelectedWatch()
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
		AppButton(LocalizedStringResource(stringLiteral: viewModel.footerButtonTitle)) {
			viewModel.onFooterTapped()
		}
	}
	
	// MARK: - Slide Transition
	
	private var slideTransition: AnyTransition {
		let insert: AnyTransition = viewModel.slideDirection == .forward ? .move(edge: .trailing) : .move(edge: .leading)
		let remove: AnyTransition = viewModel.slideDirection == .forward ? .move(edge: .leading)  : .move(edge: .trailing)
		return .asymmetric(insertion: insert, removal: remove)
	}
	
	// MARK: - Navigation Handler
	
	private func handleNavigation(_ event: ManageWatchViewModel.NavigationEvent) {
		switch event {
			case .dismiss: router.navigateBack()
		}
	}
}

// MARK: - ManageChooseDevicesStepView

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
		.onAppear { viewModel.syncSelectedWatch() }
		.onChange(of: viewModel.ciqManager?.devices.count ?? 0) { _, _ in
			viewModel.syncSelectedWatch()
		}
	}
}

// MARK: - Preview

#Preview {
	NavigationStack { ManageWatchScreen() }
		.environment(Router())
}
