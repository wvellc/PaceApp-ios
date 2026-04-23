//
//  NotificationCard.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/23/26.
//
import SwiftUI

// MARK: - Custom Card View
struct NotificationCard: View {
	let notification: NotificationItem
	
	var body: some View {
		HStack(alignment: .top, spacing: 13) {
			// Left Icon
			Circle()
				.fill(.neonAquaBlue) // Light blue color from image
				.frame(width: 42, height: 42)
				.overlay(
					Image(.icNotificationWhite)
						.resizable()
						.scaledToFit()
						.foregroundStyle(.whiteApp)
						.frame(width: 24, height: 24)
				)
			
			// Text Content
			VStack(alignment: .leading, spacing: 2) {
				Text(notification.title)
					.font(.semiBold17)
					.foregroundColor(.darkCharcoal)
				
				Text(notification.message)
					.font(.medium14)
					.foregroundColor(.fashionGray)
					.lineLimit(2)
				
				Text(notification.timeAgo)
					.font(.medium14)
					.foregroundColor(.fashionGray)
					.padding(.top, 6)
			}
			
			Spacer(minLength: 0) // Pushes content to the left
		}
		.padding(Constant.UI.defaultPadding)
		.background(Color.white)
		.clipShape(RoundedRectangle(cornerRadius: Constant.UI.defaultPadding))
	}
}
