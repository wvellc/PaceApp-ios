//
//  OTPState.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/16/26.
//


enum OTPState: Equatable {
    case idle                           // User is typing phone number
    case sending                        // API call in progress (show spinner)
    case otpSent(verificationID: String) // Show the "Enter Code" screen
    case verifying                      // Verifying the 6-digit code
    case success                        // Navigation to Home/Profile
    case error(String)                  // Show an alert or error label
}
