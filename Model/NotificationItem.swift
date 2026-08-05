//
//  NotificationItem.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/23/26.
//


import Foundation

// MARK: - Model
struct NotificationItem: Identifiable {
	let id = UUID()
	let title: String
	let message: String
	let timestamp: Date // Store the actual Date object
	
	// Computed property to format the date for the UI
	var timeAgo: String {
		timestamp.timeAgoDisplay()
	}
}
