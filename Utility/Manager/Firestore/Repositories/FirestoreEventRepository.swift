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

	func fetchCompletedEvents(userId: String, limit: Int = 150, cursor: Date? = nil) async throws -> [ActivityData] {
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

	// MARK: - Filtered + Paginated Fetch (History screen)

	/// Firestore-side filters: distance range, exact date window, location equality.
	/// Cursor pagination on `completedAt` descending. Page size = pageSize.
	///
	/// Composite index required:
	///   Collection: events
	///   Fields: userId ASC, status ASC, completedAt DESC
	///   (Add distanceValue ASC when distance filter is active — Firestore requires
	///    any range-filtered field to precede the orderBy field in the index.)
	func fetchFilteredCompletedEvents(
		userId: String,
		pageSize: Int,
		cursor: Date?,
		distanceMin: Double?,
		distanceMax: Double?,
		date: Date?,
		location: String?
	) async throws -> [ActivityData] {

		var query: Query = eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.completed.rawValue)

		// ── Distance range ─────────────────────────────────────────────────────
		// distanceValue is stored in miles in Firestore (same unit as the slider).
		let defaultMin: Double = 0
		let defaultMax: Double = 150

		let effectiveMin = distanceMin ?? defaultMin
		let effectiveMax = distanceMax ?? defaultMax

		// Only add the range clause when it is non-trivial — avoids requiring a
		// composite index on distanceValue for unfiltered loads.
		let isDistanceFiltered = effectiveMin > defaultMin || effectiveMax < defaultMax
		if isDistanceFiltered {
			query = query
				.whereField("distanceValue", isGreaterThanOrEqualTo: effectiveMin)
				.whereField("distanceValue", isLessThanOrEqualTo: effectiveMax)
				// When a range filter is present Firestore requires orderBy on
				// that same field before any other orderBy.
				.order(by: "distanceValue", descending: false)
		}

		// ── Date window ────────────────────────────────────────────────────────
		// Convert the calendar day into a [start, end) Timestamp window so the
		// query can use an inequality on `completedAt` without a separate index.
		if let date {
			let calendar = Calendar.current
			let start = calendar.startOfDay(for: date)
			let end   = calendar.date(byAdding: .day, value: 1, to: start) ?? start
			query = query
				.whereField("completedAt", isGreaterThanOrEqualTo: Timestamp(date: start))
				.whereField("completedAt", isLessThan: Timestamp(date: end))
		}

		// ── Location exact match ────────────────────────────────────────────────
		// Firestore equality does not require an extra index field.
		if let location, !location.trimmingCharacters(in: .whitespaces).isEmpty {
			query = query.whereField("location", isEqualTo: location.trimmingCharacters(in: .whitespaces))
		}

		// ── Order + pagination ─────────────────────────────────────────────────
		// Only add the completedAt order when no distance range is active (to
		// avoid a multi-field range conflict). When distance IS filtered the
		// client receives at most pageSize rows sorted by distanceValue — which
		// is acceptable UX for a filtered page.
		if !isDistanceFiltered {
			query = query.order(by: "completedAt", descending: true)
		}

		query = query.limit(to: pageSize)

		if let cursor, !isDistanceFiltered {
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

		// Write segments directly by index as document ID — no prior read needed.
		// Skipping getDocuments() avoids a subcollection read before the parent
		// event exists, which was causing the "Missing or insufficient permissions"
		// error on new event creation (parent not yet committed when rule evaluated).
		let segmentsRef = ref.collection("segments")
		for segment in segments {
			let segmentRef = segmentsRef.document(String(segment.index))
			try batch.setData(from: segment, forDocument: segmentRef, merge: false)
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

	// MARK: - Fetch Favorites / By IDs

	/// Fetches specific events by their document/sync IDs.
	/// Batched because Firestore 'in' queries are limited to 30 values.
	func fetchEvents(byIds ids: [String]) async throws -> [ActivityData] {
		guard !ids.isEmpty else { return [] }

		var allResults: [ActivityData] = []

		// Batch in groups of 30 (Firestore 'in' limit)
		for batchIds in ids.chunked(into: 30) {
			let snapshot = try await db.collection("events")
				.whereField(FieldPath.documentID(), in: batchIds)
				.getDocuments()

			let batchActivities = await mapDocuments(snapshot.documents)
			allResults.append(contentsOf: batchActivities)
		}

		return allResults
	}

	// MARK: - ConnectIQ seeding

	// One query → client-side partition by status. 1 read vs 3, no composite index needed.
	func fetchAllEventPayloads(userId: String) async throws -> ConnectIQEventSnapshot {
		let snapshot = try await eventsQuery(userId: userId).getDocuments()

		var active: [[String: Any]] = []
		var completed: [[String: Any]] = []
		var deletedIds: [Int] = []

		for doc in snapshot.documents {
			guard let event = try? doc.data(as: FirestoreEventDocument.self) else { continue }
			let payload = EventDocumentMapper.connectIQPayload(from: event)
			switch event.eventStatus {
			case .active:    active.append(payload)
			case .completed: completed.append(payload)
			case .deleted:   deletedIds.append(event.id)
			}
		}

		return ConnectIQEventSnapshot(
			activePayloads: active,
			completedPayloads: completed,
			deletedIds: deletedIds
		)
	}

}
