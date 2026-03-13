//
//  Router.swift
//  pace
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
    var root: RootFlow = .welcome

    // MARK: Push / Pop

    /// Push a destination onto the stack.
    /// - Parameters:
    ///   - destination: The screen to navigate to.
    ///   - fadeIn: If `true`, uses a fade animation instead of the default iOS slide. Default is `false`.
    func navigate(to destination: Destinations, fadeIn: Bool = false) {
        if fadeIn {
            withAnimation(.easeIn) {
                path.append(destination)
            }
        } else {
            path.append(destination)
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
        withAnimation(.default) {
            root = newRoot
            path = NavigationPath()
        }
    }
}
