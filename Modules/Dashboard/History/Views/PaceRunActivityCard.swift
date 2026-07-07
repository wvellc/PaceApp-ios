//
//  RecentActivityCard.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/2/26.
//

import SwiftUI

// MARK: - Recent Activity Card
struct PaceRunActivityCard: View {
    let activity: ActivityData

    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row with run summary and pace delta badge.
            HStack(alignment: .top, spacing: 8) {
					Image(activity.eventType.icon)
					.frame(width: 38, height: 38)

				VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
						.font(.regular13)
						.foregroundStyle(.fashionGray)

                    Text(activity.displayDate)
						.font(.semiBold17)
                        .foregroundStyle(.darkCharcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
						.tracking(0.34)

                }

                Spacer(minLength: 8)

				if activity.delta != nil && activity.delta != "" {
					Text(activity.delta ?? "")
						.font(.semiBold11)
						.foregroundStyle(activity.deltaColor == .fluorescentMint ? .blackApp : .whiteApp)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 8)
						.padding(.vertical, 6)
						.background(activity.deltaColor, in: Capsule())
				}
            }

            // Bottom metrics keep the three activity stats evenly distributed.
            HStack {
				activityMetric(title: .distanceStr, value: activity.distance)

                Spacer(minLength: 12)

				activityMetric(title: .time, value: activity.duration)

                Spacer(minLength: 12)

				activityMetric(title: .avgPace, value: activity.avgPaceFormatted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.whiteApp, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: Helpers
// Renders a single bottom metric column used by distance, time, and pace.
func activityMetric(title: LocalizedStringResource, value: String) -> some View {
	VStack(alignment: .leading, spacing: 4) {
		Text(title)
			.font(.regular13)
			.foregroundStyle(.fashionGray)
			.tracking(0.26)
		
		
		Text(value)
			.font(.semiBold17)
			.foregroundStyle(.darkCharcoal)
			.tracking(0.34)
		
	}
	.frame(maxWidth: .infinity, alignment: .leading)
}
