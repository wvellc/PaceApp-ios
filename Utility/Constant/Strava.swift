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
	static let clientId       = ""                          // Strava app "Client ID"
	static let callbackScheme = "paceapp"                   // ASWebAuthenticationSession scheme
	static let callbackHost   = "strava-callback"           // paceapp://strava-callback
	static let redirectURI    = "paceapp://strava-callback" // must match Strava "Authorization Callback Domain"
	static let scope          = "activity:write,read"       // write = uploads, read = read back

	// strava:// opens the installed Strava app; https:// is the web fallback.
	static let appAuthorizeURL = "strava://oauth/mobile/authorize"
	static let webAuthorizeURL = "https://www.strava.com/oauth/mobile/authorize"

	// Firebase HTTPS Cloud Functions base — set after `firebase deploy --only functions`.
	static let functionsBaseURL = "https://us-central1-thepaceapp.cloudfunctions.net"
}
