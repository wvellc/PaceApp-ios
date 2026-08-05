//
//  PairWatchView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/1/26.
//

import SwiftUI
import ConnectIQ

struct PairWatchView: View {
    
	@State private var animateContent = false
	@State private var animateBadge = false
	@State private var animateHalo = false
	
	let onGetStarted: VoidOptionalCallback
    
	init(
		onGetStarted: @escaping VoidOptionalCallback
	) {
		self.onGetStarted = onGetStarted
	}

	var body: some View {
		VStack(spacing: 0) {
			Spacer(minLength: 56)
			
			homeArtwork

			VSpace(height: 32)

			VStack(spacing: 12) {
				Text(.pairYourFirstGarminWatch)
					.font(.semiBold24)
					.foregroundStyle(.whiteApp)
					.multilineTextAlignment(.center)
					.lineSpacing(6)
					.kerning(0.53624)
					.fadeInUp(isAnimated: $animateContent, delay: 0.18, duration: 0.7, from: 30)
				
				Text(.putYourWatchInPairingModeMessage)
					.font(.medium16)
					.foregroundStyle(.whiteApp.opacity(0.9))
					.multilineTextAlignment(.center)
					.lineSpacing(4)
					.fadeInUp(isAnimated: $animateContent, delay: 0.28, duration: 0.7, from: 26)
			}
			.padding(.horizontal, 8)
			
			VSpace(height: 70)
			
			AppButton(.startPairingProcess, font: .medium20, verticalPadding: 20) {
                onGetStarted()
			}
			.fadeInUp(isAnimated: $animateContent, delay: 0.42, duration: 0.8, from: 32)
			.buttonStyle(.plain)
			
			VSpace(height: 32)
		}
		.onAppear {
			animateContent = true
			animateBadge = true
			animateHalo = true
		}

	}
	
	private var homeArtwork: some View {
		ZStack {
			Circle()
				.fill(.white.opacity(0.14))
				.frame(width: 180, height: 180)
				.scaleEffect(animateHalo ? 1.02 : 0.82)
				.animation(
					.interactiveSpring(duration: 0.9, extraBounce: 0.16),
					value: animateHalo
				)
			
			Circle()
				.fill(.white)
				.frame(width: 140, height: 140)
				.shadow(color: .black.opacity(0.08), radius: 28, y: 12)
				.scaleEffect(animateBadge ? 1 : 0.72)
				.overlay {
					Image(.icWatchBlue)
						.resizable()
						.frame(width: 66.25, height: 112.30)
				}
				.InteractiveSpringScaleIn(isAnimated: $animateBadge, delay: 0.05, duration: 0.9, fromScale: 0.72)
			
			
			successBadge
				.offset(x: 27, y: 13)
		}
	}
	
	private var successBadge: some View {
		Image(.icPlusGreen)
			.resizable()
			.frame(width: 28, height: 28)
			.scaleEffect(animateContent ? 1 : 0.35)
			.animation(
				.interactiveSpring(duration: 0.65, extraBounce: 0.32)
				.delay(0.4),
				value: animateContent
			)
	}
}
