//
//  HomeScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/31/26.
//

import SwiftUI

struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()
    @State private var showPairWatch = false
    private let runActions = RunAction.items
    private let recentActivities = RecentActivity.samples

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: App Navigation bar
            AppNavigation(trailing: {
                Button(action: {
                    // TODO: Show notification screen
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
                            recentActivitySection
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
                HomeMetricCard(metric: metric, isHighPerformance: viewModel.isHighPerformance)

                // Dynamic space
                if metric.id != viewModel.metrics.last?.id {
                    Spacer()
                }
            }
        }
    }

	//MARK: Run Action Grid
    private var runActionGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

        return LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            ForEach(runActions) { action in
                RunActionCard(action: action)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.recentActivity)
                .font(.semiBold16)
                .foregroundColor(.whiteApp)

            VStack(spacing: 16) {
                ForEach(recentActivities) { activity in
                    RecentActivityCard(activity: activity)
                }
            }
        }
    }
}

#Preview {
    HomeScreen()
}

