//
//  NewRunScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

import SwiftUI

struct CreateRunEventScreen: View {
	
	let type: CreateEventType
	let intialData: ActivityData?
	
	//MARK: Environment
	@Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss

	// MARK: ViewModel
	@State private var viewModel: CreateRunEventViewModel
	
	// MARK: Init
	init(type:CreateEventType = .new, intialData: ActivityData? = nil) {
		self.type = type
		self.intialData = intialData
		_viewModel = State(initialValue: CreateRunEventViewModel(type: type, initialData: intialData))
	}


	//MARK: View Builder
    var body: some View {
		VStack(spacing: 0) {
			
			// MARK: Content
			ScrollView {
				VStack(spacing: 32) {
					stepContent
				}
				.padding(.horizontal, 20)
				.padding(.bottom, 24)
				.padding(.top, 8)
			}
			.scrollBounceBehavior(.basedOnSize)
			
			Spacer(minLength: 0)
			
			// MARK: Next Button
			VStack(spacing: 0) {
				RunNextButton(
					title: viewModel.nextButtonTitle,
					isEnabled: viewModel.isNextEnabled
				) {
					
					//For duplicate event — generate new ID, save & sync, then dismiss
					if type == .duplicate && viewModel.validateEventDetails() {
						// Submit saves locally + sends create_event to watch
						viewModel.submitDuplicate()
						
						dismiss()
						
						ToastManager.shared.present(.success("Successfully created."))
						return
					}
					
					//For new event flow
					viewModel.goNext()
				}
				.padding(.horizontal, 20)
				.padding(.vertical, 16)
			}
		}
		.appBackground()
		.onAppear {
			// Plan fields (incl. duplicate seeding) are set in the ViewModel init;
			// here we only hand it the router for post-submit navigation.
			viewModel.router = self.router
		}
		.navigationBarBackButtonHidden(true)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar { topToolbar }
		.toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Step Content Router
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .eventDetails:
            EventDetailsStepView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .distance:
            DistanceStepView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .goalTime:
            GoalTimeStepView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .segmentChoice:
            SegmentChoiceStepView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .segmentCount:
            SegmentCountStepView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .segmentDetails:
            SegmentDetailStepView(viewModel: viewModel)
//                .id(viewModel.currentSegmentIndex) // Force re-render on segment change
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .lookBackIntervals:
            LookBackIntervalsStepView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        }
    }
	
	// MARK: - Top Toolbar

	@ToolbarContentBuilder
	private var topToolbar: some ToolbarContent {
		AppBackButtonToolbarContent {
			if viewModel.currentStep == .eventDetails {
				dismiss()
			} else {
				viewModel.goBack()
			}
		}

		ToolbarItem(placement: .principal) {
			Text(.newRun)
				.font(.medium16)
				.foregroundStyle(.whiteApp)
		}
	}
}

// MARK: - Preview

#Preview {
    CreateRunEventScreen()
}
