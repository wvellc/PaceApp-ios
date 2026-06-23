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
	@Environment(ConnectIQManager.self) private var ciqManager
	
	// MARK: Init
	init(activityData: ActivityData?) {
		self.activityData = activityData
		_viewModel = State(initialValue: EventDetailsViewModel(activityData: activityData))
	}
	
	// MARK: Body
	var body: some View {
		VStack(spacing: 0) {
			scrollContent
		}
		.padding(.top, 6)
		.appBackground()
		// navigationDestination must live on the root container, never inside
		// a ScrollView or List — SwiftUI warns and will ignore it in future releases.
		.navigationDestination(item: $viewModel.showEditScreen) { _ in
			EditEventScreen(eventData: $viewModel.activityData)
		}
	}
	
	// MARK: - Scroll Content
	
	private var scrollContent: some View {
		ScrollView(.vertical, showsIndicators: false) {
			VStack(spacing: 16) {
				
				// MARK: Route Map (only shown when GPS data is available)
				if viewModel.hasRouteData {
					NavigationLink {
						MapViewFullScreen(
							coordinates: viewModel.routeCoordinates
						)
						.navigationBarTitle(
							"\(activityData?.gaitType?.label ?? "")\(activityData?.gaitType?.label != nil ? " " : "")Details",
							displayMode: .inline
						)
					} label: {
						MapViewRunDetail(
							coordinates: viewModel.routeCoordinates
						)
					}
					.frame(height: 220)
				}
				
				// MARK: Detail Card (Basic details, Analysis, Intervals, Segments)
				RunDetailCardView(viewModel: viewModel)
				
				// MARK: Bottom Actions
				bottomActions
			}
			.padding(.horizontal, Constant.UI.defaultPadding)
			.padding(.top, 12)
		}
		.toolbar {
			// Favorite or UnFavorite action button
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					viewModel.toggleFavorite()
				} label: {
					Image(.icFavoriteRun)
						.renderingMode(.template)
						.resizable()
						.frame(width: 24, height: 24)
						.foregroundStyle(viewModel.isFavorite ? .fluorescentMint : .grayHint)
						.opacity(viewModel.isLoadingFavorite ? 0.6 : 1.0)
				}
				.disabled(viewModel.isLoadingFavorite)
			}
			
			ToolbarItem(placement: .principal) {
				Text("\(activityData?.gaitType?.label ?? "")\(activityData?.gaitType?.label != nil ? " " : "")Details")
					.font(.medium16)
					.foregroundStyle(.whiteApp)
			}
		}
	}
	
	// MARK: - Bottom Actions
	
	private var bottomActions: some View {
		FooterActions(
			onDelete: {
				if let syncId = activityData?.syncId {
					let _ = viewModel.isCompletedEvent ? "completed" : "active"
					ciqManager.deleteSyncedEvent(id: syncId)
				}
				dismiss()
			},
			onEdit: viewModel.editEvent
		)
	}
}

// MARK: - Preview

#Preview {
	NavigationStack {
		EventDetailsScreen(activityData: ActivityData(
			title: "Thursday Run",
			date: makeDate(day: 29, month: 1),
			distance: "5.00 mi",
			duration: "05:35:00",
			avgPace: "9:00 /mi",
			delta: "+01:10",
			deltaColor: .redBoho,
			location: "New York City",
			gaitType: .walking
		))
	}
}
