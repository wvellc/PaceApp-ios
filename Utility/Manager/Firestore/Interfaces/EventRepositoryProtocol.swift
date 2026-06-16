//
//  EventRepositoryProtocol.swift
//  PaceApp
//

import Foundation

protocol EventRepositoryProtocol: AnyObject {
	func observeActiveEvents(userId: String, onChange: @escaping ([ActivityData]) -> Void) -> ListenerRegistrationToken
	func observeCompletedEvents(userId: String, onChange: @escaping ([ActivityData]) -> Void) -> ListenerRegistrationToken
	func fetchActiveEvents(userId: String) async throws -> [ActivityData]
	func fetchCompletedEvents(userId: String, limit: Int, cursor: Date?) async throws -> [ActivityData]
	func upsert(from payload: [String: Any], isCompleted: Bool, syncStatus: String, source: String, userId: String) async throws
	func updateMetadata(eventId: Int, userId: String, name: String, location: String) async throws
	func softDelete(eventId: Int, userId: String) async throws
	func fetchEvents(byIds ids: [String]) async throws -> [ActivityData]
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
