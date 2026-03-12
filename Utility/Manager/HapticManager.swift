//
//  HapticManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

import SwiftUI
import UIKit

/// A shared manager for triggering common haptic patterns across the app.
/// Designed for SwiftUI and modern iOS versions (iOS 15+ through iOS 26).
public final class HapticManager: @unchecked Sendable {
	// MARK: - Singleton
	public static let shared = HapticManager()
	
	// Generators are UI components; they must be used on the main thread.
	private let notificationGenerator = UINotificationFeedbackGenerator()
	private let selectionGenerator = UISelectionFeedbackGenerator()
	
	// Impact generators by style. Lazily created to avoid unnecessary cost.
	private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
	
	private init() {
		// Prepares common generators up front for snappier first use.
		// Must be called on the main thread.
		if Thread.isMainThread {
			notificationGenerator.prepare()
			selectionGenerator.prepare()
		} else {
			DispatchQueue.main.async { [weak self] in
				self?.notificationGenerator.prepare()
				self?.selectionGenerator.prepare()
			}
		}
	}
	
	// MARK: - Public API
	
	/// Triggers a notification haptic (success, warning, error).
	@MainActor
	public func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
		notificationGenerator.notificationOccurred(type)
		notificationGenerator.prepare()
	}
	
	/// Triggers an impact haptic with the given style and optional intensity (0.0–1.0).
	/// If `intensity` is nil, uses the default intensity for that style.
	@MainActor
	public func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, intensity: CGFloat? = nil) {
		let generator = generator(for: style)
		if let intensity {
			generator.impactOccurred(intensity: max(0, min(1, intensity)))
		} else {
			generator.impactOccurred()
		}
		generator.prepare()
	}
	
	/// Triggers a subtle selection changed haptic.
	@MainActor
	public func selectionChanged() {
		selectionGenerator.selectionChanged()
		selectionGenerator.prepare()
	}
	
	/// Convenient shortcuts
	@MainActor public func success() { notify(.success) }
	@MainActor public func warning() { notify(.warning) }
	@MainActor public func error() { notify(.error) }
	
	@MainActor public func light(intensity: CGFloat? = nil) { impact(style: .light, intensity: intensity) }
	@MainActor public func medium(intensity: CGFloat? = nil) { impact(style: .medium, intensity: intensity) }
	@MainActor public func heavy(intensity: CGFloat? = nil) { impact(style: .heavy, intensity: intensity) }
	@MainActor public func soft(intensity: CGFloat? = nil) { impact(style: .soft, intensity: intensity) }
	@MainActor public func rigid(intensity: CGFloat? = nil) { impact(style: .rigid, intensity: intensity) }
	
	// MARK: - Private
	
	@MainActor
	private func generator(for style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
		if let existing = impactGenerators[style] {
			return existing
		}
		let newGen = UIImpactFeedbackGenerator(style: style)
		newGen.prepare()
		impactGenerators[style] = newGen
		return newGen
	}
}

// MARK: - SwiftUI Integration

private struct HapticManagerKey: EnvironmentKey {
	static let defaultValue: HapticManager = .shared
}

public extension EnvironmentValues {
	var haptics: HapticManager {
		get { self[HapticManagerKey.self] }
		set { self[HapticManagerKey.self] = newValue }
	}
}

public extension View {
	/// Inject a custom haptic manager into the environment, if needed.
	func haptics(_ manager: HapticManager) -> some View {
		environment(\.haptics, manager)
	}
	
	/// A convenience modifier to trigger a haptic on tap for simple cases.
	func onTapHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
					 intensity: CGFloat? = nil,
					 perform action: @escaping () -> Void) -> some View {
		modifier(HapticTapModifier(style: style, intensity: intensity, action: action))
	}
}

private struct HapticTapModifier: ViewModifier {
	@Environment(\.haptics) private var haptics
	let style: UIImpactFeedbackGenerator.FeedbackStyle
	let intensity: CGFloat?
	let action: () -> Void
	
	func body(content: Content) -> some View {
		content.onTapGesture {
			Task { @MainActor in
				haptics.impact(style: style, intensity: intensity)
				action()
			}
		}
	}
}

// MARK: - Previews

#Preview("HapticManager Demo") {
	VStack(spacing: 16) {
		Button("Success") {
			Task { @MainActor in
				HapticManager.shared.success()
			}
		}
		Button("Warning") {
			Task { @MainActor in
				HapticManager.shared.warning()
			}
		}
		Button("Error") {
			Task { @MainActor in
				HapticManager.shared.error()
			}
		}
		Button("Light Impact") {
			Task { @MainActor in
				HapticManager.shared.light()
			}
		}
		Button("Medium Impact 0.7") {
			Task { @MainActor in
				HapticManager.shared.medium(intensity: 0.7)
			}
		}
		Button("Selection Changed") {
			Task { @MainActor in
				HapticManager.shared.selectionChanged()
			}
		}
	}
	.buttonStyle(.borderedProminent)
	.padding()
}

/*
 • From SwiftUI environment:
	 @Environment(\.haptics) private var haptics
	 
	 Button("Go") {
	 Task { @MainActor in
	 haptics.success()
	 }
	 }
 
 • With the convenience modifier:
	 Text("Press Me")
	 .onTapHaptic(.soft) {
	 // your action
	 }
 */
