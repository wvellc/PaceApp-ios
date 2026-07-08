
//
//  AnalyticsModels.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/8/26.
//

import SwiftUI

// MARK: - Analytics Period

enum AnalyticsPeriod: String, CaseIterable, Hashable {
    case day   = "Day"
    case week  = "Week"
    case month = "Month"
    case year  = "Year"
}

// MARK: - Analytics Metric Type

enum AnalyticsMetricType: String, CaseIterable, Identifiable {
    case pace       = "Avg Pace"
    case heartRate  = "Avg Heart Rate"
    case percentage = "Avg Efforts"

    var id: String { rawValue }

	var icon: ImageResource {
        switch self {
			case .pace		: .icAvgPace
			case .heartRate	: .icAvgHeartRate
			case .percentage: .icEvgPer
        }
    }

    var accentColor: Color {
        switch self {
			case .pace		: .fluorescentMint
			case .heartRate	: .redBoho
			case .percentage: .fashionGray
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .pace:
            return [.fluorescentMint.opacity(0.6),
					.fluorescentMint.opacity(0.05)]
        case .heartRate:
            return [.redBoho.opacity(0.6),
					.redBoho.opacity(0.05)]
        case .percentage:
            return [.fashionGray.opacity(0.6),
					.fashionGray.opacity(0.05)]
        }
    }

    var detailTitle: String {
        switch self {
        case .pace:       return "Avg Pace"
        case .heartRate:  return "Avg Heart Rate"
        case .percentage: return "Avg Efforts"
        }
    }

    /// Formats a raw Y-axis value for this metric so the chart shows a meaningful
    /// unit instead of a blanket "%": pace as m:ss time, heart rate as bpm count,
    /// effort as a percentage.
    func formatValue(_ value: Double) -> String {
        switch self {
        case .pace:
            let total = Int(value.rounded())
            return String(format: "%d:%02d", total / 60, total % 60)
        case .heartRate:
            return "\(Int(value.rounded()))"
        case .percentage:
            return "\(Int(value.rounded()))%"
        }
    }
}

// MARK: - Chart Data Point

struct AnalyticsDataPoint: Identifiable {
    let id = UUID()
    let label: String   // X-axis label (e.g. "Mon", "Week 1", "Jan")
    let value: Double   // Y-axis value
}

// MARK: - Analytics Summary Card Model

struct AnalyticsSummaryCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let accentColor: Color
    let dataPoints: [AnalyticsDataPoint]
}

// MARK: - Dummy Data Provider

enum AnalyticsDummyData {

    // MARK: Generic point generators

    static func dataPoints(for period: AnalyticsPeriod, metricType: AnalyticsMetricType) -> [AnalyticsDataPoint] {
        switch period {
        case .day:   return dayPoints(for: metricType)
        case .week:  return weekPoints(for: metricType)
        case .month: return monthPoints(for: metricType)
        case .year:  return yearPoints(for: metricType)
        }
    }

    // MARK: Day (24-hour, shown as every 3h)

    private static func dayPoints(for metric: AnalyticsMetricType) -> [AnalyticsDataPoint] {
        let hours = ["12a","3a","6a","9a","12p","3p","6p","9p"]
        let values: [AnalyticsMetricType: [Double]] = [
            .pace:       [10, 20, 15, 50, 80, 65, 90, 70],
            .heartRate:  [8,  12, 10, 35, 60, 55, 80, 60],
            .percentage: [10, 18, 14, 45, 72, 60, 85, 65]
        ]
        return zip(hours, values[metric] ?? []).map { AnalyticsDataPoint(label: $0, value: $1) }
    }

    // MARK: Week (Mon–Sun)

    private static func weekPoints(for metric: AnalyticsMetricType) -> [AnalyticsDataPoint] {
        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        let values: [AnalyticsMetricType: [Double]] = [
            .pace:       [20, 45, 30, 70, 55, 90, 75],
            .heartRate:  [15, 30, 20, 50, 40, 70, 55],
            .percentage: [18, 40, 28, 62, 48, 82, 68]
        ]
        return zip(days, values[metric] ?? []).map { AnalyticsDataPoint(label: $0, value: $1) }
    }

    // MARK: Month (Weeks)

    private static func monthPoints(for metric: AnalyticsMetricType) -> [AnalyticsDataPoint] {
        let weeks = ["W1","W2","W3","W4"]
        let values: [AnalyticsMetricType: [Double]] = [
            .pace:       [40, 55, 48, 78],
            .heartRate:  [30, 42, 35, 60],
            .percentage: [38, 52, 44, 70]
        ]
        return zip(weeks, values[metric] ?? []).map { AnalyticsDataPoint(label: $0, value: $1) }
    }

    // MARK: Year (Months)

    private static func yearPoints(for metric: AnalyticsMetricType) -> [AnalyticsDataPoint] {
        let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let values: [AnalyticsMetricType: [Double]] = [
            .pace:       [30, 45, 38, 60, 52, 75, 65, 80, 70, 85, 78, 90],
            .heartRate:  [25, 35, 28, 45, 40, 58, 50, 65, 55, 68, 60, 72],
            .percentage: [28, 42, 35, 55, 48, 68, 58, 72, 62, 78, 70, 85]
        ]
        return zip(months, values[metric] ?? []).map { AnalyticsDataPoint(label: $0, value: $1) }
    }

    // MARK: Summary Cards for Detail Screen

    static func summaryCards(for metricType: AnalyticsMetricType, period: AnalyticsPeriod) -> [AnalyticsSummaryCard] {
        switch metricType {
        case .pace:
            return [
                AnalyticsSummaryCard(
                    title: "Avg Pace",
                    value: "8:45",
                    unit: "min/mi",
                    accentColor: AnalyticsMetricType.pace.accentColor,
                    dataPoints: dataPoints(for: period, metricType: .pace)
                ),
                AnalyticsSummaryCard(
                    title: "Best Pace",
                    value: "6:12",
                    unit: "min/mi",
                    accentColor: AnalyticsMetricType.pace.accentColor,
                    dataPoints: dataPoints(for: period, metricType: .pace)
                )
            ]
        case .heartRate:
            return [
                AnalyticsSummaryCard(
                    title: "Avg Heart Rate",
                    value: "142",
                    unit: "bpm",
                    accentColor: AnalyticsMetricType.heartRate.accentColor,
                    dataPoints: dataPoints(for: period, metricType: .heartRate)
                ),
                AnalyticsSummaryCard(
                    title: "Max Heart Rate",
                    value: "178",
                    unit: "bpm",
                    accentColor: AnalyticsMetricType.heartRate.accentColor,
                    dataPoints: dataPoints(for: period, metricType: .heartRate)
                )
            ]
        case .percentage:
            return [
                AnalyticsSummaryCard(
                    title: "Avg Effort",
                    value: "74",
                    unit: "%",
                    accentColor: AnalyticsMetricType.percentage.accentColor,
                    dataPoints: dataPoints(for: period, metricType: .percentage)
                ),
                AnalyticsSummaryCard(
                    title: "Peak Effort",
                    value: "92",
                    unit: "%",
                    accentColor: AnalyticsMetricType.percentage.accentColor,
                    dataPoints: dataPoints(for: period, metricType: .percentage)
                )
            ]
        }
    }
}
