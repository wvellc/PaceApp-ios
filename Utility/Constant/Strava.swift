//
//  Strava.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/9/26.
//

// MARK: Strava Level
//
// OAuth is done on-device (authorize only). The client secret, token exchange,
// refresh, and activity upload all live in Firebase Cloud Functions — the app
// never holds a Strava token. Fill these from https://www.strava.com/settings/api.
struct StravaConst {
	static let clientId       = "269660"				// Strava app "Client ID"
	static let callbackScheme = "paceapp"                   // ASWebAuthenticationSession scheme
	static let callbackHost   = "strava-callback"           // final relayed deep link: paceapp://strava-callback
	static let scope          = "activity:write,read"       // write = uploads, read = read back

	// Strava requires a real callback DOMAIN, so it redirects to this hosted page,
	// which relays to the existing paceapp://strava-callback deep link (firebase-hosting/.../stravaCallback).
	// Trailing slash serves the page directly (no hosting 301); host must match the Strava callback domain.
	static let redirectURI    = "https://thepaceapp.web.app/stravaCallback/"

	// strava:// opens the installed Strava app; https:// is the web fallback.
	static let appAuthorizeURL = "strava://oauth/mobile/authorize"
	static let webAuthorizeURL = "https://www.strava.com/oauth/mobile/authorize"

	// Firebase HTTPS Cloud Functions base — set after `firebase deploy --only functions`.
	static let functionsBaseURL = "https://us-central1-thepaceapp.cloudfunctions.net"
}
