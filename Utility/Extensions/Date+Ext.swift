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
}
