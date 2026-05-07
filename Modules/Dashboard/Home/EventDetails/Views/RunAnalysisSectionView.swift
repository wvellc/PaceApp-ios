//
//  RunAnalysisSectionView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - RunAnalysisSectionView

struct RunAnalysisSectionView: View {

    let viewModel: EventDetailsViewModel
    let isExpanded: Bool
    let onToggle: () -> Void

	
	var body: some View {
        VStack(spacing: 0) {
			detailsSeprator()


            RunDetailSectionHeader(title: "Analysis", isExpanded: isExpanded, onToggle: onToggle)

            if isExpanded {
				
				detailsSeprator()
					.padding(.vertical, 8)

                VStack(spacing: 12) {
                    statRow(
                        lLabel: "Event Distance",    lValue: viewModel.eventDistance,
                        rLabel: "Completed Distance", rValue: viewModel.completedDistance
                    )
                    statRow(
                        lLabel: "Finish Time Goal",  lValue: viewModel.finishTimeGoal,
                        rLabel: "Total Time Taken",  rValue: viewModel.totalTimeTaken
                    )
                    statRow(
                        lLabel: "Time Variance",     lValue: viewModel.timeVariance,
                        rLabel: "Look-Back Intervals", rValue: viewModel.lookBackIntervals
                    )
                    statRow(
                        lLabel: "Segments",          lValue: viewModel.segmentsCount,
                        rLabel: "Average Heart Rate", rValue: viewModel.averageHeartRate
                    )
                }
                .padding(.top, 12)
				.transition(.opacity.combined(with: .move(edge: .top).combined(with: .scale)))
            }
        }

    }

    @ViewBuilder
    private func statRow(lLabel: String, lValue: String,
                         rLabel: String, rValue: String) -> some View {
        HStack(alignment: .top) {
            statCell(label: lLabel, value: lValue)
            statCell(label: rLabel, value: rValue)
        }
    }

    @ViewBuilder
    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.regular13)
				.foregroundStyle(.fashionGray)
            Text(value)
				.font(.semiBold17)
                .foregroundStyle(.darkCharcoal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


