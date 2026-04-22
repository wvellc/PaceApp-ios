//
//  HomeMetricCard.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/1/26.
//

import SwiftUI

struct HomeMetricCard: View {
    let metric: HomeMetric
	var isHighPerformance: Bool
	var onTap: () -> Void

    var body: some View {
		Button(action: onTap) {
        	VStack(spacing: 8) {
				Image(metric.symbol)
					.resizable()
					.frame(width: 32, height: 32)
					.foregroundColor(isHighPerformance ? .fluorescentMint : .inferno)
					.scaledToFill()
					.padding(.horizontal, 6)
					.animation(.easeInOut(duration: 0.25), value: isHighPerformance)

				Spacer(minLength: 2)

				VStack(spacing: 2) {
					Text(metric.value)
						.font(.semiBold17)
						.foregroundStyle(isHighPerformance ? .fluorescentMint : .inferno)
						.lineLimit(1)
						.tracking(0.32)
						.minimumScaleFactor(0.75)
						.scaleEffect(isHighPerformance ? 1.0 : 0.98)
						.opacity(1.0)
						.animation(.easeInOut(duration: 0.25), value: isHighPerformance)

					Text(metric.unit)
						.font(.semiBold11)
						.foregroundStyle(isHighPerformance ? .fluorescentMint : .redBoho)
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.scaleEffect(isHighPerformance ? 1.0 : 0.98)
						.opacity(0.98)
						.animation(.easeInOut(duration: 0.25), value: isHighPerformance)
				}
			}
			.padding(.horizontal, 6)
			.padding(.vertical, 21)
			.frame(minWidth: 60,maxWidth: 60, minHeight: 112, maxHeight: 112)
			.modifier(HomeMetricCardGlassModifier())
        }
    }
}

