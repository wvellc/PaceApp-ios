//
//  FadeInDownModifier.swift
//  recoverytrak
//
//  Created by FURKAN VIJAPURA on 08/01/25.
//

import SwiftUI

/// Fade In Down -  Animation
struct FadeInDownModifier: ViewModifier {
	
	//MARK: Property wrapper
	@Binding var isAnimated: Bool
	let delay: Double
	let duration: TimeInterval
	let from: Double
	
	
	//MARK: View Modifier
	func body(content: Content) -> some View {
		content
			.opacity(isAnimated ? 1 : 0)  // Fades in
			.offset(
				y: isAnimated ? 0 : -(from + (delay * 10))
			) // Moves up from 50px below
			.animation(
				.interactiveSpring(duration: duration, extraBounce: 0.3, blendDuration: 0.2)
				.delay(delay), // Smooth easing and delay
				value: isAnimated
			)
	}
}

