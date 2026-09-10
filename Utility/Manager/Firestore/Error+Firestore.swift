//
//  Error+Firestore.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 9/10/26.
//

import Foundation
import FirebaseFirestore

extension Error {

	/// True when Firestore security rules rejected the request — e.g. a doc owned by another account.
	nonisolated var isFirestorePermissionDenied: Bool {
		let error = self as NSError
		return error.domain == FirestoreErrorDomain && error.code == FirestoreErrorCode.permissionDenied.rawValue
	}
}
