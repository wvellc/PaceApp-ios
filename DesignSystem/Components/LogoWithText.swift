//
//  LogoWithText.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

struct LogoWithText: View {
    var body: some View {
        VStack(spacing: 7) {
            Image("logo")
                .resizable()
                .scaledToFit()
				.frame(width: 153, height: 103)
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 8)

            Text("PACE APP")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.whiteApp)
                .tracking(2)
        }
    }
}
