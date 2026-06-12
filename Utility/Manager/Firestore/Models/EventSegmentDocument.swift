//
//  EventSegmentDocument.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore

struct EventSegmentDocument: Codable, Identifiable {
	var index: Int
	var distance: Double
	var goalTimeSeconds: Int
	var completedAt: Timestamp?
	var actualTimeSeconds: Int?

	var id: String { documentId ?? String(index) }
}
