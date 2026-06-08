//
//  FirestoreEventRepository.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore
import Logging

final class FirestoreEventRepository: EventRepositoryProtocol {

	static let shared = FirestoreEventRepository()

	private let db = Firestore.firestore()
	private let logger = Logger(label: "net.paceapp.firestore.events")

	private init() {}

	// MARK: - Observe

	func observeActiveEvents(userId: String, onChange: @escaping ([ActivityData]) -> Void) -> ListenerRegistrationToken {
		let query = eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.active.rawValue)
			.order(by: "scheduledAt", descending: false)

		let registration = query.addSnapshotListener { [weak self] snapshot, error in
			guard let self else { return }
			if let error {
				self.logger.error("Active events listener failed: \(error.localizedDescription)")
				return
			}
			guard let snapshot else { return }
			Task {
				let activities = await self.mapDocuments(snapshot.documents)
				await MainActor.run { onChange(activities) }
			}
		}
		return ListenerRegistrationToken { registration.remove() }
	}

	func observeCompletedEvents(userId: String, onChange: @escaping ([ActivityData]) -> Void) -> ListenerRegistrationToken {
		let query = eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.completed.rawValue)
			.order(by: "completedAt", descending: true)
			.limit(to: 50)

		let registration = query.addSnapshotListener { [weak self] snapshot, error in
			guard let self else { return }
			if let error {
				self.logger.error("Completed events listener failed: \(error.localizedDescription)")
				return
			}
			guard let snapshot else { return }
			Task {
				let activities = await self.mapDocuments(snapshot.documents)
				await MainActor.run { onChange(activities) }
			}
		}
		return ListenerRegistrationToken { registration.remove() }
	}

	// MARK: - Fetch

	func fetchActiveEvents(userId: String) async throws -> [ActivityData] {
		let snapshot = try await eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.active.rawValue)
			.order(by: "scheduledAt", descending: false)
			.getDocuments()
		return await mapDocuments(snapshot.documents)
	}

	func fetchCompletedEvents(userId: String, limit: Int = 50, cursor: Date? = nil) async throws -> [ActivityData] {
		var query: Query = eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.completed.rawValue)
			.order(by: "completedAt", descending: true)
			.limit(to: limit)

		if let cursor {
			query = query.start(after: [Timestamp(date: cursor)])
		}

		let snapshot = try await query.getDocuments()
		return await mapDocuments(snapshot.documents)
	}

	// MARK: - Write

	func upsert(
		from payload: [String: Any],
		isCompleted: Bool,
		syncStatus: String,
		source: String,
		userId: String
	) async throws {
		let (document, segments) = EventDocumentMapper.document(
			from: payload,
			userId: userId,
			isCompleted: isCompleted,
			syncStatus: syncStatus,
			source: source
		)
		try await write(document: document, segments: segments, merge: true)
	}

	func updateMetadata(eventId: Int, userId: String, name: String, location: String) async throws {
		let ref = eventRef(eventId: eventId)
		let snapshot = try await ref.getDocument()
		guard snapshot.exists,
			  var document = try? snapshot.data(as: FirestoreEventDocument.self) else { return }
		document = EventDocumentMapper.updatedDocument(document, name: name, location: location)
		try ref.setData(from: document, merge: true)
	}

	func softDelete(eventId: Int, userId: String) async throws {
		let ref = eventRef(eventId: eventId)
		try await ref.setData([
			"status": EventStatus.deleted.rawValue,
			"deletedAt": FieldValue.serverTimestamp(),
			"updatedAt": FieldValue.serverTimestamp(),
			"userId": userId
		], merge: true)
	}

	// MARK: - Private

	private func eventsQuery(userId: String) -> Query {
		db.collection("events").whereField("userId", isEqualTo: userId)
	}

	private func eventRef(eventId: Int) -> DocumentReference {
		db.collection("events").document(String(eventId))
	}

	private func write(document: FirestoreEventDocument, segments: [EventSegmentDocument], merge: Bool) async throws {
		let batch = db.batch()
		let ref = eventRef(eventId: document.id)
		try batch.setData(from: document, forDocument: ref, merge: merge)

		let segmentsRef = ref.collection("segments")
		let existing = try await segmentsRef.getDocuments()
		for doc in existing.documents {
			batch.deleteDocument(doc.reference)
		}
		for segment in segments {
			let segmentRef = segmentsRef.document(String(segment.index))
			try batch.setData(from: segment, forDocument: segmentRef, merge: true)
		}
		try await batch.commit()
	}

	private func mapDocuments(_ documents: [QueryDocumentSnapshot]) async -> [ActivityData] {
		var results: [ActivityData] = []
		for doc in documents {
			guard let eventDoc = try? doc.data(as: FirestoreEventDocument.self) else { continue }
			let segmentsSnapshot = try? await doc.reference.collection("segments").order(by: "index").getDocuments()
			let segments = segmentsSnapshot?.documents.compactMap { try? $0.data(as: EventSegmentDocument.self) } ?? []
			if let activity = EventDocumentMapper.activityData(from: eventDoc, segments: segments) {
				results.append(activity)
			}
		}
		return results
	}
}
