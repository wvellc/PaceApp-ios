//
//  AnalyticsViewModel.swift
//  PaceApp
//

import Foundation
import Observation
import SwiftUI

enum AnalyticsFetchState: Equatable {
	case idle
	case loading
	case success
	case failure(String)
}

@Observable
final class AnalyticsViewModel {

	var selectedPeriod: AnalyticsPeriod = .week
	var fetchState: AnalyticsFetchState = .idle
	private(set) var dataPointsByMetric: [AnalyticsMetricType: [AnalyticsDataPoint]] = [:]
	private(set) var summaryCards: [AnalyticsMetricType: [AnalyticsSummaryCard]] = [:]

	private let repository: AnalyticsRepository
	private(set) var userId: String

	init(userId: String, repository: AnalyticsRepository = .shared) {
		self.userId = userId
		self.repository = repository
	}

	func load() async {
		fetchState = .loading
		let (start, end) = selectedPeriod.dateRange()
		do {
			let records = try await repository.fetchCompletedEvents(userId: userId, from: start, to: end)
			buildDataPoints(from: records)
			buildSummaryCards(from: records)
			fetchState = .success
		} catch {
			fetchState = .failure(error.localizedDescription)
		}
	}

	func periodChanged() async {
		await load()
	}

	private func buildDataPoints(from records: [EventAnalyticsRecord]) {
		let buckets = selectedPeriod.bucketRecords(records)
		dataPointsByMetric = Dictionary(
			uniqueKeysWithValues: AnalyticsMetricType.allCases.map { metric in
				let points = buckets.map { label, group in
					AnalyticsDataPoint(label: label, value: metric.averageValue(from: group))
				}
				return (metric, points)
			}
		)
	}

	private func buildSummaryCards(from records: [EventAnalyticsRecord]) {
		summaryCards = [
			.pace: [
				AnalyticsSummaryCard(
					title: "Avg Pace",
					value: formatPace(Int(records.map(\.avgPaceSeconds).average())),
					unit: "min/mi",
					accentColor: AnalyticsMetricType.pace.accentColor,
					dataPoints: dataPointsByMetric[.pace] ?? []
				),
				AnalyticsSummaryCard(
					title: "Best Pace",
					value: formatPace(records.map(\.avgPaceSeconds).min() ?? 0),
					unit: "min/mi",
					accentColor: AnalyticsMetricType.pace.accentColor,
					dataPoints: dataPointsByMetric[.pace] ?? []
				)
			],
			.heartRate: [
				AnalyticsSummaryCard(
					title: "Avg Heart Rate",
					value: "\(Int(records.map(\.avgHeartRate).average()))",
					unit: "bpm",
					accentColor: AnalyticsMetricType.heartRate.accentColor,
					dataPoints: dataPointsByMetric[.heartRate] ?? []
				),
				AnalyticsSummaryCard(
					title: "Max Heart Rate",
					value: "\(records.map(\.avgHeartRate).max() ?? 0)",
					unit: "bpm",
					accentColor: AnalyticsMetricType.heartRate.accentColor,
					dataPoints: dataPointsByMetric[.heartRate] ?? []
				)
			],
			.elevation: [
				AnalyticsSummaryCard(
					title: "Overall Elevation Climbed",
					value: "\(Int(records.map(\.elevationGain).reduce(0, +)))",
					unit: "ft",
					accentColor: AnalyticsMetricType.elevation.accentColor,
					dataPoints: dataPointsByMetric[.elevation] ?? []
				),
				AnalyticsSummaryCard(
					title: "Total Distance Covered",
					value: String(format: "%.1f", records.map(\.distanceValue).reduce(0, +)),
					unit: "mi",
					accentColor: AnalyticsMetricType.elevation.accentColor,
					dataPoints: dataPointsByMetric[.pace] ?? []
				)
			],
			.percentage: [
				AnalyticsSummaryCard(
					title: "Avg Effort",
					value: "\(Int(records.map(\.effortPercentage).reduce(0, +) / Double(max(records.count, 1))))",
					unit: "%",
					accentColor: AnalyticsMetricType.percentage.accentColor,
					dataPoints: dataPointsByMetric[.percentage] ?? []
				),
				AnalyticsSummaryCard(
					title: "Peak Effort",
					value: "\(Int(records.map(\.effortPercentage).max() ?? 0.0))",
					unit: "%",
					accentColor: AnalyticsMetricType.percentage.accentColor,
					dataPoints: dataPointsByMetric[.percentage] ?? []
				)
			]
		]
	}

	private func formatPace(_ totalSeconds: Int) -> String {
		let minutes = totalSeconds / 60
		let seconds = totalSeconds % 60
		return String(format: "%d:%02d", minutes, seconds)
	}
}

private extension Array where Element == Int {
	func average() -> Double {
		isEmpty ? 0 : Double(reduce(0, +)) / Double(count)
	}
}
