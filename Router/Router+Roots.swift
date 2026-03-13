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
        /// First-launch / unauthenticated onboarding sequence.
        case welcome
        /// Standard auth screens (login / sign-up).
        case auth
        /// Authenticated main dashboard experience.
        case dashboard
    }
}
