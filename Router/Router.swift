//
//  Router.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.

import SwiftUI
import Observation
import UIKit

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
    // MARK: - Singleton

    static let shared = Router()

    // MARK: State

    /// The live navigation path — bind directly to `NavigationStack`.
    var path = NavigationPath()

    /// The app's current root flow.
	var root: RootFlow = .splash

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

    /// Replace the current root flow (auth → dashboard, etc.) and clear the
    /// navigation stack in one atomic update.
    ///
    /// A native CATransition is applied to the key window layer **before**
    /// the SwiftUI state mutation so the new root slides in from the trailing
    /// edge (right → left), exactly like a UINavigationController push.
    ///
    /// - Parameters:
    ///   - newRoot: The destination root flow.
    ///   - forward: When `true` (default) the new root slides in from the
    ///              **trailing** edge (right → left push feel).
    ///              Pass `false` for a leading-edge (left → right pop feel).
    func setRoot(_ newRoot: RootFlow, forward: Bool = true) {
        // 1. Attach a CATransition to the key window BEFORE mutating state.
        //    UIKit renders a snapshot of the current content, then slides the
        //    new SwiftUI tree in — fully clipped, no bleed-through.
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: \.isKeyWindow) {

            let transition = CATransition()
            transition.duration = 0.35
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transition.type = .push
            transition.subtype = forward ? .fromRight : .fromLeft
            window.layer.add(transition, forKey: kCATransition)
        }

        // 2. Mutate state — SwiftUI re-renders the new root and UIKit's
        //    transition animation carries it in smoothly.
        root = newRoot
        path = NavigationPath()
        isNavigating = false
    }

    // MARK: - Root Navigation Setup

    /// Returns the root flow for the current persisted session state without
    /// mutating navigation. Use this after splash/launch UI has rendered.
    static func staticRoot() -> RootFlow {
        guard let currentUserID = AuthManager.shared.currentUserID,
              let user = AuthManager.shared.userDetails,
              user.uuid == currentUserID else {
            return .auth
        }

        return user.isProfileCompleted ? .dashboard : .accountCreation
    }

    /// Determines the correct root flow based on the current session state and
    /// transitions to it. Mirrors the Dart `setupRootNavigation()` logic.
    ///
    /// Decision tree:
    /// 1. Not authenticated → `.auth` (login)
    /// 2. Authenticated but profile incomplete (first/last name nil or empty) → `.accountCreation`
    /// 3. Authenticated + profile complete → `.dashboard`
    func setupRootNavigation() {
        let resolvedRoot = Self.staticRoot()

        if resolvedRoot == .auth {
            AppSession.removeAllData()
        }

        setRoot(resolvedRoot, forward: true)
    }
}
