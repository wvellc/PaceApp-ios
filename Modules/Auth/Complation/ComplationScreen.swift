//
//  OTPVerified.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI


struct ComplationScreen: View {

    let screenType: ComplationScreenType

    // MARK: - Enviroment
    @Environment(Router.self) private var router

    // MARK: - Animation State
    @State private var animateContent = false
    @State private var animateBadge = false
    @State private var animateHalo = false

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 0) {
                Spacer(minLength: 56)

                verificationArtwork
                    .padding(.bottom, 48)

                VStack(spacing: 18) {
                    Text(screenType.screenTitle)
                        .font(.semiBold24)
                        .foregroundStyle(.whiteApp)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .kerning(0.53624)
                        .fadeInUp(isAnimated: $animateContent, delay: 0.18, duration: 0.7, from: 30)

                    Text(screenType.screenDescription)
                        .font(.medium16)
                        .foregroundStyle(.whiteApp.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fadeInUp(isAnimated: $animateContent, delay: 0.28, duration: 0.7, from: 26)
                }
                .padding(.horizontal, 32)

                Spacer()

                AppButton(.getStarted, font: .medium20, verticalPadding: 20) {
                    onGetStarted()
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
    @ViewBuilder
    private var verificationArtwork: some View {
        switch screenType {
        case .otpVerified:
            otpVerifiedArtwork
        case .accountCreation:
            accountCreatedArtwork
        }
    }

    private var otpVerifiedArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.white.opacity(0.15))
                .frame(width: 140, height: 140)
                .scaleEffect(animateHalo ? 1 : 0.88)
                .rotationEffect(.degrees(animateHalo ? 0 : -8))
                .animation(
                    .interactiveSpring(duration: 0.9, extraBounce: 0.18),
                    value: animateHalo
                )

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

            successBadge
                .offset(x: -64, y: 56)
        }
    }

    private var accountCreatedArtwork: some View {
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
                .InteractiveSpringScaleIn(isAnimated: $animateBadge, delay: 0.05, duration: 0.9, fromScale: 0.72)
                .overlay {
					Image(.icUserId)
						.resizable()
						.frame(width: 100, height: 100)

                }

            successBadge
                .offset(x: 70, y: -60)
        }
    }

    // MARK: - Glyphs
    private var phoneGlyph: some View {
        Image(.icSmartPhone)
            .rotationEffect(.degrees(45))
    }


    private var successBadge: some View {
        Image(.icRightTick)
            .resizable()
            .frame(width: 28, height: 28)
            .scaleEffect(animateContent ? 1 : 0.35)
            .animation(
                .interactiveSpring(duration: 0.65, extraBounce: 0.32)
                    .delay(0.36),
                value: animateContent
            )
    }

    // MARK: - Navigation
    private func onGetStarted() {
        switch screenType {
        case .otpVerified:
            router.setRoot(.accountCreation)
        case .accountCreation:
            router.setRoot(.dashboard)
        }
    }
}

#Preview {
    ComplationScreen(screenType:.accountCreation)
        .environment(Router())
}
