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
	let description: LocalizedStringResource?
	let onIconTap: VoidCallback?
	
	init(
		icon: ImageResource?,
		title: LocalizedStringResource,
		description: LocalizedStringResource? = nil,
		animateContent: Bool = false,
		onIconTap: VoidCallback? = nil
	) {
		self.icon = icon
		self.title = title
		self.description = description
		self.animateContent = animateContent
		self.onIconTap = onIconTap
	}
	
	//MARK: States
	@State private var animateContent = false
	
	//MARK: View Builder
	var body: some View {
		//No Data
		VStack {
			//Image or icon
			if icon != nil {
				// Button gives native debounce — prevents duplicate action fires on rapid taps.
				// Only rendered when a tap callback is actually provided.
				if let onIconTap {
					Button {
						onIconTap()
					} label: {
						iconImage
					}
					.buttonStyle(.plain)
				} else {
					iconImage
				}
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
				
				if let description {
					Text(description)
						.font(.medium16)
						.foregroundStyle(.whiteApp.opacity(0.9))
						.multilineTextAlignment(.center)
						.lineSpacing(4)
						.fadeInUp(isAnimated: $animateContent, delay: 0.28, duration: 0.7, from: 26)
				}
			}
			.padding(.horizontal, 32)
			
		}
		.onAppear {
			animateContent = true
		}
	}

	// MARK: - Icon image (shared between tappable and static variants)

	private var iconImage: some View {
		Image(icon!)
			.resizable()
			.frame(width: 140, height: 140)
			.padding(.bottom, 32)
			.InteractiveSpringScaleIn(isAnimated: $animateContent, duration: 0.3)
	}
	
}

#Preview {
	
	NoDataView(
		icon: .icEmptyNotification,
		title: "No Notifications Yet",
		description: "You don't have any notifications right now."
	)
	.appBackground()
}
