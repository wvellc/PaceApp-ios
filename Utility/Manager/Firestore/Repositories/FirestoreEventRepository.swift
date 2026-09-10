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
		// NOTE: No `scheduledAt >= today` filter. An active event whose scheduled
		// date is in the past but was never completed is still pending — filtering
		// it out here orphaned it (invisible in Home *and* History). Show every
		// active event; past-dated ones simply sort to the top as overdue.
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

		// Distance is always filtered client-side: stored distanceValue is unit-mixed
		// (miles or km per event's measure), so a server range can't compare correctly.
		let hasDateFilter = date != nil

		if hasDateFilter {
			// Date: server-side scheduledAt window.
			let start = calendar.startOfDay(for: date!)
			let end   = calendar.date(byAdding: .day, value: 1, to: start) ?? start
			query = query
				.whereField("scheduledAt", isGreaterThanOrEqualTo: Timestamp(date: start))
				.whereField("scheduledAt", isLessThan: Timestamp(date: end))
				.order(by: "scheduledAt", descending: true)
		} else {
			// No date filter — newest activity first: order by last update
			// so a freshly edited or synced event jumps to the top of History.
			query = query.order(by: "updatedAt", descending: true)
		}

		// ── Pagination ─────────────────────────────────────────────────────────
		// Over-fetch when distance will be applied client-side.
		let fetchSize = isDistanceFiltered ? pageSize * 3 : pageSize
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

		// ── Client-side distance filter (unit-aware, miles-denominated range) ──
		if isDistanceFiltered {
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

	/// Parses miles from display strings like "5.00 mi" or "10.00 km" — km values convert to miles.
	private static func parseMilesFromDisplay(_ display: String) -> Double {
		let isKm = display.contains(" km")
		let cleaned = display
			.replacingOccurrences(of: " mi", with: "")
			.replacingOccurrences(of: " km", with: "")
			.trimmingCharacters(in: .whitespaces)
		let value = Double(cleaned) ?? 0
		return isKm ? value * 0.621371 : value
	}

	// MARK: - Write

	func upsert(
		from payload: [String: Any],
		isCompleted: Bool,
		syncStatus: String,
		source: String,
		userId: String
	) async throws {
		var (document, _) = EventDocumentMapper.document(
			from: payload,
			userId: userId,
			isCompleted: isCompleted,
			syncStatus: syncStatus,
			source: source
		)

		// Write-once fields (source/createdAt/completedAt) must survive every app ⇄ watch
		// round-trip — carry the stored values forward instead of the freshly stamped ones.
		let ref = eventRef(eventId: document.id)
		let snapshot: DocumentSnapshot?
		do {
			snapshot = try await ref.getDocument(source: .default)
		} catch let error where error.isFirestorePermissionDenied {
			// Another account owns this doc — a write would flash it into this user's lists until the server rejects it.
			throw error
		} catch {
			snapshot = nil
		}
		if let snapshot, snapshot.exists, let current = try? snapshot.data(as: EventDocument.self) {
			document.source      = current.source
			document.createdAt   = current.createdAt
			document.completedAt = current.completedAt ?? document.completedAt
			// A finished event never turns back into an upcoming one — a stale active copy is ignored.
			if current.eventStatus == .completed, document.eventStatus == .active { return }
			// A user-deleted event stays deleted — a later watch re-sync must not resurrect it.
			if current.eventStatus == .deleted { document.status = EventStatus.deleted.rawValue }
			try await write(document: document, merge: true)
		} else if let snapshot, !snapshot.exists {
			// Confirmed new document — full write, including the write-once fields.
			try await write(document: document, merge: true)
		} else {
			// Read failed (offline, cold cache) or stored doc didn't decode — merge without
			// the write-once fields so a possibly existing doc is never blindly rewritten.
			try await writeSkippingImmutableFields(document)
		}
	}

	func updateMetadata(eventId: Int, userId: String, name: String, location: String) async throws {
		let ref = eventRef(eventId: eventId)
		let snapshot = try await ref.getDocument()
		guard snapshot.exists,
			  var document = try? snapshot.data(as: EventDocument.self) else { return }
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
	private func write(document: EventDocument, merge: Bool) async throws {
		let ref = eventRef(eventId: document.id)
		try ref.setData(from: document, merge: merge)
	}

	// Merge-write that strips the write-once keys — used when the stored copy is unreadable.
	private func writeSkippingImmutableFields(_ document: EventDocument) async throws {
		var data = try Firestore.Encoder().encode(document)
		data.removeValue(forKey: "source")
		data.removeValue(forKey: "createdAt")
		data.removeValue(forKey: "completedAt")
		try await eventRef(eventId: document.id).setData(data, merge: true)
	}

	/// Maps Firestore documents to ActivityData — segments are read from the embedded
	/// document field, eliminating the previous per-event subcollection fetch.
	private func mapDocuments(_ documents: [QueryDocumentSnapshot]) -> [ActivityData] {
		documents.compactMap { doc in
			guard let eventDoc = try? doc.data(as: EventDocument.self) else { return nil }
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

			// Unlike the active/completed queries, this fetch is keyed purely by
			// document ID, so soft-deleted events would otherwise slip through —
			// e.g. a favorited event that was later deleted. Filter them out.
			let liveDocuments = snapshot.documents.filter {
				(try? $0.data(as: EventDocument.self))?.eventStatus != .deleted
			}

			let batchActivities = mapDocuments(liveDocuments)
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
		var deletedEvents: [Int: Date] = [:]

		for doc in snapshot.documents {
			guard let event = try? doc.data(as: EventDocument.self) else { continue }
			let payload = EventDocumentMapper.connectIQPayload(from: event)
			switch event.eventStatus {
			case .active:    active.append(payload)
			case .completed: completed.append(payload)
			// A still-pending server timestamp reads back as nil — that delete has only just happened.
			case .deleted:   deletedEvents[event.id] = event.deletedAt?.dateValue() ?? Date()
			}
		}

		return ConnectIQEventSnapshot(
			activePayloads: active,
			completedPayloads: completed,
			deletedEvents: deletedEvents
		)
	}

}
