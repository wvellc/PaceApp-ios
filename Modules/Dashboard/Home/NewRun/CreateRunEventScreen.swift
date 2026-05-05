//
//  NewRunScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

import SwiftUI

// MARK: - Main Screen

struct CreateRunEventScreen: View {
	
	//MARK: Environment
	@Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss

	@State private var viewModel = CreateRunEventViewModel()

	//MARK: View Builder
    var body: some View {
        ZStack {
            // Deep blue background
            LinearGradient(
                colors: [Color(hex: "0C2D8C"), Color(hex: "091E5B")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
                        viewModel.goNext()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0A1B6B").opacity(0), Color(hex: "0A1B6B")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
            }
        }
		.onAppear {
			viewModel.router = self.router
		}
		.navigationTitle(.newRun)
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
		ToolbarItem(placement: .topBarLeading) {
			Button {
				if viewModel.currentStep == .eventDetails {
					dismiss()
				} else {
					viewModel.goBack()
				}
			} label: {
				Image(systemName: "chevron.left")
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(.whiteApp)
					.padding(8)

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
