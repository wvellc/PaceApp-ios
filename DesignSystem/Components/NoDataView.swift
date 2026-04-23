//
//  NoDataView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/23/26.
//

import SwiftUI

struct NoDataView : View {
	
	//MARK: Variables
	let icon: ImageResource?
	let title: LocalizedStringResource
	let description: LocalizedStringResource
	
	//MARK: States
	@State private var animateContent = false
	
	//MARK: View Builder
	var body: some View {
		//No Data
		VStack {
			//Image or icon
			if icon != nil {
				Image(icon!)
					.resizable()
					.frame(width: 140, height: 140)
					.padding(.bottom, 40)
					.InteractiveSpringScaleIn(isAnimated: $animateContent, duration: 0.3)
			}
			
			//Details
			VStack(spacing: 18) {
				Text(title)
					.font(.semiBold24)
					.foregroundStyle(.whiteApp)
					.multilineTextAlignment(.center)
					.lineSpacing(6)
					.kerning(0.53624)
					.fadeInUp(isAnimated: $animateContent, delay: 0.18, duration: 0.7, from: 30)
				
				Text(description)
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

#Preview {
	
	NoDataView(
		icon: .icEmptyNotification,
		title: "No Notifications Yet",
		description: "You don’t have any notifications right now."
	)
	.appBackground()
}
