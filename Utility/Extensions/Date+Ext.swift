//
//  Date+Ext.swift
//  recoverytrak
//
//  Created by FURKAN VIJAPURA on 28/01/25.
//

import Foundation

extension Date: @retroactive RawRepresentable {
	nonisolated(unsafe) static let formatter = ISO8601DateFormatter()
	
	public var rawValue: String {
		Date.formatter.string(from: self)
	}
	
	public init?(rawValue: String) {
		self = Date.formatter.date(from: rawValue) ?? Date()
	}
	
	func timeAgoDisplay() -> String {
		let formatter = RelativeDateTimeFormatter()
		// .short gives you "min" instead of "minutes" to match your design
		formatter.unitsStyle = .short
		formatter.dateTimeStyle = .numeric
		return formatter.localizedString(for: self, relativeTo: Date())
	}
}

func makeDate(day: Int, month: Int, year: Int = 2026) -> Date {
	let calendar = Calendar(identifier: .gregorian)
	let components = DateComponents(year: year, month: month, day: day)
	guard let date = calendar.date(from: components) else {
		fatalError("Invalid HistoryViewModel activity date.")
	}
	return date
}

