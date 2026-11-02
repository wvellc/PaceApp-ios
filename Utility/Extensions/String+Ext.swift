//
//  String+Ext.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/16/26.
//

import Foundation

// MARK: - String Extension
extension String {
	
	// MARK: - App Helpers
	
	var setAppNamePrefix: String {
		return "\(LocalizedStringResource.paceApp)_\(self)"
	}
	
	// MARK: - Format
	
	/// Format with two decimal digits
	static func formatWithTwoDigits(value: Double) -> String {
		return String(format: "%.2f", value)
	}
	
	/// Trims leading and trailing whitespace and newlines.
	func trim() -> String {
		return trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	// MARK: - Validations (delegated to ValidationProvider)
	
	/// Name: letters, spaces, hyphens, apostrophes; min 2 chars.
	func isName() -> Bool {
		ValidationProvider.isValid(text: self, type: .name)
	}
	
	/// Email: standard RFC-style address format.
	func isEmailAddress() -> Bool {
		ValidationProvider.isValid(text: self, type: .email)
	}
	
	/// Password: min 8 chars, upper, lower, digit, special char.
	func isPassword() -> Bool {
		ValidationProvider.isValid(text: self, type: .password)
	}
	
	/// Phone number: 7–15 digits (the E.164 national range) and not all the same digit —
	/// permissive enough for every country's numbering plan.
	func isPhoneNumber() -> Bool {
		ValidationProvider.isValid(text: self, type: .phoneNumber)
	}

	/// Live display format for a phone number: strips non-digits, caps at 15 (the E.164
	/// ceiling), and groups into space-separated blocks of 5. Idempotent, so it's safe
	/// to re-run on itself.
	func asGroupedMobileNumber() -> String {
		let digits = Array(filter(\.isNumber).prefix(15))
		return stride(from: 0, to: digits.count, by: 5)
			.map { String(digits[$0..<min($0 + 5, digits.count)]) }
			.joined(separator: " ")
	}
	
	/// Alphanumeric: letters and digits only, no spaces or special chars.
	func isAlphaNumericValid() -> Bool {
		ValidationProvider.isValid(text: self, type: .alphanumeric)
	}
	
	/// Custom regex validation.
	func isValid(regex: String) -> Bool {
		ValidationProvider.isValid(text: self, type: .custom(regex: regex))
	}
	
	// MARK: - Character Checks
	
	var isDigits: Bool {
		guard !isEmpty else { return false }
		return !contains { Int(String($0)) == nil }
	}
	
	var isNumeric: Bool {
		ValidationProvider.isValid(text: self, type: .custom(regex: ".*[0-9]+.*"))
	}
	
	var isAlphaNumeric: Bool {
		ValidationProvider.isValid(text: self, type: .alphanumeric)
	}
	
	var isSpecialCharacter: Bool {
		let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
		return rangeOfCharacter(from: characterset.inverted) != nil
	}
	
	var isCharacterOnly: Bool {
		return !(isSpecialCharacter && isNumeric)
	}
	
	var isValidPostalCodeGlobal: Bool {
		return trim().count > 2
	}
	
	var isValidNumberCharacter: Bool {
		let allowed = CharacterSet(charactersIn: ".0123456789").inverted
		let filtered = components(separatedBy: allowed).joined()
		return !filtered.isEmpty
	}
	
	// MARK: - Formatting Helpers
	
	func removeSpecialCharsFromString() -> String {
		let allowed: Set<Character> = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
		return String(filter { allowed.contains($0) })
	}
	
	func isUserName() -> Bool {
		return trimmingCharacters(in: .whitespaces).count >= 3
	}
}

extension String {
	var nilIfEmpty: String? {
		let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}
}
