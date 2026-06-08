//
//  AuthenticatingScreen.swift
//  PaceApp
//
//

import SwiftUI

struct AuthenticatingScreen: View {
    @State private var showUI = false

    var body: some View {
        BackgroundContainer {
            VStack(spacing: 24) {
                Spacer()

				Text(.paceApp)
					.font(.extraBold34)
					.foregroundStyle(.whiteApp)
					.tracking(2)
                    .scaleEffect(showUI ? 1 : 0.85)
                    .opacity(showUI ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showUI)

				VSpace(height: 12)

                VStack(spacing: 46) {
                    ProgressView()
						.tint(.neonAquaBlue)
                        .scaleEffect(1.5)
                    
                    Text("Authenticating...")
						.font(.medium24)
                        .foregroundStyle(.whiteApp)
                        .opacity(showUI ? 0.9 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.2), value: showUI)
                }
                .padding(.bottom, 48)

                Spacer()
            }
            .safeAreaPadding()
            .defaultScreenStyle()
            .onAppear {
                showUI = true
            }
        }
    }
}

#Preview {
    AuthenticatingScreen()
}
