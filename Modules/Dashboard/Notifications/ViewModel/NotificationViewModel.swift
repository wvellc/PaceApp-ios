//
//  NotificationViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/23/26.
//

import SwiftUI
import Observation

import SwiftUI
import Observation

// MARK: - ViewModel
@Observable
class NotificationsViewModel {
	
	//MARK: Property
	var notifications: [NotificationItem] = []
	
	//MARK: Initializer
	init() {
		print("\(self) :---> Allocated 🟦")
		loadData()
	}
	
	deinit {
		print("\(self) :---> Deallocated 🟩")
	}
	
	//MARK: Methods
	// Handle the swipe-to-delete action
	func delete(notification: NotificationItem) {
		if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
			notifications.remove(at: index)
		}
	}
	
	// Handle clear all notification action
	func clearAllNotification() {
		
		notifications.removeAll()
	}

	
	//Data Loading
	//FIXME: Remove after database login
	private func loadData() {
		let formatter = ISO8601DateFormatter()
		let now = Date()
		
		// Simulating incoming UTC timestamps (Fallback to math if parsing fails)
		// Adjust these ISO8601 strings to match your actual server data
		let date1 = formatter.date(from: "2026-04-23T11:46:20Z") ?? now.addingTimeInterval(-1300)
		let date2 = formatter.date(from: "2026-04-23T11:46:20Z") ?? now.addingTimeInterval(-300) // 5 min ago
		let date3 = formatter.date(from: "2026-04-23T11:48:20Z") ?? now.addingTimeInterval(-180) // 3 min ago
		let date4 = formatter.date(from: "2026-04-23T11:50:20Z") ?? now.addingTimeInterval(-60)  // 1 min ago
		let date5 = formatter.date(from: "2026-04-23T11:49:20Z") ?? now.addingTimeInterval(-120) // 2 min ago
		
		self.notifications = [
			NotificationItem(title: "Interval complete", message: "Check your split time and steps for this segment.", timestamp: date1),
			NotificationItem(title: "Goal pace off target", message: "You're slightly off your target pace. Adjust in the next interval.", timestamp: date2),
			NotificationItem(title: "Goal pace on track", message: "You're right on your target pace. Keep it up!", timestamp: date3),
			NotificationItem(title: "Goal pace ahead", message: "You're exceeding your target pace. Maintain this energy!", timestamp: date4),
			NotificationItem(title: "Goal pace below target", message: "You're falling behind your target pace. Push harder!", timestamp: date5)
		]
	}
}
