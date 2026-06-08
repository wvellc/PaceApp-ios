//
//  EventAnalyticsRecord.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore

struct EventAnalyticsRecord: Codable, Identifiable {
	@DocumentID var documentId: String?
	var completedAt: Date
	var avgPaceSeconds: Int
	var avgHeartRate: Int
	var elevationGain: Double
	var effortPercentage: Double
	var distanceValue: Double
	var measure: String

	var id: String { documentId ?? UUID().uuidString }

	init(
		documentId: String? = nil,
		completedAt: Date,
		avgPaceSeconds: Int,
		avgHeartRate: Int,
		elevationGain: Double,
		effortPercentage: Double,
		distanceValue: Double,
		measure: String
	) {
		self.documentId = documentId
		self.completedAt = completedAt
		self.avgPaceSeconds = avgPaceSeconds
		self.avgHeartRate = avgHeartRate
		self.elevationGain = elevationGain
		self.effortPercentage = effortPercentage
		self.distanceValue = distanceValue
		self.measure = measure
	}
}
