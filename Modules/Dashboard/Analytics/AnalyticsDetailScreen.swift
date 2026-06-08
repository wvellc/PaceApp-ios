
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
    let viewModel: AnalyticsViewModel

    // MARK: - State

    @State private var selectedPeriod: AnalyticsPeriod
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(metricType: AnalyticsMetricType, initialPeriod: AnalyticsPeriod = .day, viewModel: AnalyticsViewModel) {
        self.metricType = metricType
        self.viewModel = viewModel
        _selectedPeriod = State(initialValue: initialPeriod)
    }

    // MARK: - Computed

    private var summaryCards: [AnalyticsSummaryCard] {
        viewModel.summaryCards[metricType] ?? []
    }

    // MARK: - Body

    var body: some View {
		VStack {
			
			// Period Selector
			AppSegmentedControl(
				selection: $selectedPeriod,
				segments: AnalyticsPeriod.allCases.map { (key: $0, title: $0.rawValue) }
			)
			.padding(.vertical, Constant.UI.defaultPadding / 2)
			
			// Summary Chart Cards
			ScrollView(showsIndicators: false) {
				ForEach(summaryCards) { card in
					summaryCardView(card)
				}
			}
		}
		.padding(.horizontal ,Constant.UI.defaultPadding)
		.appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            AppBackButtonToolbarContent {
                dismiss()
            }
			
			ToolbarItem(placement: .principal) {
				Text(metricType.detailTitle)
					.font(.medium16)
					.foregroundStyle(.whiteApp)
			}
        }
        .onChange(of: selectedPeriod) { _, newPeriod in
            viewModel.selectedPeriod = newPeriod
            Task { await viewModel.periodChanged() }
        }
        .onAppear {
            viewModel.selectedPeriod = selectedPeriod
        }
    }

    // MARK: - Summary Card View Builder

    @ViewBuilder
    private func summaryCardView(_ card: AnalyticsSummaryCard) -> some View {
        VStack(alignment: .leading, spacing: Constant.UI.defaultPadding) {

            // Value Header
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(card.value)
						.font(.bold28)
                        .foregroundStyle(card.accentColor)

                    Text(card.unit)
                        .font(.semiBold16)
                        .foregroundStyle(card.accentColor.opacity(0.7))
                }

                Text(card.title)
					.font(.semiBold16)
					.foregroundStyle(.darkCharcoal)
            }

            // Full-height chart with axes
            PaceAreaChart(
                dataPoints: card.dataPoints,
                accentColor: card.accentColor,
				gradientColors: metricType.gradientColors,
                showAxes: true,
                height: 172
            )
        }
		.padding(.horizontal, Constant.UI.defaultPadding)
		.padding(.vertical, Constant.UI.defaultPadding )
		.cardBackground()
		.padding(.bottom, Constant.UI.defaultPadding)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnalyticsDetailScreen(
			metricType: .elevation,
			initialPeriod: .day,
			viewModel: AnalyticsViewModel(userId: "preview")
		)
    }
}
