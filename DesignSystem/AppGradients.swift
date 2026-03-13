//
//  AppGradients.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

///Common app gradents
enum AppGradients {
    // Background gradient
    static let background = LinearGradient(
        stops: [
            Gradient.Stop(color: .radiantBlue, location: 0.0),
            Gradient.Stop(color: .darkSeaBlue, location: 1.0)
        ],
        startPoint: UnitPoint(x: 0.5, y: 0.0),
        endPoint: UnitPoint(x: 0.5, y: 1.0)
    )
	
	// Subtle vertical border/outline gradient: fluorescent mint to black
	static var border = LinearGradient(
		colors: [
			.fluorescentMint,
			.black
		],
		startPoint: .top,
		endPoint: .bottom
	)
	
	// Primary button fill gradient: neon aqua to deep electric blue
	static let button = LinearGradient(
		colors: [
			.neonAquaBlue,
			Color(red: 26/255, green: 102/255, blue: 255/255)
		],
		startPoint: .top,
		endPoint: .bottom
	)
}

