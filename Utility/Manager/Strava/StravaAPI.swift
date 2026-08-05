//
//  StravaAPI.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/9/26.
//

import Foundation
import FirebaseAuth

// MARK: - StravaAPI
//
// Thin URLSession client for the app's own Firebase HTTPS functions (NOT Strava
// directly). Every call carries the Firebase ID token so the function knows the
// user; the function talks to Strava with the secret we never ship in the app.

enum StravaAPI {

	// MARK: - Error

	/// User-facing error — the message is already friendly (surfaced by the function or mapped here).
	struct APIError: LocalizedError {
		let message: String
		var errorDescription: String? { message }
	}

	// MARK: - Request

	/// POSTs a JSON body to a function endpoint and returns the decoded JSON object.
	@discardableResult
	static func post(_ path: String, body: [String: Any] = [:]) async throws -> [String: Any] {
		guard let user = Auth.auth().currentUser else {
			throw APIError(message: "Please sign in again to continue.")
		}
		let idToken = try await user.getIDToken()

		guard let url = URL(string: StravaConst.functionsBaseURL + path) else {
			throw APIError(message: "Couldn't reach the server. Please try again.")
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
		request.httpBody = try JSONSerialization.data(withJSONObject: body)

		let (data, response) = try await URLSession.shared.data(for: request)
		guard let http = response as? HTTPURLResponse else {
			throw APIError(message: "No response from the server. Please try again.")
		}

		let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
		guard (200..<300).contains(http.statusCode) else {
			throw APIError(message: (json["error"] as? String) ?? "Something went wrong. Please try again.")
		}
		return json
	}
}
