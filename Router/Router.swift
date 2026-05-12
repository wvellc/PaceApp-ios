//
//  Router.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.

import SwiftUI
import Observation

// MARK: - Router

/// **Usage — any child view:**
/// ```swift
/// @Environment(Router.self) private var router
///
/// Button("Open Settings") { router.navigate(to: .settings) }
/// ```
@Observable
@MainActor
final class Router {
    // MARK: State

    /// The live navigation path — bind directly to `NavigationStack`.
    var path = NavigationPath()

    /// The app's current root flow.
	var root: RootFlow = .accountCreation

    // MARK: Private

    /// Prevents duplicate pushes from rapid / double taps.
	@ObservationIgnored
    private var isNavigating = false

    // MARK: Push / Pop

    /// Push a destination onto the stack.
    /// Duplicate calls within the same run-loop tick are silently dropped,
    /// so rapid double-taps can never push the same screen twice.
	func navigate(to destination: Destinations, animation: Animation? = nil) {
        guard !isNavigating else { return }
        isNavigating = true

        if let animation {
            withAnimation(animation) {
                path.append(destination)
            }
        } else {
            path.append(destination)
        }

        // Re-arm after the transition animation completes (~0.4 s is safe for
        // the default iOS push; use a short delay so back-to-back *different*
        // destinations still work when intentional).
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            isNavigating = false
        }
    }

    /// Pop one screen.
    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Pop screens until `target` is the top of the stack.
    ///
    /// - Note: Because `NavigationPath` is type-erased, this works by
    ///   counting encoded elements; prefer ``navigateToRoot()`` when a
    ///   full reset is acceptable.
    func navigateBack(count: Int) {
        let steps = min(count, path.count)
        guard steps > 0 else { return }
        path.removeLast(steps)
    }

    /// Pop all screens and return to the stack's root view.
    func navigateToRoot() {
        guard !path.isEmpty else { return }
        path.removeLast(path.count)
    }

    // MARK: Root switching

    /// Replace the current root flow (auth → dashboard, etc.)
    /// and clear the navigation stack in one atomic update.
    func setRoot(_ newRoot: RootFlow) {
		root = newRoot
		path = NavigationPath()
        isNavigating = false
    }
}
