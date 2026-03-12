//
//  GlassButton.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//


import SwiftUI

/// A reusable glass-effect capsule button with a thin neon stroke and trailing chevron.
public struct GlassButton: View {
    public let title: String
    public let action: () -> Void

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
				Rectangle()
					.frame(width: 32, height: 32)
				Spacer(minLength: 8)
                Text(title)
					.font(.paceMedium16)
				Spacer(minLength: 8)

                Image("icGetStartArrow")
					.frame(width: 32, height: 32)
            }
            .foregroundStyle(Color.whiteApp)
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
        }
        // Apply Apple's Liquid Glass styling per documentation
        .buttonStyle(.glass)
        .glassEffect(.regular.interactive(), in: .capsule)
        .overlay(
            Capsule()
                .stroke(Color.neonAquaBlue, lineWidth: 1)
        )
        .shadow(color: Color.neonAquaBlue.opacity(0.25), radius: 8, x: 0, y: 2)
        .accessibilityLabel(Text(title))
    }
}
