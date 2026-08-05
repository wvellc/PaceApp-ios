//
//  ProfilePhotoShape.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/27/26.
//

import SwiftUI


struct ProfilePhotoShape: Shape {

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            topLeadingRadius: 72,
            bottomLeadingRadius: 10,
            bottomTrailingRadius: 10,
            topTrailingRadius: 72,
            style: .continuous
        )
        .path(in: rect)
    }
}
