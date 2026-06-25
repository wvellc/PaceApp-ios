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
	private let calendar = Calendar.current

	private init() {}

	// MARK: - Observe

	func observeActiveEvents(userId: String, onChange: @escaping ([ActivityData]) -> Void) -> ListenerRegistrationToken {
		let start = calendar.startOfDay(for: Date.now)

		let query = eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.active.rawValue)
			.whereField("scheduledAt", isGreaterThanOrEqualTo: Timestamp(date: start))
			.order(by: "scheduledAt", descending: false)

		let registration = query.addSnapshotListener { [weak self] snapshot, error in
			guard let self else { return }
			if let error {
				self.logger.error("Active events listener failed: \(error.localizedDescription)")
				return
			}
			guard let snapshot else { return }
			// Segments are now embedded in the document — no async subcollection fetch needed.
			let activities = self.mapDocuments(snapshot.documents)
			Task { await MainActor.run { onChange(activities) } }
		}
		return ListenerRegistrationToken { registration.remove() }
	}

	// MARK: - Fetch

	func fetchActiveEvents(userId: String) async throws -> [ActivityData] {
		let snapshot = try await eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.active.rawValue)
			.order(by: "scheduledAt", descending: false)
			.getDocuments()
		return mapDocuments(snapshot.documents)
	}

	func fetchCompletedEvents(userId: String, limit: Int = 150, cursor: Any? = nil) async throws -> [ActivityData] {
		var query: Query = eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.completed.rawValue)
			.order(by: "completedAt", descending: true)
			.limit(to: limit)

		if let snapshot = cursor as? DocumentSnapshot {
			query = query.start(afterDocument: snapshot)
		}

		let snapshot = try await query.getDocuments()
		return mapDocuments(snapshot.documents)
	}

	// MARK: - Filtered + Paginated Fetch (History screen)

	/// Firestore-side filters: distance range, exact date window.
	/// Location filtering is applied client-side (case-insensitive substring).
	/// Cursor pagination via DocumentSnapshot for robust page boundaries.
	///
	/// Composite index required:
	///   Collection: events
	///   Fields: userId ASC, status ASC, completedAt DESC
	///   (Add distanceValue ASC, completedAt DESC when distance filter is active.)
	func fetchFilteredCompletedEvents(
		userId: String,
		pageSize: Int,
		cursor: Any?,
		distanceMin: Double?,
		distanceMax: Double?,
		date: Date?,
		location: String?
	) async throws -> (events: [ActivityData], nextCursor: Any?) {

		var query: Query = eventsQuery(userId: userId)
			.whereField("status", isEqualTo: EventStatus.completed.rawValue)

		// ── Distance range ─────────────────────────────────────────────────────
		// distanceValue is stored in miles in Firestore (same unit as the slider).
		let defaultMin: Double = 0
		let defaultMax: Double = 150

		let effectiveMin = distanceMin ?? defaultMin
		let effectiveMax = distanceMax ?? defaultMax

		// Only add the range clause when it differs from defaults.
		let isDistanceFiltered = effectiveMin > defaultMin || effectiveMax < defaultMax

		// When both date and distance filters are active, Firestore cannot do range
		// inequalities on two fields. Apply distance server-side and date client-side
		// over-fetch scenario. When only distance is active, apply it server-side.
		let hasDateFilter = date != nil

		if isDistanceFiltered && !hasDateFilter {
			// Distance-only: server-side range + completedAt ordering.
			query = query
				.whereField("distanceValue", isGreaterThanOrEqualTo: effectiveMin)
				.whereField("distanceValue", isLessThanOrEqualTo: effectiveMax)
				.order(by: "distanceValue", descending: false)
				.order(by: "scheduledAt", descending: true)
		} else if hasDateFilter && !isDistanceFiltered {
			// Date-only: server-side completedAt window.
			let start = calendar.startOfDay(for: date!)
			let end   = calendar.date(byAdding: .day, value: 1, to: start) ?? start
			query = query
				.whereField("scheduledAt", isGreaterThanOrEqualTo: Timestamp(date: start))
				.whereField("scheduledAt", isLessThan: Timestamp(date: end))
				.order(by: "scheduledAt", descending: true)
		} else if hasDateFilter && isDistanceFiltered {
			// Both active: date server-side (range on completedAt), distance client-side.
			// Over-fetch to compensate for client-side distance trimming.
			let start = calendar.startOfDay(for: date!)
			let end   = calendar.date(byAdding: .day, value: 1, to: start) ?? start
			query = query
				.whereField("scheduledAt", isGreaterThanOrEqualTo: Timestamp(date: start))
				.whereField("scheduledAt", isLessThan: Timestamp(date: end))
				.order(by: "scheduledAt", descending: true)
		} else {
			// No date or distance filter — just order by completedAt.
			query = query.order(by: "scheduledAt", descending: true)
		}

		// ── Pagination ─────────────────────────────────────────────────────────
		// Over-fetch when distance will be applied client-side.
		let fetchSize = (hasDateFilter && isDistanceFiltered) ? pageSize * 3 : pageSize
		query = query.limit(to: fetchSize)

		if let lastDoc = cursor as? DocumentSnapshot {
			query = query.start(afterDocument: lastDoc)
		}

		// ── Cache-first strategy ──────────────────────────────────────────────
		// Try local cache for instant display; fall back to server on cache miss.
		let snapshot: QuerySnapshot
		do {
			snapshot = try await query.getDocuments(source: .default)
		} catch {
			snapshot = try await query.getDocuments(source: .cache)
		}

		var activities = mapDocuments(snapshot.documents)

		// ── Client-side distance filter (when both date + distance active) ────
		if hasDateFilter && isDistanceFiltered {
			activities = activities.filter { activity in
				let miles = Self.parseMilesFromDisplay(activity.distance)
				return miles >= effectiveMin && miles <= effectiveMax
			}
		}

		// ── Client-side location filter (case-insensitive substring) ───────────
		if let location, !location.trimmingCharacters(in: .whitespaces).isEmpty {
			let locationQuery = location.trimmingCharacters(in: .whitespaces).lowercased()
			activities = activities.filter {
				$0.location.lowercased().contains(locationQuery)
			}
		}

		// Next cursor is the last Firestore document from the raw snapshot.
		let nextCursor: Any? = snapshot.documents.last
		return (events: activities, nextCursor: nextCursor)
	}

	/// Parses miles from display strings like "5.00 mi" or "10.00 km".
	private static func parseMilesFromDisplay(_ display: String) -> Double {
		let cleaned = display
			.replacingOccurrences(of: " mi", with: "")
			.replacingOccurrences(of: " km", with: "")
			.trimmingCharacters(in: .whitespaces)
		return Double(cleaned) ?? 0
	}

	// MARK: - Write

	func upsert(
		from payload: [String: Any],
		isCompleted: Bool,
		syncStatus: String,
		source: String,
		userId: String
	) async throws {
		let (document, _) = EventDocumentMapper.document(
			from: payload,
			userId: userId,
			isCompleted: isCompleted,
			syncStatus: syncStatus,
			source: source
		)
		// Segments are embedded in document.segments — single document write, no subcollection.
		try await write(document: document, merge: true)
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

	/// Single document write — segments are stored as an embedded array field.
	/// Previously required a batch write + subcollection; now a single setData call.
	private func write(document: FirestoreEventDocument, merge: Bool) async throws {
		let ref = eventRef(eventId: document.id)
		try ref.setData(from: document, merge: merge)
	}

	/// Maps Firestore documents to ActivityData — segments are read from the embedded
	/// document field, eliminating the previous per-event subcollection fetch.
	private func mapDocuments(_ documents: [QueryDocumentSnapshot]) -> [ActivityData] {
		documents.compactMap { doc in
			guard let eventDoc = try? doc.data(as: FirestoreEventDocument.self) else { return nil }
			// Use embedded segments if present; fall back to empty for legacy documents.
			let segments = eventDoc.segments ?? []
			return EventDocumentMapper.activityData(from: eventDoc, segments: segments)
		}
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

			let batchActivities = mapDocuments(snapshot.documents)
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
