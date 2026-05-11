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
	var root: RootFlow = .dashboard
	
	/// Debounce flag — blocks duplicate calls within the 500 ms window.
	/// `@ObservationIgnored` keeps this out of SwiftUI's observation graph
	/// so no view re-renders when it toggles.
	@ObservationIgnored
	private var isNavigating = false
	
	// MARK: Push / Pop
	
	/// Push a destination onto the stack.
	///
	/// Automatically guards against double-tap / rapid taps (500 ms debounce).
	///
	/// - Parameters:
	///   - destination: The screen to navigate to.
	///   - animation: Optional animation override; `nil` uses the default iOS slide.
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
		
		Task {
			try? await Task.sleep(for: .milliseconds(500))
			isNavigating = false
		}
	}
	
	/// Pop one screen.
	func navigateBack() {
		guard !path.isEmpty else { return }
		path.removeLast()
	}
	
	/// Pop `count` screens.
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
