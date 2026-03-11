//
//  GilroyFontModifier.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//
import SwiftUI

// MARK: - Default Font Modifier
// Apply once at root — all Text() inherits Gilroy-Regular
struct GilroyFontModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.font(Gilroy.regular.size(17))
	}
}

extension View {
	func gilroyDefault() -> some View {
		modifier(GilroyFontModifier())
	}
}
