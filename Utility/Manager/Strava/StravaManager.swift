//
//  StravaManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/9/26.
//

import UIKit
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import Logging

// MARK: - StravaManager
//
// Owns the on-device half of the Strava integration: the OAuth authorize step and
// the connection state. Token exchange, refresh and uploads all happen server-side
// (Cloud Functions) — this manager only starts OAuth, hands the returned code to a
// function, and mirrors the connection summary the function writes to Firestore.

@Observable
final class StravaManager: NSObject {

	// MARK: - Singleton
	static let shared = StravaManager()

	// MARK: - Published state
	private(set) var isConnected = false
	private(set) var athleteName: String?
	/// True while an OAuth exchange / disconnect / sync call is in flight.
	var isWorking = false

	// MARK: - Private
	@ObservationIgnored private var authSession: ASWebAuthenticationSession?
	@ObservationIgnored private var listener: ListenerRegistration?
	@ObservationIgnored private let db = Firestore.firestore()
	@ObservationIgnored private let log = Logger(label: "strava.manager")

	private override init() { super.init() }

	// MARK: - Connection state (Firestore)

	/// Starts mirroring `users/{uid}.strava` → `isConnected` / `athleteName`.
	/// The Cloud Functions write this summary; the app only reads it.
	func startObserving() {
		guard listener == nil, let uid = AuthManager.shared.currentUserID else { return }
		listener = db.collection("users").document(uid)
			.addSnapshotListener { [weak self] snapshot, _ in
				guard let self else { return }
				let strava = snapshot?.data()?["strava"] as? [String: Any]
				self.isConnected = (strava?["connected"] as? Bool) ?? false
				self.athleteName = strava?["athleteName"] as? String
			}
	}

	/// Tears down the listener (e.g. on logout).
	func stopObserving() {
		listener?.remove()
		listener = nil
		isConnected = false
		athleteName = nil
	}

	// MARK: - Connect (OAuth authorize)

	/// Prefers the installed Strava app for a native handoff; falls back to a web sheet.
	func connect() {
		if isStravaAppInstalled, let url = authorizeURL(base: StravaConst.appAuthorizeURL) {
			// Callback returns via the app's URL scheme → handleOpenURL(_:).
			UIApplication.shared.open(url)
		} else if let url = authorizeURL(base: StravaConst.webAuthorizeURL) {
			startWebAuth(url)
		}
	}

	/// Native-app callback path. Routed here from `PaceApp.onOpenURL`; self-guards on scheme+host.
	func handleOpenURL(_ url: URL) {
		guard url.scheme == StravaConst.callbackScheme, url.host == StravaConst.callbackHost else { return }
		handleCallback(url)
	}

	// MARK: - Disconnect

	@MainActor
	func disconnect() async {
		isWorking = true
		defer { isWorking = false }
		do {
			try await StravaAPI.post("/stravaDisconnect")
			isConnected = false
			athleteName = nil
			ToastManager.shared.present(.success("Disconnected from Strava."))
		} catch {
			ToastManager.shared.present(.error(error.localizedDescription))
		}
	}

	// MARK: - Sync recent (backfill)

	/// Pushes recent completed activities that haven't reached Strava yet.
	@MainActor
	func syncRecent() async {
		isWorking = true
		defer { isWorking = false }
		do {
			let result = try await StravaAPI.post("/stravaBackfill")
			let count = result["synced"] as? Int ?? 0
			let message = count > 0
				? "Synced \(count) activit\(count == 1 ? "y" : "ies") to Strava."
				: "You're all caught up."
			ToastManager.shared.present(.success(message))
		} catch {
			ToastManager.shared.present(.error(error.localizedDescription))
		}
	}

	// MARK: - Private — OAuth

	private var isStravaAppInstalled: Bool {
		guard let url = URL(string: "strava://") else { return false }
		return UIApplication.shared.canOpenURL(url)
	}

	private func authorizeURL(base: String) -> URL? {
		var components = URLComponents(string: base)
		components?.queryItems = [
			URLQueryItem(name: "client_id",       value: StravaConst.clientId),
			URLQueryItem(name: "redirect_uri",     value: StravaConst.redirectURI),
			URLQueryItem(name: "response_type",    value: "code"),
			URLQueryItem(name: "approval_prompt",  value: "auto"),
			URLQueryItem(name: "scope",            value: StravaConst.scope)
		]
		return components?.url
	}

	private func startWebAuth(_ url: URL) {
		let session = ASWebAuthenticationSession(
			url: url,
			callbackURLScheme: StravaConst.callbackScheme
		) { [weak self] callbackURL, error in
			guard let self else { return }
			if let callbackURL {
				self.handleCallback(callbackURL)
			} else if let error {
				self.reportAuthError(error)
			}
			self.authSession = nil
		}
		session.presentationContextProvider = self
		session.prefersEphemeralWebBrowserSession = false
		authSession = session
		session.start()
	}

	/// Shared callback parser for both the native-app and web-sheet paths.
	private func handleCallback(_ url: URL) {
		let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

		if let denied = items?.first(where: { $0.name == "error" })?.value {
			reportError(denied == "access_denied" ? "Strava connection was cancelled." : "Couldn't connect to Strava.")
			return
		}
		guard let code = items?.first(where: { $0.name == "code" })?.value else {
			reportError("Couldn't connect to Strava. Please try again.")
			return
		}
		// activity:write is required for uploads — warn (don't block) if it wasn't granted.
		let granted = items?.first(where: { $0.name == "scope" })?.value ?? ""
		if !granted.contains("activity:write") {
			reportError("Please allow activity upload access so we can sync your runs.")
		}
		Task { await exchange(code: code) }
	}

	@MainActor
	private func exchange(code: String) async {
		isWorking = true
		defer { isWorking = false }
		do {
			let result = try await StravaAPI.post("/stravaExchange", body: ["code": code])
			// The Firestore listener flips isConnected; set the name optimistically for instant UI.
			if let name = result["athleteName"] as? String { athleteName = name }
			ToastManager.shared.present(.success("Connected to Strava."))
		} catch {
			ToastManager.shared.present(.error(error.localizedDescription))
		}
	}

	// MARK: - Private — Errors

	private func reportAuthError(_ error: Error) {
		// The user closing the sheet isn't an error worth surfacing.
		if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin { return }
		reportError("Couldn't connect to Strava. Please try again.")
	}

	private func reportError(_ message: String) {
		Task { @MainActor in ToastManager.shared.present(.error(message)) }
	}
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension StravaManager: ASWebAuthenticationPresentationContextProviding {
	func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap { $0.windows }
			.first { $0.isKeyWindow } ?? ASPresentationAnchor()
	}
}
