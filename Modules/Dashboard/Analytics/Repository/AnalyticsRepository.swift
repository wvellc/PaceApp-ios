//
//  AnalyticsRepository.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore

final class AnalyticsRepository {

	static let shared = AnalyticsRepository()

	private let db = Firestore.firestore()

	private init() {}

	func fetchCompletedEvents(
		userId: String,
		from startDate: Date,
		to endDate: Date
	) async throws -> [EventAnalyticsRecord] {
		let snapshot = try await db.collection("events")
			.whereField("userId", isEqualTo: userId)
			.whereField("status", isEqualTo: EventStatus.completed.rawValue)
			.whereField("completedAt", isGreaterThanOrEqualTo: Timestamp(date: startDate))
			.whereField("completedAt", isLessThanOrEqualTo: Timestamp(date: endDate))
			.order(by: "completedAt", descending: false)
			.getDocuments()

		return snapshot.documents.compactMap { doc in
			guard let event = try? doc.data(as: EventDocument.self) else { return nil }
			return EventDocumentMapper.analyticsRecord(from: event)
		}
	}
}
