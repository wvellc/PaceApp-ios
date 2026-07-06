
//
//  AnalyticsMetricRow.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/8/26.
//
//  A compact metric card shown in the AnalyticsScreen list.
//  Tapping navigates to AnalyticsDetailScreen for that metric.

import SwiftUI

struct AnalyticsMetricRow: View {

    let metricType: AnalyticsMetricType
    let dataPoints: [AnalyticsDataPoint]
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {

                // Header: icon + title
                HStack(spacing: 8) {
                    Image(metricType.icon)
						.frame(width: 32, height: 32)

                    Text(metricType.rawValue)
                        .font(.semiBold16)
						.foregroundStyle(.darkCharcoal)

                    Spacer()
                }

                // Chart
                PaceAreaChart(
                    dataPoints: dataPoints,
                    accentColor: metricType.accentColor,
                    gradientColors: metricType.gradientColors,
					showAxes: true,
                    height: 105,
                    valueFormat: metricType.formatValue
                )
                .allowsHitTesting(false)
            }
			.padding(.horizontal, Constant.UI.defaultPadding)
			.padding(.vertical, Constant.UI.defaultPadding )
			.cardBackground()
        }
		.buttonStyle(.plainSelected(active: .clear, pressed: .radiantBlue))
    }
}


// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.05, green: 0.09, blue: 0.22).ignoresSafeArea()
        VStack(spacing: 12) {
            ForEach(AnalyticsMetricType.allCases) { metric in
                AnalyticsMetricRow(
                    metricType: metric,
                    dataPoints: AnalyticsDummyData.dataPoints(for: .week, metricType: metric),
                    onTap: {}
                )
            }
        }
        .padding()
    }
}
