//
//  FullScreenMapView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//

import SwiftUI
import MapKit

// MARK: - FullScreenMapView
struct MapViewFullScreen: View {
	let coordinates: [CLLocationCoordinate2D]
	
	@State private var position: MapCameraPosition = .automatic
	
	var body: some View {
		ZStack(alignment: .top) {
			// Default init allows all interaction modes (zoom/pan)
			Map(position: $position) {
				MapPolyline(coordinates: coordinates)
					.stroke(
						.neonAquaBlue,
						style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
					)
			}
			.mapStyle(.standard(emphasis: .muted))
			.preferredColorScheme(.light)
			.ignoresSafeArea()
		}
		.onAppear {
			updateCameraPosition()
		}
	}
	
	private func updateCameraPosition() {
		guard !coordinates.isEmpty else { return }
		let region = MKCoordinateRegion(coordinates: coordinates)
		position = .region(region)
	}
}
