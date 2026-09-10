//
//  WatchOutboxEntry.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 9/10/26.
//

import Foundation

// MARK: - WatchOutboxEntry

/// A phone event change the watch hasn't confirmed yet — persisted, so it survives disconnects and relaunches.
struct WatchOutboxEntry: Codable, Equatable {

	enum Change: String, Codable {
		case upsert   // create_event (active) or finish_event (completed) — picked when sent
		case delete   // delete_event
	}

	/// Unique per enqueue, so a send only clears the entry it actually delivered.
	let token: UUID
	let eventId: Int
	let change: Change
}
