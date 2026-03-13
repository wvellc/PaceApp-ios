//
//  LoginType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//


import SwiftUI
import Combine


/// ViewModel responsible for managing the state and business logic
/// of the Login screen using MVVM architecture.
final class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently selected login type.
    @Published var loginType: LoginType = .phoneNumber
    
    /// The entered phone number string.
    @Published var phoneNumber: String = ""
    
    /// The entered email address string.
    @Published var email: String = ""
    
    /// The selected country dial code prefix.
    @Published var countryCode: String = "+62"
    
    /// Loading state indicator for async operations.
    @Published var isLoading: Bool = false
    
    /// Stores error messages related to login validation or sending OTP.
    @Published var errorMessage: String? = nil
    
    
    // MARK: - Computed Properties
    
    /// Validates the email format using a simple regex pattern.
    var isEmailValid: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format:"SELF MATCHES %@", pattern)
        return predicate.evaluate(with: email)
    }
    
    /// Validates the phone number ensuring at least 6 digits after stripping non-digit characters.
    var isPhoneValid: Bool {
        let digits = phoneNumber.filter { $0.isNumber }
        return digits.count >= 6
    }
    
    /// Determines if the form can send OTP based on the current login type and input validity.
    var canSendOTP: Bool {
        switch loginType {
        case .email:
            return isEmailValid
        case .phoneNumber:
            return isPhoneValid
        }
    }
    
    
    // MARK: - Methods
    
    /// Attempts to send an OTP asynchronously.
    ///
    /// Sets loading state, clears previous errors, simulates a delay,
    /// validates inputs, and updates error messages accordingly.
    @MainActor
    func sendOTP() async {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(for: .seconds(0.8))
        
        switch loginType {
        case .email:
            guard isEmailValid else {
                errorMessage = "Please enter a valid email address."
                isLoading = false
                return
            }
        case .phoneNumber:
            guard isPhoneValid else {
                errorMessage = "Please enter a valid phone number."
                isLoading = false
                return
            }
        }
        
        // OTP sending logic would go here.
        // For now, just simulate completion.
        
        isLoading = false
    }
    
    /// Returns the normalized phone number string combining country code and digits only phone number.
    func normalizedPhone() -> String {
        let digits = phoneNumber.filter { $0.isNumber }
        return countryCode + digits
    }
    
    /// Switches the login type and resets error messages.
    /// - Parameter type: The new login type to switch to.
    func switchTo(_ type: LoginType) {
        loginType = type
        errorMessage = nil
    }
}
