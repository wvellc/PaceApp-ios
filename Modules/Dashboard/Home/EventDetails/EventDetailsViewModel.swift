//
//  EventDetailsViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI
import CoreLocation
import MapKit

// MARK: - EventDetailsViewModel

@Observable
final class EventDetailsViewModel {
	
	// MARK: Input
	var activityData: ActivityData?
	
	// MARK: Section Expansion
	var isAnalysisExpanded: Bool  = true
	var isIntervalsExpanded: Bool = false
	var isSegmentsExpanded: Bool  = true
	
	// MARK: Toggle States
	var isFavorite: Bool = false
	
	// MARK: Full-screen map
	var isShowingFullMap: Bool = false
	
	// MARK: Init
	init(activityData: ActivityData? = nil) {
		self.activityData = activityData
	}
	
	// MARK: - Computed: Time Delta
	
	/// Signed time delta in seconds (negative = behind pace, positive = ahead)
	var timeDeltaSeconds: Int { -70 }      // replace with real activityData value
	var timeDeltaIsNegative: Bool { timeDeltaSeconds < 0 }	
	var timeDeltaFormatted: String {
		let abs   = Swift.abs(timeDeltaSeconds)
		let m     = abs / 60
		let s     = abs % 60
		let sign  = timeDeltaIsNegative ? "-" : "+"
		return String(format: "%@%02d:%02d", sign, m, s)
	}
	
	var completionPercent: Int { 97 }       // replace with real activityData value
	var completionPercentText: String { "\(completionPercent)%" }
	
	// MARK: - Computed: Analysis
	
	var eventDistance: String     { "1.00 mi" }
	var completedDistance: String { "1.3 mi" }
	var finishTimeGoal: String    { "00:06:00" }
	var totalTimeTaken: String    { "00:03:51" }
	var timeVariance: String      { "-00:02:09" }
	var lookBackIntervals: String { "1" }
	var segmentsCount: String     { "\(segments.count)" }
	var averageHeartRate: String  { "157 bpm" }
	
	// MARK: - Computed: Intervals
	
	var intervals: [RunInterval] {
		(1...7).map { RunInterval(label: "Interval \($0)", time: "03:02") }
	}
	
	// MARK: - Computed: Segments
	// Uses the real RunSegment model (id: Int, distance: Float, goalHours/Minutes/Seconds)
	
	var segments: [RunSegment] {[
		RunSegment(id: 1, distance: 0.10, goalHours: 0, goalMinutes: 0,  goalSeconds: 23),
		RunSegment(id: 2, distance: 0.25, goalHours: 0, goalMinutes: 1,  goalSeconds: 5),
		RunSegment(id: 3, distance: 0.50, goalHours: 0, goalMinutes: 2,  goalSeconds: 15),
		RunSegment(id: 4, distance: 0.75, goalHours: 0, goalMinutes: 3,  goalSeconds: 40),
	]}
	
	// MARK: - Route Coordinates
	
	var routeCoordinates: [CLLocationCoordinate2D] {[
		CLLocationCoordinate2D(latitude: 40.666349, longitude: -74.214964),
		CLLocationCoordinate2D(latitude: 40.666351, longitude: -74.214964),
		CLLocationCoordinate2D(latitude: 40.666589, longitude: -74.213397),
		CLLocationCoordinate2D(latitude: 40.667108, longitude: -74.210215),
		CLLocationCoordinate2D(latitude: 40.667117, longitude: -74.210118),
		CLLocationCoordinate2D(latitude: 40.667105, longitude: -74.210012),
		CLLocationCoordinate2D(latitude: 40.667080, longitude: -74.209892),
		CLLocationCoordinate2D(latitude: 40.667108, longitude: -74.209878),
		CLLocationCoordinate2D(latitude: 40.667108, longitude: -74.209878),
		CLLocationCoordinate2D(latitude: 40.667080, longitude: -74.209892),
		CLLocationCoordinate2D(latitude: 40.666565, longitude: -74.208271),
		CLLocationCoordinate2D(latitude: 40.666190, longitude: -74.207139),
		CLLocationCoordinate2D(latitude: 40.665875, longitude: -74.206130),
		CLLocationCoordinate2D(latitude: 40.665519, longitude: -74.205041),
		CLLocationCoordinate2D(latitude: 40.665519, longitude: -74.205041),
		CLLocationCoordinate2D(latitude: 40.665062, longitude: -74.203670),
		CLLocationCoordinate2D(latitude: 40.662094, longitude: -74.205338),
		CLLocationCoordinate2D(latitude: 40.662277, longitude: -74.205923),
		CLLocationCoordinate2D(latitude: 40.662599, longitude: -74.206870),
		CLLocationCoordinate2D(latitude: 40.662651, longitude: -74.206839),
		CLLocationCoordinate2D(latitude: 40.662651, longitude: -74.206839),
		CLLocationCoordinate2D(latitude: 40.662599, longitude: -74.206870),
		CLLocationCoordinate2D(latitude: 40.662753, longitude: -74.207334),
		CLLocationCoordinate2D(latitude: 40.663017, longitude: -74.208182),
		CLLocationCoordinate2D(latitude: 40.663376, longitude: -74.209234),
		CLLocationCoordinate2D(latitude: 40.663501, longitude: -74.209625),
		CLLocationCoordinate2D(latitude: 40.663889, longitude: -74.210708),
		CLLocationCoordinate2D(latitude: 40.663970, longitude: -74.210914),
		CLLocationCoordinate2D(latitude: 40.664047, longitude: -74.211082),
		CLLocationCoordinate2D(latitude: 40.664047, longitude: -74.211082),
		CLLocationCoordinate2D(latitude: 40.664220, longitude: -74.211468),
		CLLocationCoordinate2D(latitude: 40.664183, longitude: -74.211498),
		CLLocationCoordinate2D(latitude: 40.664164, longitude: -74.211525),
		CLLocationCoordinate2D(latitude: 40.664175, longitude: -74.211538),
		CLLocationCoordinate2D(latitude: 40.664512, longitude: -74.212413),
		CLLocationCoordinate2D(latitude: 40.664583, longitude: -74.212379),
		CLLocationCoordinate2D(latitude: 40.664812, longitude: -74.212951),
		CLLocationCoordinate2D(latitude: 40.664901, longitude: -74.213219),
		CLLocationCoordinate2D(latitude: 40.665301, longitude: -74.214550),
		CLLocationCoordinate2D(latitude: 40.665328, longitude: -74.214768),
		CLLocationCoordinate2D(latitude: 40.665324, longitude: -74.214768),
		CLLocationCoordinate2D(latitude: 40.665324, longitude: -74.214768),
		CLLocationCoordinate2D(latitude: 40.665487, longitude: -74.214759),
		CLLocationCoordinate2D(latitude: 40.666346, longitude: -74.214997),
		CLLocationCoordinate2D(latitude: 40.666351, longitude: -74.214964),
	]}
	

	
	// MARK: - Actions
	func toggleFavorite() {
		withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
			isFavorite.toggle()
		}
	}
	
	func toggleAnalysis() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
			isAnalysisExpanded.toggle()
		}
	}
	
	func toggleIntervals() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
			isIntervalsExpanded.toggle()
		}
	}
	
	func toggleSegments() {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
			isSegmentsExpanded.toggle()
		}
	}
	
	func openFullMap() {
		isShowingFullMap = true
	}
	
	func closeFullMap() {
		isShowingFullMap = false
	}
	
	//TODO: Delete event
	func deleteEvent() {
		print("Delete event tapped")
	}
	//TODO: Dublicate event
	func duplicateEvent() {
		print("Duplicate event tapped")
	}
}
