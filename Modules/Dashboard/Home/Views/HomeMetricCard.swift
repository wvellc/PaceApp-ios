//
//  HomeMetricCard.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/1/26.
//

import SwiftUI

struct HomeMetricCard: View {
    let metric: HomeMetric

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: metric.symbolName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.fluorescentMint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28, height: 28)

            Spacer(minLength: 2)

            VStack(spacing: 2) {
                Text(metric.value)
					.font(.semiBold16)
                    .foregroundStyle(.fluorescentMint)
                    .lineLimit(1)
					.tracking(0.32)
                    .minimumScaleFactor(0.75)

                Text(metric.unit)
					.font(.semiBold10)
                    .foregroundStyle(.fluorescentMint)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 21)
        .frame(width: 56, height: 112)
        .modifier(HomeMetricCardGlassModifier())
    }
}

