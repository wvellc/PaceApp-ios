//
//  RunDetailMapView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI
import MapKit

// MARK: - RunDetailMapView
struct RunDetailMapView: View {

    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        RunRouteMapRepresentable(coordinates: coordinates)
			.clipShape(RoundedRectangle(cornerRadius: Constant.UI.cornerRadius16, style: .continuous))
    }
}

// MARK: - FullScreenMapView
// Full map presented via .fullScreenCover. Mirrors the second design image.

struct FullScreenMapView: View {

    let coordinates: [CLLocationCoordinate2D]
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
			RunRouteMapRepresentable(coordinates: coordinates, isZoomEnabled: true)
                .ignoresSafeArea()

            // Nav bar overlay
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Spacer()

                Text("Run Detail")
                    .font(.semiBold17)
                    .foregroundColor(.primary)

                Spacer()

                Color.clear.frame(width: 40, height: 40)   // balance
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

// MARK: - RunRouteMapRepresentable
// UIViewRepresentable wrapping MKMapView so we can draw MKPolyline
// (SwiftUI's Map/MapPolyline requires an MKRoute; this draws raw coordinates directly).

struct RunRouteMapRepresentable: UIViewRepresentable {

    let coordinates: [CLLocationCoordinate2D]
	let isZoomEnabled: Bool
	
	init(coordinates: [CLLocationCoordinate2D], isZoomEnabled: Bool = false) {
		self.coordinates = coordinates
		self.isZoomEnabled = isZoomEnabled
	}
	
	
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.mapType              		= .mutedStandard
		map.isUserInteractionEnabled 	= isZoomEnabled
		map.isZoomEnabled 				= isZoomEnabled
        map.delegate             		= context.coordinator
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        guard coordinates.count > 1 else { return }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polyline, level: .aboveRoads)
        map.setRegion(region(for: coordinates), animated: false)
    }

    // MARK: - Region helper
    private func region(for coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude:  (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta:  (lats.max()! - lats.min()!) * 3,
            longitudeDelta: (lons.max()! - lons.min()!) * 3
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let r = MKPolylineRenderer(polyline: polyline)
			r.strokeColor = .neonAquaBlue
            r.lineWidth   = 8
            r.lineCap     = .round
            r.lineJoin    = .round
            return r
        }
    }
}
