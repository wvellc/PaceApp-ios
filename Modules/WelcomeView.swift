//
//  WelcomeView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

/// Welcome screen
struct WelcomeView: View {
	// Animation state flags
	@State private var showBackgroundPattern = false
	@State private var showLogo = false
	@State private var showBottomContent = false
	
	// Tunable animation constants
	private let fadeDuration: Double = 0.6
	private let logoZoomDuration: Double = 0.5
	private let bottomDelayAfterLogo: Double = 1.0
	
	var body: some View {
		ZStack {
			AppGradients.welcomeBackground
				.ignoresSafeArea()
			
			// Background pattern fades in
			Image("BackgroundPattern")
				.resizable()
				.scaledToFill()
				.blendMode(.screen)
				.ignoresSafeArea()
				.opacity(showBackgroundPattern ? 1 : 0)
				.animation(.easeInOut(duration: fadeDuration), value: showBackgroundPattern)
			
			VStack {
				Spacer(minLength: 40)
				
				// Logo appears with zoom-in and moves slightly up when bottom content shows
				LogoWithText()
					.scaleEffect(showLogo ? 1.0 : 0.65)
					.opacity(showLogo ? 1.0 : 0.0)
					.animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2), value: showLogo)
					.animation(.easeInOut(duration: 0.35), value: showBottomContent)
				
				Spacer()
				
				VStack(spacing: 8) {
					Text("\(.turn) \(Text(.pace).font(.semiBold32).foregroundStyle(.green)) \(.into)")
						.font(.light32)
						.foregroundStyle(.whiteApp)
						.opacity(showBottomContent ? 1 : 0)
						.offset(y: showBottomContent ? 0 : 8)
						.animation(.easeOut(duration: 0.4), value: showBottomContent)
					
					Text(.performance)
						.font(.semiBold32)
						.foregroundStyle(.green)
						.opacity(showBottomContent ? 1 : 0)
						.offset(y: showBottomContent ? 0 : 8)
						.animation(.easeOut(duration: 0.45).delay(0.05), value: showBottomContent)
					
					// Get Started button
					GlassButton(title: "Get Started") {
						// TODO: Handle Get Started action
					}
					.opacity(showBottomContent ? 1 : 0)
					.offset(y: showBottomContent ? 0 : 10)
					.animation(.easeOut(duration: 0.5).delay(0.1), value: showBottomContent)
					.padding(.vertical, 36)
				}
				.multilineTextAlignment(.center)
			}
			.safeAreaPadding()
		}
		.onAppear {
			// Stage 1: Fade in background pattern
			showBackgroundPattern = true
			
			// Stage 2: Zoom in logo after a slight delay to let background settle
			DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration * 0.7) {
				withAnimation(.spring(response: logoZoomDuration, dampingFraction: 0.85)) {
					showLogo = true
				}
			}
			
			// Stage 3: Reveal bottom content after specified delay from logo
			DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration * 0.7 + bottomDelayAfterLogo) {
				withAnimation(.easeOut(duration: 0.5)) {
					showBottomContent = true
				}
			}
		}
	}
}

#Preview {
	WelcomeView()
}


#Preview {
    WelcomeView()
}

