//
//  FashionCardBackground.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/6/26.
//

import SwiftUI

/// A reusable card-style background modifier that applies a rounded, filled background
/// with an optional stroke to any SwiftUI view.
struct AppCardBackground: ViewModifier {
	/// The corner radius applied to the rounded rectangle background and stroke.
	let cornerRadius: CGFloat
	/// The color used for the border stroke drawn on top of the background.
	let strokeColor: Color
	/// The width of the border stroke. Set to 0 to hide the stroke.
	let lineWidth: CGFloat
	/// The fill color of the card background.
	let backgroundColor: Color
	
	/// Composes the view with a rounded rectangle fill as the background and an
	/// overlay stroke for the border, using the provided styling values.
	func body(content: Content) -> some View {
		content
			.background( // Card fill
				RoundedRectangle(cornerRadius: cornerRadius)
					.fill(backgroundColor)
			)
			.overlay( // Card border
				RoundedRectangle(cornerRadius: cornerRadius)
					.stroke(strokeColor, lineWidth: lineWidth)
			)
	}
}

extension View {
	/// Applies a rounded card-style background and optional border to the view.
	/// - Parameters:
	///   - radius: Corner radius for the card. Default is 8.
	///   - stroke: Border color. Default is `.fashionGray`.
	///   - lineWidth: Border width. Default is 1.2.
	///   - bg: Background fill color. Default is `.whiteApp`.
	/// - Returns: A view with the card background styling applied.
	func cardBackground(
		radius: CGFloat = 12,
		stroke: Color = .fashionGray,
		lineWidth: CGFloat = 1.2,
		bg: Color = .whiteApp
	) -> some View {
		self.modifier(
			AppCardBackground(
				cornerRadius: radius,
				strokeColor: stroke,
				lineWidth: lineWidth,
				backgroundColor: bg
			)
		)
	}
}
