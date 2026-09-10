//
//  RunDetailCardView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - Run Detail Card View
struct RunDetailCardView: View {

	//MARK: States
    @Bindable var viewModel: EventDetailsViewModel

	
	//MARK: View Builder
    var body: some View {
        VStack(alignment: .leading) {
			
            // Title
			Text(viewModel.activityData?.title ?? viewModel.activityData?.gaitType?.label ?? "Activity")
				.font(.semiBold24)
                .foregroundStyle(.darkCharcoal)

			VSpace(height: 12)

            // Time delta badge
            TimeDeltaBadgeView(
                timeDelta: viewModel.timeDeltaFormatted,
                isNegative: viewModel.timeDeltaIsNegative,
                percent: viewModel.completionPercentText
            )

            // Date & Location
            VStack(alignment: .leading, spacing: 10) {
				
				//Date
				if viewModel.activityData?.displayDate != nil {
					HStack(alignment: .center, spacing: 8) {
						Image(.icDate)
							.frame(width: 24, height: 24, alignment: .center)

						Text(viewModel.activityData?.displayDate ?? "")
							.font(.semiBold16)
							.foregroundStyle(.darkCharcoal)
							.lineLimit(1)

					}
				}
				
				//Location
				if viewModel.activityData?.location != nil {
					HStack(alignment: .center, spacing: 8) {
						Image(.icLocationBlue)
							.frame(width: 24, height: 24, alignment: .center)

						Text(viewModel.activityData?.location ?? "")
							.font(.semiBold16)
							.foregroundStyle(.darkCharcoal)
							.lineLimit(3)
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
			if !viewModel.intervals.isEmpty  {
            	RunIntervalsSectionView(
					intervals: viewModel.intervals,
					isExpanded: viewModel.isIntervalsExpanded,
					onToggle: viewModel.toggleIntervals
				)
            }

			// Segments section
			if !viewModel.segmentRows.isEmpty {
				RunSegmentsSectionView(
					segments: viewModel.segmentRows,
					isExpanded: viewModel.isSegmentsExpanded,
					onToggle: viewModel.toggleSegments,
					distanceUnit: MeasureUnit(measure: viewModel.activityData?.measure ?? MeasureUnit.miles.rawValue).shortLabel
				)
			}
        }
		.padding(Constant.UI.defaultPadding)
		.cardBackground()
    }
}

func detailsSeprator() -> some View {
	return Divider()
		.foregroundStyle(.grayHint)
		.background(.grayHint)
}

