//
//  EventDetailsScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI
import MapKit

///Event details screen
struct EventDetailsScreen: View {
	
	//MARK: Variables
	let activityData: ActivityData?
	@State private var route: MKRoute?
	
	//MARK: Environment
	@Environment(\.dismiss) private var dismiss
	
	//MARK: View Builder
	var body: some View {
		VStack {
			//MARK: Rout map
			Map {
				if let route {
					MapPolyline(route)
						.stroke(.blue, lineWidth: 5)
				}
			}
//			.task {
//				getDirections()
//			}
			
			//MARK: Save & Favorites

			VStack {
				//MARK: Basic details
				//MARK: Analisys
				//MARK: Intervals
				//MARK: Segments
			}
			
		}
		.appBackground()
		.navigationBarTitle("\(activityData?.gaitType?.label ?? "")\(activityData?.gaitType?.label != nil ? " " : "")Details")
		.navigationBarTitleDisplayMode(.inline)
	}
}

#Preview {
	EventDetailsScreen(activityData: ActivityData.samples.first)
}
