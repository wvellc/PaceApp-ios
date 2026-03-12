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
	
	@State private var isPressed = false
	
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
				Rectangle()
					.foregroundStyle(.clear)
					.frame(width: 32, height: 32)
				
				Spacer(minLength: 8)
                Text(title)
					.font(.medium16)
				Spacer(minLength: 8)

				Image("icGetStartArrow")
					.resizable()
					.frame(width: 32, height: 32)
            }
            .foregroundStyle(Color.whiteApp)
            .padding(.vertical, 12)
            .padding(.horizontal, 17)
        }
		.contentShape(Capsule())
		
		// Liquid glass effect
		.glassEffect(.regular, in: Capsule())
		
		// Neon gradient border
		.overlay(
			Capsule()
				.stroke(AppGradients.gradientBorder, lineWidth: 1)
		)
		
		// Press animation (glass + border scale together)
		.scaleEffect(isPressed ? 0.97 : 1)
		
		.animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
		
		.simultaneousGesture(
			DragGesture(minimumDistance: 0)
				.onChanged { _ in
					if !isPressed { isPressed = true }
				}
				.onEnded { _ in
					isPressed = false
				}
		)
		
		.frame(width: .infinity)

    }
}

/*
struct ArrowFlow: View {
	
	@State private var progress: CGFloat = 0
	
	private let arrowSpacing: CGFloat = 10
	private let arrowCount = 25
	
	var body: some View {
		
		ZStack {
			
			ForEach(0..<arrowCount, id: \.self) { i in
				
				Image("icGetStartArrow")
					.resizable()
					.scaledToFit()
					.frame(width: 36, height: 36)
				
					.offset(x: progress + CGFloat(i) * arrowSpacing - 26)
				
					.opacity(opacity(for: i))
			}
		}
		.frame(width: 36, height: 36)
		.clipped()
		// Smooth opacity fade on edges
		.mask(
			LinearGradient(
				stops: [
					.init(color: .clear, location: 0),
					.init(color: .white, location: 0.25),
					.init(color: .white, location: 0.75),
					.init(color: .clear, location: 1)
				],
				startPoint: .leading,
				endPoint: .trailing
			)
		)
		.onAppear {
			
			withAnimation(
				.linear(duration: 1.2)
				.repeatForever(autoreverses: false)
			) {
				progress = arrowSpacing
			}
		}
	}
	
	func opacity(for index: Int) -> Double {
		
		let step = Double(index) / Double(arrowCount)
		
		return max(0.2, min(1, step + 0.3))
	}
}

*/

//MARK:- Preview
#Preview {
	
	ZStack {
		 
		Color.darkSeaBlue
		
		GlassButton(title: "Get starte") {
			
		}
		.frame(width: 340)
	}
	
	
}
