//
//  ProfilePhotoShape.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/27/26.
//

import SwiftUI

// Regular pentagon avatar plate — point at top centre, tapering to a narrower bottom edge.
struct ProfilePhotoShape: Shape {

	/// Corner softening — keeps the point readable without a sharp tip.
	var cornerRadius: CGFloat = 12

	func path(in rect: CGRect) -> Path {
		let corners = Self.corners(in: rect)
		guard corners.count == 5 else { return Path(rect) }

		var path = Path()
		// Start mid-edge so every corner is turned by an arc between its two edges.
		path.move(to: Self.midpoint(corners[4], corners[0]))
		for index in corners.indices {
			let next = corners[(index + 1) % corners.count]
			path.addArc(tangent1End: corners[index], tangent2End: next, radius: cornerRadius)
		}
		path.closeSubpath()
		return path
	}

	/// The five points of a regular pentagon, scaled to fit `rect` and centred in it.
	private static func corners(in rect: CGRect) -> [CGPoint] {
		// A unit-radius pentagon spans 2·sin72 wide and 1+cos36 tall.
		let radius = min(rect.width / (2 * sin(.pi * 0.4)), rect.height / (1 + cos(.pi / 5)))
		let center = CGPoint(x: rect.midX, y: rect.midY + radius * (1 - cos(.pi / 5)) / 2)
		return (0..<5).map { index in
			let angle = -CGFloat.pi / 2 + CGFloat(index) * 2 * .pi / 5
			return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
		}
	}

	private static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
		CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
	}
}
