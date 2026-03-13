//
//  LoginType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import Foundation

/// Represents the type of login method available.
enum LoginType: String, CaseIterable, Identifiable, Equatable {
	case email
	case phoneNumber
	
	var id: String { rawValue }
	
	/// The display title for the login type.
	var title: LocalizedStringResource {
		switch self {
			case .email:
				return .email
			case .phoneNumber:
			return .phoneNumber
		}
	}
}
