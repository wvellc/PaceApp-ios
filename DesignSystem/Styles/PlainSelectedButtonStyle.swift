//
//  PlainSelectedStyle.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/8/26.
//

import SwiftUI

struct PlainSelectedStyle: ButtonStyle {
	let activeColor: Color
	let pressedColor: Color
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
		// Change the color based on configuration.isPressed
			.foregroundStyle(configuration.isPressed ? pressedColor : activeColor)
		// Optional: Add a slight scale effect for better UX
			.scaleEffect(configuration.isPressed ? 0.98 : 1.0)
			.animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
	}
}

// Helper for cleaner syntax
extension ButtonStyle where Self == PlainSelectedStyle {
	static func plainSelected(active: Color = .clear, pressed: Color = .radiantBlue) -> PlainSelectedStyle {
		PlainSelectedStyle(activeColor: active, pressedColor: pressed)
	}
}
