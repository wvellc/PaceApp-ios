//
//  ConnectWatchStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI

// MARK: - ConnectWatchStepView

/// Step 2 — animated watch pairing illustration.
struct ConnectWatchStepView: View {

    let watchName: String

    // Pulsing ring animation state
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Pulsing rings + watch icon
            ZStack {
                pulseRing(scale: isPulsing ? 1.6 : 1.0, opacity: isPulsing ? 0.0 : 0.15)
                pulseRing(scale: isPulsing ? 1.35 : 1.0, opacity: isPulsing ? 0.0 : 0.25)
                pulseRing(scale: isPulsing ? 1.1 : 1.0, opacity: isPulsing ? 0.0 : 0.35)

                // Watch face placeholder
				Image(.icPaceWatch)
            }
            .frame(width: 260, height: 260)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.6)
                    .repeatForever(autoreverses: false)
                ) { isPulsing = true }
            }

            VSpace(height: 32)

            // Watch model name
            Text(watchName)
                .font(.semiBold20)
                .foregroundStyle(.whiteApp)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func pulseRing(scale: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false), value: isPulsing)
    }
}


