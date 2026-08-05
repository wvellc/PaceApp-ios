//
//  LoginViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import Combine
import SwiftUI
import CountryPicker

// MARK: - LoginViewModel

@Observable
final class LoginViewModel {

    // MARK: - Published Properties

    /// Currently selected login type.
    var loginType: LoginType = .phoneNumber

    /// The entered phone number string.
    var phoneNumber: String = ""

    /// The entered email address string.
    var email: String = ""

    /// The selected country dial code prefix.
    var countryCode: Country = .init(countryCode: "US")

    /// Loading / request state.
    var state: OTPState = .idle

    // MARK: - Navigation events (View reacts to these)
    var navigationEvent: NavigationEvent?

    enum NavigationEvent {
        case sendOTP
        case tearmsOfService
        case privacyPolicy
    }

    // MARK: - Validation

    var isInputValid: Bool {
        switch loginType {
        case .email:       return email.isEmailAddress()
        case .phoneNumber: return phoneNumber.isPhoneNumber()
        }
    }

    // MARK: - Validate & Focus

    @MainActor
    @discardableResult
    func validate(focus: inout LoginType?) -> Bool {
        guard isInputValid else { return false }
        focus = nil
        return true
    }

    // MARK: - Send OTP / Email Link

    @MainActor
    func sendOTP() async {
        guard isInputValid, state != .sending else { return }

        state = .sending

        do {
            if loginType == .phoneNumber {
                let formattedNumber = normalizedPhone()
                // sendOTP already persists verificationID to Keys.authVerificationID
                let verificationID = try await AuthManager.shared.sendOTP(phoneNumber: formattedNumber)
                // Assign both state and navigationEvent synchronously on MainActor —
                // no intermediate suspend point prevents the reCAPTCHA-return race
                // where the navigation event could fire in the wrong order.
                state = .otpSent(verificationID: verificationID)
                navigationEvent = .sendOTP
            } else {
                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                // sendEmailLink persists the email to Keys.emailForSignIn
                try await AuthManager.shared.sendEmailLink(email: cleanEmail)
                state = .success
				email = ""
				
                ToastManager.shared.present(.success("Login link sent! Please check your email inbox."))
            }
        } catch {
            let message = AuthErrorMapper.message(for: error)
            state = .error(message)
            ToastManager.shared.present(.error(message))
        }
    }

    // MARK: - Helpers

    func normalizedPhone() -> String {
        let digits = phoneNumber.filter(\.isNumber)
        return (countryCode.dialingCode ?? "") + digits
    }



    func switchTo(_ type: LoginType) {
        loginType = type
    }

    // MARK: - Navigation

    func openTermsOfService() { navigationEvent = .tearmsOfService }
    func openPrivacyPolicy()  { navigationEvent = .privacyPolicy }
}
