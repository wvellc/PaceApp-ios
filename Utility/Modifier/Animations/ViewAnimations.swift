//
//  ViewAnimations.swift
//  recoverytrak
//
//  Created by FURKAN VIJAPURA on 02/01/25.
//

import SwiftUI

//MARK: View Extensions - Modefier
extension View {
	
	/// Applies a fade-in-up animation to a view.
	/// - Parameters:
	///   - isAnimated: A binding to control the start and stop of the animation.
	///   - delay: The time (in seconds) to wait before starting the animation. Default is 0.3.
	///   - duration: The total time (in seconds) for the animation to complete. Default is 0.5.
	///   - from: The vertical offset (in points) from which the animation begins. Default is 50.
	/// - Returns: A view with the applied fade-in-up animation modifier.
	func fadeInUp(isAnimated: Binding<Bool>, delay: Double = 0.3, duration: TimeInterval = 0.5, from: Double = 50) -> some View {
		self.modifier(FadeInUpModifier(isAnimated: isAnimated, delay: delay, from: from, duration: duration))
	}
	
	
	/// Applies a fade-in-down animation to a view.
	/// - Parameters:
	///   - isAnimated: A binding to control the start and stop of the animation.
	///   - delay: The time (in seconds) to wait before starting the animation. Default is 0.3.
	///   - duration: The total time (in seconds) for the animation to complete. Default is 0.2.
	///   - from: The vertical offset (in points) from which the animation begins. Default is 50.
	/// - Returns: A view with the applied fade-in-down animation modifier.
	func fadeInDown(isAnimated: Binding<Bool>, delay: Double = 0.3, duration: TimeInterval = 0.2, from: Double = 50) -> some View {
		self.modifier(
			FadeInDownModifier(isAnimated: isAnimated, delay: delay, duration: duration, from: from)
		)
	}
	
	/// Applies an interactive spring scale-in animation to a view.
	/// - Parameters:
	///   - isAnimated: A binding to control the start and stop of the animation.
	///   - delay: The time (in seconds) to wait before starting the animation. Default is 0.3.
	///   - duration: The total time (in seconds) for the animation to complete. Default is 0.5.
	///   - fromScale: The initial scale value to start the animation from. Default is 0 (scaled from nothing).
	/// - Returns: A view with the applied interactive spring scale-in animation modifier.
	func InteractiveSpringScaleIn(isAnimated: Binding<Bool>, delay: Double = 0.3, duration: TimeInterval = 0.5, fromScale: Double = 0) -> some View {
		self.modifier(
			InteractiveSpringScaleInModifier(
				isAnimated: isAnimated,
				delay: delay,
				duration: duration,
				fromScale: fromScale
			)
		)
	}

}
