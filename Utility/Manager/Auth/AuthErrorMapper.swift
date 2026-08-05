//
//  AuthErrorMapper.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/9/26.
//

import Foundation
import FirebaseAuth

// MARK: - AuthErrorMapper
//
// Turns raw Firebase / network errors into short, non-technical messages fit to
// show a user. Always call this before presenting an auth error in a toast/alert.

enum AuthErrorMapper {

	static func message(for error: Error) -> String {
		let ns = error as NSError

		// Our own thrown errors already carry a friendly, user-ready message.
		if ns.domain == "AuthManager", let m = ns.userInfo[NSLocalizedDescriptionKey] as? String, !m.isEmpty {
			return m
		}

		// Non-Firebase failures (usually connectivity).
		guard ns.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: ns.code) else {
			return ns.domain == NSURLErrorDomain
				? "No internet connection. Please check your network and try again."
				: "Something went wrong. Please try again."
		}

		switch code {
		case .invalidActionCode, .expiredActionCode:
			return "This sign-in link is no longer valid. Please request a new one."
		case .invalidVerificationCode:
			return "That code isn't correct. Please check it and try again."
		case .missingVerificationCode, .sessionExpired, .invalidVerificationID:
			return "Your code has expired. Please request a new one."
		case .invalidPhoneNumber, .missingPhoneNumber:
			return "Please enter a valid phone number."
		case .invalidEmail, .missingEmail:
			return "Please enter a valid email address."
		case .tooManyRequests, .quotaExceeded:
			return "Too many attempts. Please wait a little and try again."
		case .networkError:
			return "No internet connection. Please check your network and try again."
		case .requiresRecentLogin, .userTokenExpired:
			return "For your security, please sign in again to continue."
		case .userNotFound:
			return "We couldn't find an account for those details."
		case .userDisabled:
			return "This account has been disabled. Please contact support."
		case .credentialAlreadyInUse, .emailAlreadyInUse:
			return "Those details are already linked to another account."
		default:
			return "Something went wrong. Please try again."
		}
	}
}
