//
//  LoginType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import Combine
import SwiftUI
import CountryPicker

// MARK: - LoginViewModel

/// ViewModel responsible for managing the state and business logic
@Observable
final class LoginViewModel {
	
	// MARK: - Dependencies
	
	// MARK: - Published Properties
	
	/// Currently selected login type.
	var loginType: LoginType = .phoneNumber
	
	/// The entered phone number string.
	var phoneNumber: String = ""
	
	/// The entered email address string.
	var email: String = ""
	
	/// The selected country dial code prefix.
	var countryCode: Country = .init(countryCode: "US")
	
	/// Loading state indicator for async operations.
	var state: OTPState = .idle
	
	
	// MARK: - Init
	
	// MARK: - Navigation events (View reacts to these)
	var navigationEvent: NavigationEvent?
	
	enum NavigationEvent {
		case sendOTP
		case tearmsOfService
		case privacyPolicy
	}
	
	// MARK: - Computed: Single Validation Source of Truth
	
	var isInputValid: Bool {
		switch loginType {
			case .email:       return email.isEmailAddress()
			case .phoneNumber: return phoneNumber.isPhoneNumber()
		}
	}
	
	// MARK: - Validate & Focus (called on submit)
	
	@MainActor
	@discardableResult
	func validate(focus: inout LoginType?) -> Bool {
		guard isInputValid else {
//			focus = loginType == .email ? .email : .phoneNumber
			return false
		}
		focus = nil
		return true
	}
	
	// MARK: - Send OTP
	
	/// Attempts to send an OTP asynchronously.
	@MainActor
	func sendOTP() async {
		guard isInputValid && state != .sending else {
			return
		}

		saveLoginContact()
		
		//Manage state
		state = .sending
		
		
		do {
			// OTP sending logic goes here.
			try await Task.sleep(for: .seconds(0.8))
			
			//TO Verify OTP
			await navigateToVerification()
			
			//Manage state
			state = .success
					
		} catch {
			//Manage state
			state = .error(error.localizedDescription)

		}
	}
	
	// MARK: - Helpers
	/// Returns the normalized phone number combining country code and digits only.
	func normalizedPhone() -> String {
		let digits = phoneNumber.filter(\.isNumber)
		return (countryCode.dialingCode ?? "") + digits
	}

	private func saveLoginContact() {
		var user = AppSession.userDetails ?? UserModel(uuid: UUID().uuidString)

		switch loginType {
			case .email:
				user.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
				user.phoneNumber = nil
			case .phoneNumber:
				user.phoneNumber = normalizedPhone()
				user.email = nil
		}

		AppSession.userDetails = user
	}
	
	/// Switches the login type and resets input + error state.
	func switchTo(_ type: LoginType) {
		loginType = type
	}
	
	// MARK: - Navigation
	
	func openTermsOfService() {
		navigationEvent = .tearmsOfService
	}
	
	func openPrivacyPolicy() {
		navigationEvent = .privacyPolicy
	}
	
	func navigateToVerification() async {
		navigationEvent = .sendOTP
	}
	
}
