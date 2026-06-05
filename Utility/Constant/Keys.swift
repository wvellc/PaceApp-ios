//
//  Keys.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

// MARK: - Storage Keys
struct Keys {
    static let accessToken          = "user_access_token"
    static let garminAccessToken    = "garmin_access_token"
    static let userProfile          = "user_profile_cache"
    static let onboardingComplete   = "onboarding_complete"

    // MARK: Firebase Auth
    /// Stores the Firebase phone verification ID between OTP send and verify steps.
    static let authVerificationID   = "authVerificationID"
    /// Stores the email address that requested a sign-in link so it can be
    /// retrieved when the deep link re-opens the app on the same device.
    static let emailForSignIn       = "emailForSignIn"
}
