//
//  HistoryNoData.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import SwiftUI

struct HistoryNoData: View {
	
	@State private var animateContent = false
	
	var body: some View {
		//No Data
		VStack {
			
			Image(.icEmptyHistory)
				.resizable()
				.frame(width: 140, height: 140)
				.padding(.bottom, 40)
				.InteractiveSpringScaleIn(isAnimated: $animateContent, duration: 0.3)
			
			VStack(spacing: 18) {
				Text("Ready for your first run!")
					.font(.semiBold24)
					.foregroundStyle(.whiteApp)
					.multilineTextAlignment(.center)
					.lineSpacing(6)
					.kerning(0.53624)
					.fadeInUp(isAnimated: $animateContent, delay: 0.18, duration: 0.7, from: 30)
				
				Text("Great things start here. Track your first event to unlock splits, pace analysis and personal bests.")
					.font(.medium16)
					.foregroundStyle(.whiteApp.opacity(0.9))
					.multilineTextAlignment(.center)
					.lineSpacing(4)
					.fadeInUp(isAnimated: $animateContent, delay: 0.28, duration: 0.7, from: 26)
			}
			.padding(.horizontal, 32)
			
			
		}
		.onAppear {
			animateContent = true
		}
	}
}
