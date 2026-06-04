//
//  Keys.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//


// MARK: Storage Keys
struct Keys {
	static let accessToken              = "user_access_token"
	static let garminAccessToken		= "garmin_access_token"
	static let userProfile              = "user_profile_cache"
	static let onboardingComplete       = "onboarding_complete"

	// MARK: - Firebase Auth
	/// Stores the Firebase phone verification ID between the OTP send and verify steps.
	static let authVerificationID       = "authVerificationID"
	/// Stores the email address used to request a sign-in link so it can be retrieved on deep-link open.
	static let emailForSignIn           = "emailForSignIn"
}
