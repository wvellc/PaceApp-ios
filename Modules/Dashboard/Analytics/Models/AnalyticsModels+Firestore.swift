//
//  AnalyticsModels+Firestore.swift
//  PaceApp
//

import Foundation

extension AnalyticsPeriod {

	/// Short weekday label ("Mon", "Tue", …) derived from a real date. Cached
	/// because DateFormatter allocation is expensive; POSIX locale keeps labels
	/// stable in English to match the fixed year/month column labels.
	private static let weekdayFormatter: DateFormatter = {
		let f = DateFormatter()
		f.locale = Locale(identifier: "en_US_POSIX")
		f.dateFormat = "EEE"
		return f
	}()

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
			// Last 7 days ending today. Labels are derived from each column's real
			// date (e.g. today may be "Wed"), not a fixed Mon–Sun list that would
			// mislabel every column by the current weekday offset.
			let today = calendar.startOfDay(for: Date())
			return (0..<7).map { offset in
				let day = calendar.date(byAdding: .day, value: offset - 6, to: today) ?? today
				let label = Self.weekdayFormatter.string(from: day)
				let group = records.filter { calendar.isDate($0.completedAt, inSameDayAs: day) }
				return (label, group)
			}
		case .month:
			// Four rolling 7-day windows ending now. Bucketing by absolute date
			// windows avoids the weekOfYear delta bug that broke across the
			// year boundary (week 51 → week 2 produced a nonsensical delta).
			let now = Date()
			return ["W1", "W2", "W3", "W4"].enumerated().map { index, label in
				let weeksBack = 3 - index
				let upper = calendar.date(byAdding: .day, value: -7 * weeksBack, to: now) ?? now
				let lower = calendar.date(byAdding: .day, value: -7, to: upper) ?? upper
				let group = records.filter { $0.completedAt > lower && $0.completedAt <= upper }
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
