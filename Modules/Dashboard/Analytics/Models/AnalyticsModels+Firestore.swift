//
//  AnalyticsModels+Firestore.swift
//  PaceApp
//

import Foundation

extension AnalyticsPeriod {

	func dateRange() -> (Date, Date) {
		let now = Date()
		let calendar = Calendar.current
		switch self {
		case .day:
			return (calendar.startOfDay(for: now), now)
		case .week:
			let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
			return (start, now)
		case .month:
			let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
			return (start, now)
		case .year:
			let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
			return (start, now)
		}
	}

	func bucketRecords(_ records: [EventAnalyticsRecord]) -> [(String, [EventAnalyticsRecord])] {
		let calendar = Calendar.current
		switch self {
		case .day:
			let hours = ["12a", "3a", "6a", "9a", "12p", "3p", "6p", "9p"]
			let slots = [0, 3, 6, 9, 12, 15, 18, 21]
			return zip(hours, slots).map { label, hour in
				let group = records.filter {
					let recordHour = calendar.component(.hour, from: $0.completedAt)
					return recordHour >= hour && recordHour < hour + 3
				}
				return (label, group)
			}
		case .week:
			let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
			return days.enumerated().map { index, label in
				let target = calendar.date(byAdding: .day, value: index - 6, to: Date()) ?? Date()
				let group = records.filter { calendar.isDate($0.completedAt, inSameDayAs: target) }
				return (label, group)
			}
		case .month:
			let weeks = ["W1", "W2", "W3", "W4"]
			return weeks.enumerated().map { index, label in
				let group = records.filter {
					let weeksAgo = calendar.dateComponents([.weekOfYear], from: $0.completedAt, to: Date()).weekOfYear ?? 0
					return weeksAgo == (3 - index)
				}
				return (label, group)
			}
		case .year:
			let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
			return months.enumerated().map { index, label in
				let group = records.filter { calendar.component(.month, from: $0.completedAt) == index + 1 }
				return (label, group)
			}
		}
	}
}

extension AnalyticsMetricType {

	func averageValue(from records: [EventAnalyticsRecord]) -> Double {
		guard !records.isEmpty else { return 0 }
		switch self {
		case .pace:
			return records.map { Double($0.avgPaceSeconds) }.reduce(0, +) / Double(records.count)
		case .heartRate:
			return records.map { Double($0.avgHeartRate) }.reduce(0, +) / Double(records.count)
		case .elevation:
			return records.map(\.elevationGain).reduce(0, +)
		case .percentage:
			return records.map(\.effortPercentage).reduce(0, +) / Double(records.count)
		}
	}
}

private extension Array where Element == Double {
	func average() -> Double {
		isEmpty ? 0 : reduce(0, +) / Double(count)
	}
}

private extension Array where Element == Int {
	func average() -> Double {
		isEmpty ? 0 : Double(reduce(0, +)) / Double(count)
	}
}
