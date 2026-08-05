//
//  HomeMetricCardGlassModifier.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/1/26.
//

import SwiftUI

struct HomeMetricCardGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
				.glassEffect(.clear.tint(.radiantBlue.opacity(0.2)).interactive(), in: Capsule())
        } else {
            content
                .background(fallbackBackground)
                .overlay(fallbackStroke)
                .clipShape(Capsule())
        }
    }

    private var fallbackBackground: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.16),
                        .white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.24),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 12)
                    .padding(2)
            }
    }

    private var fallbackStroke: some View {
        Capsule()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        .white.opacity(0.65),
                        .white.opacity(0.12),
                        .white.opacity(0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}
