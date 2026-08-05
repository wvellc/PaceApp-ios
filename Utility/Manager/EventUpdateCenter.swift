//
//  EventUpdateCenter.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/8/26.
//

import SwiftUI

// MARK: - EventUpdateCenter

/// App-wide broadcast for event metadata edits (name / location) so every screen
/// holding a copy of the event reflects the change without a manual refetch.
///
/// Mirrors `EventDeletionCenter`: the Firestore write stays the source of truth,
/// this just nudges the open Event Details screen and the one-shot History list to
/// patch the matching row in place. Home's upcoming list already updates live via
/// its Firestore listener, so it needs nothing here.
@MainActor
@Observable
final class EventUpdateCenter {

	// MARK: - Singleton

	static let shared = EventUpdateCenter()
	private init() {}

	// MARK: - Payload

	/// A single name / location edit for one event.
	struct MetadataUpdate: Equatable {
		let eventId: Int
		let name: String
		let location: String
	}

	// MARK: - State

	/// The most recent metadata edit. Screens observe this via `.onChange` and patch
	/// the event whose id matches.
	private(set) var lastUpdate: MetadataUpdate?

	// MARK: - Publish

	/// Broadcasts that the event's name / location changed.
	func notifyUpdated(eventId: Int, name: String, location: String) {
		lastUpdate = MetadataUpdate(eventId: eventId, name: name, location: location)
	}
}
