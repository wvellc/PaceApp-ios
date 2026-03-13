//
//  AppButton.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import SwiftUI

// MARK: - Button Style

/// Predefined visual styles for `AppButton`.
enum AppButtonStyle {
	/// Gradient background with white text (default primary action style).
	case primary
	/// Light solid background with accent-colored text (secondary action style).
	case secondary
	
	// MARK: - Defaults per style
	
	var font: Font {
		switch self {
			case .primary:   return .medium16
			case .secondary: return .medium16
		}
	}
	
	var foregroundColor: Color {
		switch self {
			case .primary:   return .whiteApp
			case .secondary: return .redBoho
		}
	}
	
	var verticalPadding: CGFloat {
		switch self {
			case .primary:   return 16
			case .secondary: return 16
		}
	}
	
	var horizontalPadding: CGFloat {
		switch self {
			case .primary:   return 0
			case .secondary: return 0
		}
	}
}

// MARK: - AppButton
struct AppButton: View {
	
	// MARK: - Properties
	
	private let title: LocalizedStringResource
	private let style: AppButtonStyle
	private let font: Font
	private let foregroundColor: Color
	private let maxWidth: CGFloat?
	private let verticalPadding: CGFloat
	private let horizontalPadding: CGFloat
	private let action: () -> Void
	
	// MARK: - Init
	
	/// Creates an `AppButton`.
	///
	/// - Parameters:
	///   - title: The button label text.
	///   - style: Visual preset. Default `.primary`.
	///   - font: Overrides the style's default font.
	///   - foregroundColor: Overrides the style's default text color.
	///   - maxWidth: Maximum width. Default `.infinity` (full-width).
	///   - verticalPadding: Overrides the style's default vertical padding.
	///   - horizontalPadding: Overrides the style's default horizontal padding.
	///   - action: Closure invoked on tap.
	init(
		_ title: LocalizedStringResource,
		style: AppButtonStyle = .primary,
		font: Font? = nil,
		foregroundColor: Color? = nil,
		maxWidth: CGFloat? = .infinity,
		verticalPadding: CGFloat? = nil,
		horizontalPadding: CGFloat? = nil,
		action: @escaping () -> Void
	) {
		self.title = title
		self.style = style
		self.font = font ?? style.font
		self.foregroundColor = foregroundColor ?? style.foregroundColor
		self.maxWidth = maxWidth
		self.verticalPadding = verticalPadding ?? style.verticalPadding
		self.horizontalPadding = horizontalPadding ?? style.horizontalPadding
		self.action = action
	}
	
	// MARK: - Body
	
	var body: some View {
		Button(action: action) {
			Text(title)
				.font(font)
				.foregroundColor(foregroundColor)
				.frame(maxWidth: maxWidth)
				.padding(.vertical, verticalPadding)
				.padding(.horizontal, horizontalPadding)
				.background(backgroundView)
				.clipShape(Capsule())
		}
	}
	
	// MARK: - Background
	
	@ViewBuilder
	private var backgroundView: some View {
		switch style {
			case .primary:
				AppGradients.button
			case .secondary:
				Color.grayHint
		}
	}
}

// MARK: - Preview

#Preview {
	ZStack {
		Color.darkSeaBlue
		
		VStack(spacing: 20) {
			AppButton("Next") { }
			
			AppButton("Skip", style: .secondary) { }
			
			AppButton("Custom", style: .primary, font: .semiBold16, verticalPadding: 12) { }
		}
		.padding(.horizontal, 16)
	}
}
