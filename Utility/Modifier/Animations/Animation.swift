//
//  Shake.swift
//  recoverytrak
//
//  Created by FURKAN VIJAPURA on 29/11/24.
//

import SwiftUI


/// Shake animation helper
struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
		    amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
		    y: 0))
    }
}
