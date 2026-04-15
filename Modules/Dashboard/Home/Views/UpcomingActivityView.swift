//
//  UpcomingActivityView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/10/26.
//
import SwiftUI

///Upcoming activity cell
struct UpcomingActivityView: View {
	
	let activity: RecentActivity
	
	var body: some View {
		HStack(alignment: .top) {
			Image(.icRunLeft)
				.frame(width: 35.38, height: 42)
			
			VStack(alignment: .leading, spacing: 16) {
				
				activityMetric(
					title: LocalizedStringResource(stringLiteral: activity.title),
					value: activity.displayDate
				)
				
				
				activityMetric(
					title: .location,
					value: activity.location
				)
			}			
			
			// Bottom metrics keep the three activity stats evenly distributed.
			VStack(alignment: .leading, spacing: 16)  {
				activityMetric(title: .distanceStr, value: activity.distance)
				
				activityMetric(title: .gaolTime, value: activity.duration)
			}
			
		}
		.padding(.horizontal, 14)
		.padding(.vertical, 12)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.whiteApp, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
	}
}
