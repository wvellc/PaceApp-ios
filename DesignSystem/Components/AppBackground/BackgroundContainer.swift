//
//  ScreenContainer.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import SwiftUI

///
struct BackgroundContainer<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            AppBackground()
                .ignoresSafeArea()
            content
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
