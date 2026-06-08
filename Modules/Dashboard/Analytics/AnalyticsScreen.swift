//
//  AnalyticsScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/8/26.
//
//  The main Analytics tab screen. Shows a scrollable list of metric cards,
//  each containing a compact PaceAreaChart. Tapping navigates to the detail view.

import SwiftUI

struct AnalyticsScreen: View {

    // MARK: - State
    @State private var viewModel: AnalyticsViewModel?
    @State private var selectedMetric: AnalyticsMetricType? = nil
    @State private var navigateToDetail = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
				// MARK: App Navigation bar
				AppNavigation()
				
				//MARK: Main scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
						
                        // Metric Cards
                        ForEach(AnalyticsMetricType.allCases) { metric in
                            AnalyticsMetricRow(
                                metricType: metric,
								dataPoints: viewModel?.dataPointsByMetric[metric] ?? [],
                                onTap: {
                                    selectedMetric = metric
                                    navigateToDetail = true
                                }
                            )
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
			.appBackground()
            .task(id: AuthManager.shared.currentUserID) {
                guard let userId = AuthManager.shared.currentUserID else { return }
                let vm = AnalyticsViewModel(userId: userId)
                viewModel = vm
                await vm.load()
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                if let metric = selectedMetric, let viewModel {
					AnalyticsDetailScreen(metricType: metric, initialPeriod: .week, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AnalyticsScreen()
}
