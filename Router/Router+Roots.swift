//
//  Router+Roots.swift
//  pace
//  Created by FURKAN VIJAPURA on 3/12/26.
//  Defines the high-level entry points (root flows) of the app.
//

extension Router {

    /// Top-level navigation roots.
    ///
    /// Switch between them via `router.setRoot(_:)`.
    enum RootFlow {
        /// Startup splash shown before resolving the session-based root.
        case splash
        /// First-launch / unauthenticated onboarding sequence.
        case welcome
        /// Standard auth screens (login / sign-up).
        case auth
        /// Email link verification loading screen.
        case authenticating
		/// Account setup (Connect watch, strava and user info).
        case accountCreation
		
        /// Authenticated main dashboard experience.
        case dashboard
    }
}
