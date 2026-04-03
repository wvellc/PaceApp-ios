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
	
    var body: some View {
        VStack(spacing: 8) {
			Image(isHighPerformance ? metric.symbol.high : metric.symbol.low)
				.resizable()
                .frame(width: 32, height: 32)
				.scaledToFill()
				.scaleEffect(isHighPerformance ? 1.0 : 0.94)
				.opacity(1.0)
				.animation(.easeInOut(duration: 0.25), value: isHighPerformance)

            Spacer(minLength: 2)

            VStack(spacing: 2) {
                Text(metric.value)
					.font(.semiBold16)
					.foregroundStyle(isHighPerformance ? .fluorescentMint : .redBoho)
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
        .frame(minWidth: 56,maxWidth: 56, minHeight: 112)
        .modifier(HomeMetricCardGlassModifier())
    }
}

