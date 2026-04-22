//
//  HomeMetric.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/22/26.
//

import SwiftUI

struct HomeMetric: Identifiable {
	let id = UUID()
	
	// MARK: - Capsule Display & Popup Icon (shared)
	let symbol: String       
	let value: String
	let unit: String
	
	// MARK: - Popup Info
	let title: String
	let description: String
}
