//
//  PairWatchStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/17/26.
//

//
//  PairWatchStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI

// MARK: - PairWatchStepView

/// Step 2 — Entry point for watch pairing.
/// Shows a watch icon with a sync badge and prompts the user to start pairing.
struct PairWatchStepView: View {
	
	// MARK: - Animation State
	
	@State private var isFloating = false
	@State private var syncRotation: Double = 0
	@State private var outerRingScale: CGFloat = 0.92
	@State private var outerRingOpacity: Double = 0.6
	
	// MARK: - Body
	
	var body: some View {
		VStack(spacing: 0) {
			Spacer()
			
			// Watch icon with sync badge
			ZStack {
				// Outer pulsing ring
				Circle()
					.fill(.white20)
					.frame(width: 180, height: 180)
					.scaleEffect(outerRingScale)
					.opacity(outerRingOpacity)
				
				// Inner white circle
				Circle()
					.fill(.whiteApp)
					.frame(width: 140, height: 140)
				
				// Watch image — floats up/down
				Image(.icWatchBlue)
					.resizable()
					.scaledToFit()
					.frame(width: 66.25, height: 112.30)
				
				// Sync badge — rotates continuously
				Image(.icPairSync)
					.resizable()
					.frame(width: 28, height: 28)
//					.rotationEffect(.degrees(syncRotation))
					.offset(x: 28, y: 14)
			}
			.InteractiveSpringScaleIn(isAnimated: $isFloating, fromScale: 0.7)
			.onAppear {
				startAnimations()
			}
			
			VSpace(height: 32)
			
			// Title
			Text("Pair a new Garmin watch")
				.font(.semiBold24)
				.tracking(0.54)
				.foregroundStyle(.whiteApp)
				.multilineTextAlignment(.center)
			
			VSpace(height: 8)
			
			// Subtitle
			Text("Connect your watch to this phone to sync runs,\npace goals.")
				.font(.medium16)
				.foregroundStyle(.grayHint)
				.multilineTextAlignment(.center)
			
			Spacer()
		}
		.frame(maxWidth: .infinity)
		.padding(.horizontal, 24)
		.clipped()
	}
	
	// MARK: - Animations
	
	private func startAnimations() {
		
		// 1. Gentle float
		withAnimation(
			.easeInOut(duration: 2.2)
		) {
			isFloating = true
		}
		
//		// 1. Sync icon — slow continuous clockwise spin
//		withAnimation(
//			.linear(duration: 2.4)
//			.repeatForever(autoreverses: false)
//		) {
//			syncRotation = 360
//		}
		
		// 2. Outer ring — gentle breathe pulse
		withAnimation(
			.easeInOut(duration: 1.8)
			.repeatForever(autoreverses: true)
		) {
			outerRingScale = 1.08
			outerRingOpacity = 1.0
		}
	}
}

#Preview {
	PairWatchStepView()
		.appBackground()
}
