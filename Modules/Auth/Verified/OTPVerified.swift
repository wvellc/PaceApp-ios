//
//  OTPVerified.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI

struct OTPVerified: View {
	//MARK: - Enviroment
	@Environment(Router.self) private var router

	// MARK: - Animation State
	@State private var animateContent = false
	@State private var animateBadge = false
	@State private var animateHalo = false

	var body: some View {
		ZStack {
			Color.clear

			VStack(spacing: 0) {
				Spacer(minLength: 56)

				verificationArtwork
					.padding(.bottom, 48)

				VStack(spacing: 18) {
					Text(.yourPhoneNumberHasBeenVerified)
						.font(.semiBold24)
						.foregroundStyle(.whiteApp)
						.multilineTextAlignment(.center)
						.lineSpacing(6)
						.kerning(0.53624)
						.fadeInUp(isAnimated: $animateContent, delay: 0.18, duration: 0.7, from: 30)

					Text(.youWillSoonBeDirectedToTheMainPage)
						.font(.medium16)
						.foregroundStyle(.whiteApp.opacity(0.9))
						.multilineTextAlignment(.center)
						.lineSpacing(4)
						.fadeInUp(isAnimated: $animateContent, delay: 0.28, duration: 0.7, from: 26)
				}
				.padding(.horizontal, 32)

				Spacer()

				AppButton(.getStarted, font: .medium20, verticalPadding: 20) {
					navigateToDashboard()
				}
				.fadeInUp(isAnimated: $animateContent, delay: 0.42, duration: 0.8, from: 32)
				.padding(.horizontal, 16)
				.padding(.bottom, 18)
			}
		}
		.defaultScreenStyle()
		.appBackground()
		.navigationBarBackButtonHidden(true)
		.onAppear {
			animateContent = true
			animateBadge = true
			animateHalo = true
		}
	}

	// MARK: - Artwork
	private var verificationArtwork: some View {
		ZStack {
			// Soft halo behind the main verification card
			RoundedRectangle(cornerRadius: 34, style: .continuous)
				.fill(.white.opacity(0.15))
				.frame(width: 140, height: 140)
				.scaleEffect(animateHalo ? 1 : 0.88)
				.rotationEffect(.degrees(animateHalo ? 0 : -8))
				.animation(
					.interactiveSpring(duration: 0.9, extraBounce: 0.18),
					value: animateHalo
				)

			// Rotated card container for the phone illustration
			RoundedRectangle(cornerRadius: 34, style: .continuous)
				.fill(.white)
				.frame(width: 140, height: 140)
				.rotationEffect(.degrees(animateContent ? -45 : 135))
				.shadow(color: .black.opacity(0.08), radius: 28, y: 12)
				.scaleEffect(animateBadge ? 1 : 0.72)
				.InteractiveSpringScaleIn(isAnimated: $animateBadge, delay: 0.05, duration: 0.9, fromScale: 0.72)
				.overlay {
					phoneGlyph
						.rotationEffect(.degrees(-45))
				}

			// Success indicator badge layered on the artwork
			Image(.icRightTick)
				.resizable()
				.frame(width: 28, height: 28)
				.offset(x: -64, y: 56)
				.scaleEffect(animateContent ? 1 : 0.35)
				.animation(
					.interactiveSpring(duration: 0.65, extraBounce: 0.32)
					.delay(0.36),
					value: animateContent
				)
		}
//		.frame(height: 320)
	}

	// MARK: - Phone Glyph
	private var phoneGlyph: some View {
		Image(.icSmartPhone)
		.rotationEffect(.degrees(45))
	}

	// MARK: - Navigation
	private func navigateToDashboard() {
		router.setRoot(.dashboard)
	}
}

#Preview {
	OTPVerified()
		.environment(Router())
}
