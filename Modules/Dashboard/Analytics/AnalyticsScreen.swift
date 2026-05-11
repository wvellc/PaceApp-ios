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
								dataPoints: AnalyticsDummyData.dataPoints(for: .week, metricType: metric),
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
            .navigationDestination(isPresented: $navigateToDetail) {
                if let metric = selectedMetric {
					AnalyticsDetailScreen(metricType: metric, initialPeriod: .week)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AnalyticsScreen()
}
