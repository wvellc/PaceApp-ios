//
//  ButtonGlassStyle.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/15/26.
//

import SwiftUI


extension View {
    /// Apply the glass button style when available, with a fallback to `ButtonGlassStyle` on earlier OS versions.
    @ViewBuilder
    func glassButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
			self.buttonStyle(.plain)
        }
    }
}
