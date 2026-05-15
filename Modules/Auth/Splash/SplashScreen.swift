//
//  SplashScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/18/26.
//

import SwiftUI

struct SplashScreen: View {
    @State private var showLogo = false

    var body: some View {
        BackgroundContainer {
            VStack {
                Spacer()

                LogoWithText()
                    .scaleEffect(showLogo ? 1 : 0.82)
                    .opacity(showLogo ? 1 : 0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showLogo)

                Spacer()
            }
            .safeAreaPadding()
            .defaultScreenStyle()
            .onAppear {
                showLogo = true
            }
        }
    }
}

#Preview {
    SplashScreen()
}
