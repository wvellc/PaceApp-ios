//
//  RunDetailCardView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - Run Detail Card View
struct RunDetailCardView: View {

    @Bindable var viewModel: EventDetailsViewModel  // @Observable → @Bindable

    var body: some View {
        VStack(alignment: .leading) {
			
            // Title
			Text(viewModel.activityData?.title ?? viewModel.activityData?.gaitType?.label ?? "Activity")
				.font(.semiBold24)
                .foregroundStyle(.darkCharcoal)

			VSpace()

            // Time delta badge
            TimeDeltaBadgeView(
                timeDelta: viewModel.timeDeltaFormatted,
                isNegative: viewModel.timeDeltaIsNegative,
                percent: viewModel.completionPercentText
            )

            // Date & Location
            VStack(alignment: .leading, spacing: 8) {
				
				//Date
				if viewModel.activityData?.displayDate != nil {
					HStack(alignment: .center, spacing: 8) {
						Image(.icDate)
							.frame(width: 24, height: 24, alignment: .center)

						Text(viewModel.activityData?.displayDate ?? "")
							.font(.semiBold16)
							.foregroundStyle(.darkCharcoal)
					}
				}
				
				if viewModel.activityData?.location != nil {
					HStack(alignment: .center, spacing: 8) {
						Image(.icLocationBlue)
							.frame(width: 24, height: 24, alignment: .center)

						Text(viewModel.activityData?.location ?? "")
							.font(.semiBold16)
							.foregroundStyle(.darkCharcoal)
					}
				}
            }
			.padding(.vertical, 16)


            // Analysis section
            RunAnalysisSectionView(
                viewModel: viewModel,
                isExpanded: viewModel.isAnalysisExpanded,
                onToggle: viewModel.toggleAnalysis
            )

			// Intervals section
            RunIntervalsSectionView(
                intervals: viewModel.intervals,
                isExpanded: viewModel.isIntervalsExpanded,
                onToggle: viewModel.toggleIntervals
            )

			// Segments section
            RunSegmentsSectionView(
                segments: viewModel.segments,
                isExpanded: viewModel.isSegmentsExpanded,
                onToggle: viewModel.toggleSegments
            )
        }
		.padding(Constant.UI.defaultPadding)
		.cardBackground()
    }
}

// MARK: - TimeDeltaBadgeView

private struct TimeDeltaBadgeView: View {

    let timeDelta: String
    let isNegative: Bool
    let percent: String

	private var color: Color { !isNegative ? .redBoho : .fluorescentMint }
	private var textColor: Color { !isNegative ? .whiteApp : .darkCharcoal }

    var body: some View {
        HStack {
			Image(.icOvertime)
				.renderingMode(.template)
				.frame(width: 24, height: 24)
			
            Text(timeDelta)
				.font(.semiBold16)
			
            Spacer()
			
            Text(percent)
                .font(.semiBold16)
        }
		.foregroundStyle(textColor)
        .padding(.horizontal, 8)
		.padding(.vertical, 4.5)
        .background(color)
		.clipShape(Capsule())
    }
}
