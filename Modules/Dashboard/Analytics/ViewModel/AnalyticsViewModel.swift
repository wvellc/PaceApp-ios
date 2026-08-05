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

@MainActor
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
		// Capture the period this load is for. Runs on the main actor, so the
		// @Observable mutations below are serialized — no data race on the
		// dictionaries. If the user switches period mid-flight, the in-flight
		// result is dropped so a slow older fetch can't clobber newer data.
		let period = selectedPeriod
		fetchState = .loading
		let (start, end) = period.dateRange()
		do {
			let records = try await repository.fetchCompletedEvents(userId: userId, from: start, to: end)
			guard period == selectedPeriod else { return }
			buildDataPoints(from: records)
			buildSummaryCards(from: records)
			fetchState = .success
		} catch {
			guard period == selectedPeriod else { return }
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
					// Best = fastest = smallest pace; ignore 0s (records without pace data)
					// so a missing value can't win min() and freeze the label at 0:00.
					title: "Best Pace",
					value: formatPace(records.map(\.avgPaceSeconds).filter { $0 > 0 }.min() ?? 0),
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
