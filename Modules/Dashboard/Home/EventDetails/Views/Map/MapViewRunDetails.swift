//
//  RunDetailMapView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI
import MapKit

// MARK: - RunDetailMapView
struct MapViewRunDetail: View {
	let coordinates: [CLLocationCoordinate2D]
	@State private var position: MapCameraPosition = .automatic
	
	var body: some View {
		Map(position: $position, interactionModes: []) {
			MapPolyline(coordinates: coordinates)
				.stroke(
					.neonAquaBlue,
					style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
				)
		}
		.mapStyle(.standard(emphasis: .muted))
		.preferredColorScheme(.light)
		.clipShape(RoundedRectangle(cornerRadius: Constant.UI.cornerRadius16, style: .continuous))
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

