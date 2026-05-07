//
//  EventDetailsScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI
import MapKit

// MARK: - EventDetailsScreen

/// Event details screen
struct EventDetailsScreen: View {
	
	// MARK: Variables
	let activityData: ActivityData?
	
	// MARK: ViewModel
	@State private var viewModel: EventDetailsViewModel
	
	// MARK: Environment
	@Environment(\.dismiss) private var dismiss
	
	// MARK: Init
	init(activityData: ActivityData?) {
		self.activityData = activityData
		_viewModel = State(initialValue: EventDetailsViewModel(activityData: activityData))
	}
	
	// MARK: View Builder
	var body: some View {
		VStack(spacing: 0) {
			scrollContent
		}
		.appBackground()
		.navigationBarTitle(
			"\(activityData?.gaitType?.label ?? "")\(activityData?.gaitType?.label != nil ? " " : "")Details",
			displayMode: .inline
		)
		.navigationDestination(item: $viewModel.showEditScreen, destination: { activity in
			EditEventScreen(eventData: $viewModel.activityData)
		})
	}
	
	// MARK: - Scroll Content
	
	private var scrollContent: some View {
		ScrollView(.vertical, showsIndicators: false) {
			VStack(spacing: 16) {
				
				// MARK: Route Map
				NavigationLink {
					MapViewFullScreen(
						coordinates: viewModel.routeCoordinates,
					)
					.navigationBarTitle(
						"\(activityData?.gaitType?.label ?? "")\(activityData?.gaitType?.label != nil ? " " : "")Details",
						displayMode: .inline
					)

				} label: {
					MapViewRunDetail(
						coordinates: viewModel.routeCoordinates,
					)
				}
				.frame(height: 220)
								
				// MARK: Detail Card (Basic details, Analysis, Intervals, Segments)
				RunDetailCardView(viewModel: viewModel)
				
				// MARK: Bottom Actions
				bottomActions
				
			}
			.padding(.horizontal, 16)
			.padding(.top, 12)
		}
		.toolbar {
			//Favorite or UnFavorite action button
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					viewModel.toggleFavorite()
				} label: {
					Image(.icFavoriteRun)
						.renderingMode(.template)
						.resizable()
						.frame(width: 24, height: 24)
						.foregroundStyle(viewModel.isFavorite ? .fluorescentMint : .grayHint)

				}
			}
		}
	}
	
	// MARK: - Bottom Actions
	
	private var bottomActions: some View {
		FooterActions(
			onDelete: {
				dismiss()
			},
			onEdit: viewModel.editEvent
		)
	}
}

// MARK: - Preview

#Preview {
	NavigationStack {
		EventDetailsScreen(activityData: ActivityData.samples.first)
	}
}
