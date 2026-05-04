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
			ToolbarItem(placement: .topBarLeading) {
				Button(action: viewModel.onBack) {
					Image(systemName: "chevron.left")
						.font(.system(size: 16, weight: .semibold))
						.foregroundStyle(.whiteApp)
						.padding(8)
				}
			}
		}
		
		ToolbarItem(placement: .principal) {
			Text(viewModel.currentStep.title)
				.font(.medium17)
				.foregroundStyle(.whiteApp)
		}
		
		if viewModel.currentStep.showsSkip {
			let skipButton: ToolbarItem<(), Button<some View>> = ToolbarItem(placement: .topBarTrailing) {
				Button(action: viewModel.onSkip) {
					Text(.skip)
						.font(.medium17)
						.foregroundStyle(.grayHint)
//						.padding(8)
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
				SetGaitStepView()
			case .connectStrava:
				ConnectStravaStepView(viewModel: viewModel)
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
