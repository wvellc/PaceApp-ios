//
//  PaceAreaChart.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/8/26.
//
//  A reusable area/line chart built on Swift Charts.
//  Used in both AnalyticsScreen (compact) and AnalyticsDetailScreen (full).

import SwiftUI
import Charts

// MARK: - PaceAreaChart

/// A shared area-chart component used on both the Analytics list screen
/// and the Analytics detail screen.
///
/// - Parameters:
///   - dataPoints:      Array of (label, value) pairs to plot.
///   - accentColor:     The stroke + gradient base colour.
///   - gradientColors:  Two-stop gradient fill (top → transparent).
///   - showAxes:        When `true` the Y-axis grid lines & labels are visible (detail mode).
///   - height:          Chart frame height. Defaults to 90 (compact) or 180 (detail).
struct PaceAreaChart: View {

    let dataPoints: [AnalyticsDataPoint]
    let accentColor: Color
    let gradientColors: [Color]
    var showAxes: Bool = false
    var height: CGFloat = 90
    /// Formats a raw Y value for its metric (e.g. pace → "8:45", HR → "142").
    /// Defaults to a plain integer so the chart never falls back to a blanket "%".
    var valueFormat: (Double) -> String = { "\(Int($0.rounded()))" }

	// 1. State to track the currently selected index
	@State private var selectedIndex: Int? = nil

    // Derived range so the chart fills nicely
    private var maxValue: Double { (dataPoints.map(\.value).max() ?? 100) * 1.15 }

    var body: some View {
        Chart {
			// Use enumerated() to get the index. This is the key to edge-to-edge.
			ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
				// Gradient area
				AreaMark(
					x: .value("Index", index),
					y: .value("Value", point.value)
				)
				.foregroundStyle(
					LinearGradient(
						colors: gradientColors,
						startPoint: .top,
						endPoint: .bottom
					)
				)
				.interpolationMethod(.catmullRom)
				
				// Stroke line on top
				LineMark(
					x: .value("Index", index),
					y: .value("Value", point.value)
				)
				.foregroundStyle(accentColor)
				.lineStyle(StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
				.interpolationMethod(.catmullRom)
				
				// 2. Add RuleMark and Annotation for Selection
				if let selectedIndex, selectedIndex < dataPoints.count {
					
					let selectedPoint = dataPoints[selectedIndex]

						RuleMark(
							x: .value("Selected", selectedIndex),
							yStart: .value("Bottom", 0),           // Starts at the bottom
							yEnd: .value("Value", selectedPoint.value) // Ends EXACTLY at the data point
						)
						.foregroundStyle(.grayMild)
						.lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
						.annotation(position: .top, spacing: 20) {
							Text(valueFormat(selectedPoint.value))
								.font(.semiBold10)
								.foregroundStyle(.blackApp)
								.padding(.horizontal, 8)
								.padding(.vertical, 4)
								.background(
									RoundedRectangle(cornerRadius: 4)
										.fill(.whiteApp)
										.shadow(radius: 0.5)
								)
						}
					
					// Optional: Point indicator on the line
					PointMark(
						x: .value("Selected", selectedIndex),
						y: .value("Value", dataPoints[selectedIndex].value)
					)
					.foregroundStyle(accentColor)
					.symbolSize(40)
				}
			}
		}
		// 3. Enable edge-to-edge and touch tracking
		.chartXScale(domain: 0...((dataPoints.count - 1) > 0 ? dataPoints.count - 1 : 0))
		.chartYScale(domain: 0...maxValue)
		.chartXSelection(value: $selectedIndex) // Tracks the drag/tap index
		.onChange(of: selectedIndex, {
			HapticManager.shared.medium()
		})

        .chartXAxis {
            if showAxes {
				// X is plotted by integer index (for edge-to-edge), so map each
				// index back to its bucket label. The label already reflects the
				// selected period — hours for Day, weekdays for Week, W1–W4 for
				// Month, months for Year.
				AxisMarks(values: Array(0..<dataPoints.count)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
						.foregroundStyle(.grayLight)
					if let index = value.as(Int.self), dataPoints.indices.contains(index) {
						// Anchor the two edge labels inward so they aren't clipped
						// by the plot bounds: the first hugs leading, the last
						// hugs trailing, the rest stay centred on their tick.
						AxisValueLabel(anchor: index == 0 ? .topLeading : (index == dataPoints.count - 1 ? .topTrailing : .top)) {
							Text(dataPoints[index].label)
								.font(.semiBold10)
								.foregroundStyle(.grayMild)
						}
					}
                }
            } else {
                AxisMarks { _ in AxisGridLine().foregroundStyle(Color.clear) }
            }
        }
        .chartYAxis {
            if showAxes {
                // Y value labels are hidden for now — only the horizontal
                // gridlines remain. This also frees leading width so the first
                // X-axis label is no longer pushed off-screen.
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
						.foregroundStyle(.grayLight)
                }
            } else {
                AxisMarks { _ in AxisGridLine().foregroundStyle(Color.clear) }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkSeaBlue
        VStack(spacing: 20) {
            // Compact (list) usage
            PaceAreaChart(
                dataPoints: AnalyticsDummyData.dataPoints(for: .week, metricType: .pace),
                accentColor: AnalyticsMetricType.pace.accentColor,
                gradientColors: AnalyticsMetricType.pace.gradientColors
            )
            .padding()
            .cardBackground()

            // Detail usage with axes
            PaceAreaChart(
                dataPoints: AnalyticsDummyData.dataPoints(for: .week, metricType: .heartRate),
                accentColor: AnalyticsMetricType.heartRate.accentColor,
                gradientColors: AnalyticsMetricType.heartRate.gradientColors,
                showAxes: true,
                height: 180
            )
            .padding()
            .cardBackground()
        }
        .padding()
    }
    .ignoresSafeArea()
}
