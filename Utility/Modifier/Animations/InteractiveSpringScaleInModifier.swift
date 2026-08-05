//
//  InteractiveSpringScaleInModifier.swift
//  recoverytrak
//
//  Created by FURKAN VIJAPURA on 08/01/25.
//

import SwiftUI

/// Fade In Down -  Animation
struct InteractiveSpringScaleInModifier: ViewModifier {
	
	//MARK: Property wrapper
	@Binding var isAnimated: Bool
	let delay: Double
	let duration: TimeInterval
	let fromScale: Double

	//MARK: View Modifier
	func body(content: Content) -> some View {
		content
			.opacity(isAnimated ? 1 : 0)  // Fades in
			.scaleEffect(
				isAnimated ? 1 : fromScale,
				anchor: .center
			) // scale from 0 to 1
			.animation(
				.interactiveSpring(duration: duration, extraBounce: 0.3, blendDuration: 0.2)
				.delay(delay), // Smooth easing and delay
				value: isAnimated
			)
	}
}
