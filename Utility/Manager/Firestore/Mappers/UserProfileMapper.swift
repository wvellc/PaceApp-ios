//
//  UserProfileMapper.swift
//  PaceApp
//

import Foundation
import FirebaseFirestore

enum UserProfileMapper {

	static func document(from model: UserModel, userId: String) -> FirestoreUserDocument {
		FirestoreUserDocument(
			uuid: userId,
			firstName: model.firstName ?? "",
			lastName: model.lastName ?? "",
			gender: model.gender?.rawValue ?? "",
			email: model.email ?? "",
			phoneNumber: model.phoneNumber ?? "",
			lastSyncedAt: Timestamp(date: Date())
		)
	}

	static func userModel(from document: FirestoreUserDocument, userId: String) -> UserModel {
		var model = UserModel(uuid: userId)
		model.firstName = document.firstName.nilIfEmpty
		model.lastName = document.lastName.nilIfEmpty
		if let gender = Gender(rawValue: document.gender) {
			model.gender = gender
		}
		model.email = document.email.nilIfEmpty
		model.phoneNumber = document.phoneNumber.nilIfEmpty
		return model
	}
}

extension String {
	var nilIfEmpty: String? {
		let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}
}
