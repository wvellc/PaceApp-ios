//
//  MKRegionCoordinator+Ext.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//

import MapKit

// MARK: - Region Helper
extension MKCoordinateRegion {
	init(coordinates: [CLLocationCoordinate2D]) {
		let lats = coordinates.map { $0.latitude }
		let lons = coordinates.map { $0.longitude }
		
		let center = CLLocationCoordinate2D(
			latitude: (lats.min()! + lats.max()!) / 2,
			longitude: (lons.min()! + lons.max()!) / 2
		)
		let span = MKCoordinateSpan(
			latitudeDelta: (lats.max()! - lats.min()!) * 1.5,
			longitudeDelta: (lons.max()! - lons.min()!) * 1.5
		)
		self.init(center: center, span: span)
	}
}
