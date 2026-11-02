//
//  ValidationType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/16/26.
//


// MARK: - Validation Type

enum ValidationType {
	case name
	case location
	case email
	case password
	case confirmPassword(new: String)
	case phoneNumber
	case alphanumeric
	case custom(regex: String)
	case none
	
	var validationMessage: String {
		switch self {
			case .name:             return "Please enter a valid name."
			case .location:         return "Enter a valid location (e.g. City)."
			case .email:            return "Please enter a valid email address."
			case .password:         return "Min 8 chars with uppercase, lowercase, digit & special character."
			case .confirmPassword:  return "Passwords do not match."
			case .phoneNumber:      return "Please enter a valid phone number."
			case .alphanumeric:     return "Only letters and numbers are allowed."
			case .custom:           return "Invalid input."
			case .none:             return ""
		}
	}

	// Context-aware message: lets a field explain *why* it's unhappy.
	// Defaults to the static message above.
	func message(for text: String) -> String {
		let digits = text.filter(\.isNumber)
		switch self {
			case .phoneNumber where digits.count >= 7 && Set(digits).count == 1:
				return "Nice try — that's not a real number. 🙂"
			default:
				return validationMessage
		}
	}
}

