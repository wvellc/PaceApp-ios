//
//  EventDetailsScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI
import MapKit
import Logging

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
		scrollContent
		.padding(.top, 6)
		.appBackground()
		.onAppear {
			logger.debug("Event ID: \(viewModel.activityData?.id.description ?? "Unknown ID")")
		}
		// Reflect a name/location edit made on EditEventScreen without a refetch.
		.onChange(of: EventUpdateCenter.shared.lastUpdate) { _, update in
			guard let update, update.eventId == viewModel.activityData?.id else { return }
			viewModel.activityData?.title = update.name
			viewModel.activityData?.location = update.location
		}
		// navigationDestination must live on the root container, never inside
		// a ScrollView or List — SwiftUI warns and will ignore it in future releases.
		.navigationDestination(item: $viewModel.showEditScreen) { _ in
			EditEventScreen(eventData: $viewModel.activityData)
		}
		// Duplicate reuses this event's plan as a new upcoming event — works from Home, History, and Favorites alike.
		.navigationDestination(item: $viewModel.duplicateSource) { source in
			CreateRunEventScreen(type: .duplicate, intialData: source)
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
							detailsTitle,
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
				Text(detailsTitle)
					.font(.medium16)
					.foregroundStyle(.whiteApp)
			}
		}
	}

	// MARK: - Title

	/// Screen title, e.g. "Running Details" / "Cycling Details" — driven by the
	/// event's activity type. Falls back to "Details" when no event is loaded.
	private var detailsTitle: String {
		guard let eventType = activityData?.eventType else { return "Details" }
		return "\(eventType.title) Details"
	}
	
	// MARK: - Bottom Actions
	
	private var bottomActions: some View {
		FooterActions(
			onDelete: {
				// Confirm before deleting — destructive and irreversible.
				AppAlertManager.shared.confirmEventDeletion {
					if let eventId = viewModel.activityData?.id {
						ciqManager.deleteSyncedEvent(id: eventId)
					}
					dismiss()
				}
			},
			onEdit: viewModel.editEvent,
			onDuplicate: duplicateAction
		)
	}

	// A finished event can be run again, just like on the watch.
	private var duplicateAction: (() -> Void)? {
		guard viewModel.isCompletedEvent else { return nil }
		return viewModel.duplicateEvent
	}
}

// MARK: - Preview

#Preview {
	NavigationStack {
		EventDetailsScreen(
activityData: ActivityData(
			title: "Thursday Run",
			date: makeDate(day: 29, month: 1),
			distance: "5.00 mi",
			duration: "05:35:00",
			avgPace: 540,	// 9:00 per mile, in seconds
			delta: "+01:10",
			deltaColor: .redBoho,
			location: "New York City",
			gaitType: .walking,
			segments: [
				RunSegment(id: 787987978897, distance: 2.5, goalHours: 2, goalMinutes: 20, goalSeconds: 50, actualTimeSeconds: 500),
				RunSegment(id: 8798789789889, distance: 1.5, goalHours: 1, goalMinutes: 20, goalSeconds: 50, actualTimeSeconds: 600),
				RunSegment(id: 5465456456456, distance: 2.5, goalHours: 2, goalMinutes: 20, goalSeconds: 50, actualTimeSeconds: 500)
			]
		)
)
	}
}
