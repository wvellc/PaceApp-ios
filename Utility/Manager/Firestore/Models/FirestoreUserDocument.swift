//
//  FirestoreUserDocument.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore

struct FirestoreUserDocument: Codable {
	var uuid: String
	var firstName: String
	var lastName: String
	var gender: String
	var email: String
	var phoneNumber: String
	var lastSyncedAt: Timestamp?
}
