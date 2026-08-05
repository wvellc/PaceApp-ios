//
//  EventRepositoryProtocol.swift
//  PaceApp
//

import Foundation

protocol EventRepositoryProtocol: AnyObject {
	func observeActiveEvents(userId: String, onChange: @escaping ([ActivityData]) -> Void) -> ListenerRegistrationToken
	func fetchActiveEvents(userId: String) async throws -> [ActivityData]
	func fetchCompletedEvents(userId: String, limit: Int, cursor: Any?) async throws -> [ActivityData]

	/// Paginated + filtered fetch for History screen.
	/// - Parameters:
	///   - userId: Owner of the events.
	///   - pageSize: Number of documents per page.
	///   - cursor: Opaque pagination cursor from previous page — nil for first page.
	///   - distanceMin: Minimum distance in miles (inclusive). Nil = no lower bound.
	///   - distanceMax: Maximum distance in miles (inclusive). Nil = no upper bound.
	///   - date: If set, restrict to events whose `completedAt` falls on this calendar day.
	///   - location: If non-empty, client-side case-insensitive substring filter on location.
	/// - Returns: Tuple of mapped events and an opaque cursor for the next page (nil when no more).
	func fetchFilteredCompletedEvents(
		userId: String,
		pageSize: Int,
		cursor: Any?,
		distanceMin: Double?,
		distanceMax: Double?,
		date: Date?,
		location: String?
	) async throws -> (events: [ActivityData], nextCursor: Any?)

	func upsert(from payload: [String: Any], isCompleted: Bool, syncStatus: String, source: String, userId: String) async throws
	func updateMetadata(eventId: Int, userId: String, name: String, location: String) async throws
	func softDelete(eventId: Int, userId: String) async throws
	func fetchEvents(byIds ids: [String]) async throws -> [ActivityData]

	// MARK: - ConnectIQ seeding
	// One query fetches all user events; client partitions by status. e.g. → ConnectIQEventSnapshot(activePayloads: [...], deletedIds: [3, 7])
	func fetchAllEventPayloads(userId: String) async throws -> ConnectIQEventSnapshot
}

/// Opaque handle for removing a Firestore listener.
final class ListenerRegistrationToken {
	private let removeHandler: () -> Void
	init(removeHandler: @escaping () -> Void) {
		self.removeHandler = removeHandler
	}

	func remove() { removeHandler() }

	deinit { removeHandler() }
}

enum EventRepository {
	static let shared: EventRepositoryProtocol = FirestoreEventRepository.shared
}
