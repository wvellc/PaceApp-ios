//
//  WelcomeView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

/// Welcome screen
struct WelcomeView: View {
    var body: some View {
        ZStack {
            AppGradients.welcomeBackground
                .ignoresSafeArea()

            Image("BackgroundPattern")
                .resizable()
                .scaledToFill()
                .blendMode(.screen)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 40)

				LogoWithText()

                Spacer()

                VStack(spacing: 8) {
                    Text("Turn Pace Into")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.whiteApp.opacity(0.9))

                    Text("Performance")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.arabGreen)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                Spacer()

				//Get Started button
                GlassButton(title: "Get Started") {
                    // TODO: Handle Get Started action
                }
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 24)
			.safeAreaPadding()
        }
    }
}

#Preview {
	WelcomeView()
}

