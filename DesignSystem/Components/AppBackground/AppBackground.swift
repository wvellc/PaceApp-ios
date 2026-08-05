//
//  AppBackground.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import SwiftUI

///App comman background
struct AppBackground: View {
    @State private var showPattern = false
    private let fadeDuration = 0.8
    
    var body: some View {
        ZStack {
            // Base gradient
            AppGradients.background
                .ignoresSafeArea()
            
            // Pattern overlay with fade-in
            Image(.backgroundPattern)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(showPattern ? 1 : 0)
                .animation(.easeInOut(duration: fadeDuration), value: showPattern)
        }
        .onAppear {
            showPattern = true
        }
    }
}

//MARK: App Background Modifier
struct AppBackgroundModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.background {
				AppBackground()
					.ignoresSafeArea()
			}
	}
}

//MARK: Extension
extension View {
	func appBackground() -> some View {
		modifier(AppBackgroundModifier())
	}
	
	func defaultScreenStyle() -> some View {
		self
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(.clear)                               // ✅ Screen is transparent
			.toolbarBackground(.hidden, for: .navigationBar) // ✅ Nav bar is transparent
			.ignoresSafeArea(.keyboard, edges: .bottom)       // ✅ No bg shift on keyboard
	}
}
