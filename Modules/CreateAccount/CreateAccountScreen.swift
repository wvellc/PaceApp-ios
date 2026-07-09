//
//  CreateAccountScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI

// MARK: - CreateAccountScreen

/// Root container for the multi-step Create Account onboarding flow.
struct CreateAccountScreen: View {
	
	// MARK: - Environment
	
	@Environment(Router.self) private var router
	@Environment(ConnectIQManager.self) private var ciqManager
	
	// MARK: - State
	
	@State private var viewModel = CreateAccountViewModel()
	
	// MARK: - Body
	
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
				.ignoresSafeArea(.keyboard, edges: .bottom)
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
		.onAppear {
			viewModel.configure(ciqManager: ciqManager)
		}
		// Watch reply lands ~0.5s after connect — refresh the gait pickers once it arrives.
		.onChange(of: AuthManager.shared.userDetails) { _, _ in
			if viewModel.currentStep == .setGait { viewModel.seedGait() }
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
		
		if viewModel.currentStep.showsSkip {
			let skipButton: ToolbarItem<(), Button<some View>> = ToolbarItem(placement: .topBarTrailing) {
				Button(action: viewModel.onSkip) {
					Text(.skip)
						.font(.medium17)
						.foregroundStyle(.grayHint)
				}
			}
			
			if #available(iOS 26.0, *) {
				skipButton
					.sharedBackgroundVisibility(.hidden)
			} else {
				skipButton
			}
		}
	}
	
	// MARK: - Step Content
	
	@ViewBuilder
	private var stepContent: some View {
		switch viewModel.currentStep {
			case .profile:
				ProfileStepView(viewModel: viewModel)
			case .pairWatch:
				PairWatchStepView()
			case .chooseYourModel:
				ChooseDevicesStepView(viewModel: viewModel)
			case .showConnectedWatch:
				ConnectWatchStepView(watch: viewModel.selectedWatch)
			case .setGait:
				// Pass live gaitData down; callbacks write back into the ViewModel
				// so the data is ready to persist when the user taps Continue / Skip.
				SetGaitStepView(
					gender: viewModel.selectedGender,
					gaitData: viewModel.gaitData,
					onRunningChange: { viewModel.onRunningGaitChange($0) },
					onWalkingChange: { viewModel.onWalkingGaitChange($0) }
				)
				// Re-init the pickers only when gait is re-seeded (entry / watch sync), not on edits.
				.id(viewModel.gaitSeedToken)
			// Hidden for now — Connect Strava step disabled.
//			case .connectStrava:
//				ConnectStravaStepView(viewModel: viewModel)
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
	
	private func handleNavigation(_ event: CreateAccountViewModel.NavigationEvent) {
		switch event {
			case .skip, .finish:
				router.navigate(to: .accountCreated)
		}
	}
}

// MARK: - Preview

#Preview {
	NavigationStack {
		CreateAccountScreen()
	}
	.environment(Router())
}
