//
//  HomeMetric.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/22/26.
//

import SwiftUI

struct HomeMetric: Identifiable {
	// Stable per-slot identity so the row card animates its value in place
	// (e.g. the flashing distance ⇄ finish-time capsule) instead of being
	// destroyed and rebuilt on every update. Defaults to a fresh UUID.
	let id: String

	// MARK: - Capsule Display & Popup Icon (shared)
	let symbol: String
	let value: String
	let unit: String

	// MARK: - Popup Info
	let title: String
	let description: String

	init(id: String = UUID().uuidString, symbol: String, value: String, unit: String, title: String, description: String) {
		self.id = id
		self.symbol = symbol
		self.value = value
		self.unit = unit
		self.title = title
		self.description = description
	}
}
