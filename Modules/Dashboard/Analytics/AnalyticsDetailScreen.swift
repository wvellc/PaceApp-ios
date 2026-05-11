
//
//  AnalyticsDetailScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/8/26.
//
//  Detail screen for a specific analytics metric.
//  Shows full-height PaceAreaCharts with axes, a summary value,
//  and a period segmented control.

import SwiftUI

struct AnalyticsDetailScreen: View {

    // MARK: - Properties

    let metricType: AnalyticsMetricType

    // MARK: - State

    @State private var selectedPeriod: AnalyticsPeriod
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(metricType: AnalyticsMetricType, initialPeriod: AnalyticsPeriod = .day) {
        self.metricType = metricType
        _selectedPeriod = State(initialValue: initialPeriod)
    }

    // MARK: - Computed

    private var summaryCards: [AnalyticsSummaryCard] {
        AnalyticsDummyData.summaryCards(for: metricType, period: selectedPeriod)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {

                    // Period Selector
                    AppSegmentedControl(
                        selection: $selectedPeriod,
                        segments: AnalyticsPeriod.allCases.map { (key: $0, title: $0.rawValue) }
                    )
                    .padding(.top, 4)

                    // Summary Chart Cards
                    ForEach(summaryCards) { card in
                        summaryCardView(card)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle(metricType.detailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            AppBackButtonToolbarContent {
                dismiss()
            }
        }
    }

    // MARK: - Summary Card View Builder

    @ViewBuilder
    private func summaryCardView(_ card: AnalyticsSummaryCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // Value Header
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(card.value)
                        .font(.extraBold34)
                        .foregroundStyle(card.accentColor)

                    Text(card.unit)
                        .font(.semiBold16)
                        .foregroundStyle(card.accentColor.opacity(0.7))
                }

                Text(card.title)
                    .font(.medium16)
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            // Full-height chart with axes
            PaceAreaChart(
                dataPoints: card.dataPoints,
                accentColor: card.accentColor,
                gradientColors: [
                    card.accentColor.opacity(0.55),
                    card.accentColor.opacity(0.04)
                ],
                showAxes: true,
                height: 180
            )
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: selectedPeriod)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnalyticsDetailScreen(metricType: .elevation, initialPeriod: .day)
    }
}
