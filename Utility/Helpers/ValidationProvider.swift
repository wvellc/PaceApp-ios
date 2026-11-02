//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/16/26.
//

import Foundation

// MARK: - ValidationProvider

struct ValidationProvider {
	
	static func isValid(text: String, type: ValidationType) -> Bool {
		switch type {
			case .none:
				return true
			case .name:
				return matches(text, regex: "^[a-zA-ZÀ-ÿ' -]{1,}$")
			case .email:
				return matches(text, regex: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
			case .password:
				return matches(text, regex: "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z\\d]).{8,}$")
			case .confirmPassword(let new):
				return text == new
			case .phoneNumber:
				return isValidPhoneNumber(text)
			case .alphanumeric:
				return matches(text, regex: "^[a-zA-Z0-9]+$")
			case .custom(let regex):
				return matches(text, regex: regex)
			case .location:
				return matches(text, regex: "^[\\p{L}\\s\\-\\']{1,50}$")
		}
	}
	
	private static func matches(_ text: String, regex: String) -> Bool {
		guard let expression = try? NSRegularExpression(pattern: regex) else { return false }
		let range = NSRange(text.startIndex..., in: text)
		return expression.firstMatch(in: text, range: range) != nil
	}

	// Phone: 7–15 digits (the E.164 national-number range, so every country's plan fits —
	// the country code is chosen separately), and not the same digit repeated.
	private static func isValidPhoneNumber(_ text: String) -> Bool {
		let digits = text.filter(\.isNumber)
		guard (7...15).contains(digits.count) else { return false }
		return Set(digits).count > 1
	}
}

