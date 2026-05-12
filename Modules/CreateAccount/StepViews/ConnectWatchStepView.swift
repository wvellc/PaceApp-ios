//
//  ConnectWatchStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI
import ConnectIQ

// MARK: - ConnectWatchStepView

/// Step 2 — animated watch pairing illustration.
struct ConnectWatchStepView: View {

    let watch: IQDevice?

    private let pulseDuration: TimeInterval = 2.6
	private let pulseOffsets: [TimeInterval] = [0.0, 0.8, 1.6, 2.4]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Pulsing rings + watch icon
            TimelineView(.animation) { context in
                ZStack {
                    ForEach(Array(pulseOffsets.enumerated()), id: \.offset) { index, delay in
                        pulseRing(at: context.date, delay: delay, baseOpacity: 0.34 - (Double(index) * 0.07))
                    }

                    Image(.icPaceWatch)
                        .scaleEffect(watchScale(at: context.date))
                        .shadow(color: .white.opacity(0.18), radius: 24)
                }
            }
            .frame(width: 260, height: 260)

            VSpace(height: 32)

            // Watch model name
			if watch?.modelName != nil {
				Text(watch!.modelName)
					.font(.semiBold20)
					.foregroundStyle(.whiteApp)
			}

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func pulseRing(at date: Date, delay: TimeInterval, baseOpacity: Double) -> some View {
        let progress = pulseProgress(at: date, delay: delay)
        let scale = 0.88 + (progress * 1.8)
        let opacity = max(0, (1 - progress) * baseOpacity)

        return Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .blur(radius: progress * 3)
    }

    private func pulseProgress(at date: Date, delay: TimeInterval) -> CGFloat {
        let elapsed = date.timeIntervalSinceReferenceDate - delay
        let cycle = elapsed.truncatingRemainder(dividingBy: pulseDuration)
        let normalized = cycle / pulseDuration
        return CGFloat(normalized < 0 ? normalized + 1 : normalized)
    }

    private func watchScale(at date: Date) -> CGFloat {
        let progress = pulseProgress(at: date, delay: 0)
        return 1 + (sin(progress * .pi * 2) * 0.02)
    }
}

#Preview {
	ConnectWatchStepView(watch:.init())
		.appBackground()
}

