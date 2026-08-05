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
}

