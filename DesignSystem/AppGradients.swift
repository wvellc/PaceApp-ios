//
//  AppGradients.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

enum AppGradients {
    static let welcomeBackground = LinearGradient(
        stops: [
            Gradient.Stop(color: .radiantBlue, location: 0.0),
            Gradient.Stop(color: .darkSeaBlue, location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.5, y: 0.0),
        endPoint: UnitPoint(x: 0.5, y: 1.0)
    )

    static let buttonFill = LinearGradient(
        colors: [
            .darkCharcoal.opacity(0.35),
            .darkCharcoal.opacity(0.55)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
	
	static var gradientBorder: LinearGradient {
		LinearGradient(
			colors: [
				.fluorescentMint,
				.black
			],
			startPoint: .top,
			endPoint: .bottom
		)
	}
}
