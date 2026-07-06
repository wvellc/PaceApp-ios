//
//  EventDeletionCenter.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/6/26.
//

import SwiftUI

// MARK: - EventDeletionCenter

/// App-wide broadcast for event deletions so every list stays consistent no
/// matter where the delete was triggered (Event Details, Home, History, …).
///
/// The Home "upcoming" list already updates live via its Firestore listener,
/// but History and Favorites are one-shot fetches — they observe this center
/// and prune the deleted item locally instead of refetching.
///
/// Both deletion paths publish here: `ConnectIQManager.applyDeletedEventId`
/// (synced events) and `HistoryViewModel.delete` (local-only events).
@MainActor
@Observable
final class EventDeletionCenter {

	// MARK: - Singleton

	static let shared = EventDeletionCenter()
	private init() {}

	// MARK: - State

	/// The most recently deleted event id. Screens observe this via `.onChange`
	/// and prune the matching row. Set even if the id was already deleted so a
	/// repeat delete still fires a change.
	private(set) var lastDeletedEventId: Int?

	/// Cumulative set of deleted ids — lets a list that loads *after* a delete
	/// still filter out the stale event.
	private(set) var deletedEventIds: Set<Int> = []

	// MARK: - Publish

	/// Broadcasts that the event with `eventId` was deleted.
	func notifyDeleted(eventId: Int) {
		deletedEventIds.insert(eventId)
		lastDeletedEventId = eventId
	}
}
