//
//  HomeScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/31/26.
//

import SwiftUI

///Home screen main view
struct HomeScreen: View {
	
	//MARK: Variables
	@State private var viewModel = HomeViewModel()
	@State private var showPairWatch = false
	private let recentActivities = ActivityData.samples
	
	@Environment(Router.self) private var router
	
	
	//MARK: View Builder
	var body: some View {
		ZStack {
			VStack(alignment: .leading, spacing: 0) {
				// MARK: App Navigation bar
				AppNavigation(trailing: {
					Button(action: {
						//Show notification screen
						router.navigate(to: .notifications)
					}, label: {
						RoundedRectangle(cornerRadius: 100)
							.foregroundStyle(.whiteApp)
							.overlay(content: {
								Image(.icNotification)
									.resizable()
									.frame(width: 20, height: 20)
							})
					})
				})
				
				//MARK: Main scrollable content
				ScrollView(showsIndicators: false) {
					VStack(alignment: .leading, spacing: 0) {
						//User name & sync status
						VStack(alignment: .leading) {
							Text("GM, Jack")
								.font(.bold28)
								.foregroundColor(.whiteApp)
							Text("Not Synced Yet!")
								.font(.medium14)
								.foregroundColor(.white50)
						}
						
						// MARK: Home data & Pair watch view
						if showPairWatch {
							PairWatchView {
								showPairWatch = true
							}
						} else {
							VStack(alignment: .leading, spacing: 16) {
								// Metrics
								metricRow
								
								// Run Actions
								runActionGrid
								
								// Recent Activity
								UpcomingActivitySection
							}
							.padding(.vertical, 16)
							
						}
					}
					.padding(.horizontal, 16)
					.padding(.bottom, 18)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
			.appBackground()
			
			if viewModel.showMetricPopup {
				MetricsPopupView(
					isPresented: $viewModel.showMetricPopup,
					metrics: viewModel.metrics,
					startingIndex: viewModel.selectedMetricIndex
				)
				.zIndex(20)
			}
		}
	}
	
	//MARK: Metric Row
	private var metricRow: some View {
		HStack {
			ForEach(viewModel.metrics) { metric in
				// Dynamic space
				if metric.id != viewModel.metrics.first?.id {
					Spacer()
				}
				
				// Metric cards
				HomeMetricCard(metric: metric, isHighPerformance: viewModel.isHighPerformance) {
					viewModel.didTapMetric(metric)
				}
				
				// Dynamic space
				if metric.id != viewModel.metrics.last?.id {
					Spacer()
				}
			}
		}
	}
	
	//MARK: Run Action Grid
	private var runActionGrid: some View {
	    // Two flexible columns with consistent spacing
	    let spacing: CGFloat = 16
	    let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)
	    let runActions: [RunAction] = [
	        RunAction(title: .newRun, symbol: "icNewRun", action: {
	            router.navigate(to: .createRunEvent)
	        }),
	        RunAction(title: .favoriteRun, symbol: "icFavoriteRun", action: {
				router.navigate(to: .favoritesRun)
			}),
	    ]

		return LazyVGrid(columns: columns, alignment: .center, spacing: spacing) {
	        ForEach(runActions) { action in
	            GeometryReader { geo in
	                let side = geo.size.width
					
	                RunActionCard(action: action)
	                    .frame(width: side, height: side)
	            }
				.aspectRatio(1, contentMode: .fit)

	        }
	    }
		.fixedSize(horizontal: false, vertical: true)

	}
	
	// MARK: Upcoming Activity
	private var UpcomingActivitySection: some View {
		VStack(alignment: .leading, spacing: 16) {
			//Activity title
			Text(.upcomingActivities)
				.font(.semiBold16)
				.foregroundColor(.whiteApp)

			
			VStack(spacing: 16) {
				//Activity list
				ForEach(recentActivities) { activity in
					UpcomingActivityView(activity: activity)
				}
			}
		}
	}
}


#Preview {
	HomeScreen()
		.environment(Router())
}

