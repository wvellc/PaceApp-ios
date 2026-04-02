//
//  RecentActivityCard.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/2/26.
//

import SwiftUI

// MARK: - Recent Activity Card
struct RecentActivityCard: View {
    let activity: RecentActivity

    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row with run summary and pace delta badge.
            HStack(alignment: .top, spacing: 12) {
					Image(.icRunLeft)
						.frame(width: 35.38, height: 42)
					

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
						.font(.regular13)
						.foregroundStyle(.fashionGray)

                    Text(activity.date)
						.font(.semiBold17)
                        .foregroundStyle(.darkCharcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
						.tracking(0.34)

                }

                Spacer(minLength: 8)

                Text(activity.delta)
					.font(.semiBold11)
                    .foregroundStyle(.whiteApp)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(activity.deltaColor, in: Capsule())
            }

            // Bottom metrics keep the three activity stats evenly distributed.
            HStack  {
                activityMetric(title: "Distance", value: activity.distance)

                Spacer(minLength: 12)

                activityMetric(title: "Time", value: activity.duration)

                Spacer(minLength: 12)

                activityMetric(title: "Avg Pace", value: activity.avgPace)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.whiteApp, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Helpers
    // Renders a single bottom metric column used by distance, time, and pace.
    private func activityMetric(title: String, value: String) -> some View {
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
}

// MARK: - Recent Activity Model
struct RecentActivity: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let distance: String
    let duration: String
    let avgPace: String
    let delta: String
    let deltaColor: Color

    // MARK: Sample Data
    // Sample content used by the dashboard preview state.
    static let samples: [RecentActivity] = [
        RecentActivity(
            title: "Thursday Run",
            date: "29 Jan",
            distance: "5.00 mi",
            duration: "0:45",
            avgPace: "9:00 /mi",
            delta: "+01:10",
			deltaColor: .redBoho
        ),
        RecentActivity(
            title: "Saturday Run",
            date: "31 Jan",
            distance: "15.00 mi",
            duration: "0:50",
            avgPace: "3:20 /mi",
            delta: "-02:15",
			deltaColor: .fluorescentMint
        )
    ]
}
