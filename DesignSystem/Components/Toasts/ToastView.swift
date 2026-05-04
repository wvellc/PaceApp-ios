//
//  ToastView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import SwiftUI

// MARK: - Toast View
struct ToastView: View {
	let toast: ToastValue
	let onDismiss: () -> Void
	
	@State private var dragOffset: CGSize = .zero
	
	var body: some View {
		HStack(spacing: 12) {
			// Icon
			if let icon = toast.icon {
				icon
					.resizable()
					.scaledToFit()
					.frame(width: 22, height: 22)
					.foregroundColor(toast.type.tintColor)
					.symbolEffect(.bounce, value: toast.id)  // iOS 17+
			}
			
			// Message
			Text(toast.message)
				.font(.medium14)
				.foregroundColor(.blackApp)
				.lineLimit(3)
				.fixedSize(horizontal: false, vertical: true)
			
			Spacer(minLength: 0)
			
			// Optional Button
			if let button = toast.button {
				Button(button.title) {
					button.action()
					onDismiss()
				}
				.font(.semiBold14)
				.foregroundColor(button.color)
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 13)
		.background(
			ZStack {
				// Blur background
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.fill(.thinMaterial)
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.strokeBorder(toast.type.tintColor.opacity(0.25), lineWidth: 1)
			}
		)
		.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
		.offset(y: dragOffset.height)
		.gesture(
			DragGesture()
				.onChanged { value in
					// Only allow drag upward (negative y)
					if value.translation.height < 0 {
						dragOffset = value.translation
					}
				}
				.onEnded { value in
					if value.translation.height < -40 {
						onDismiss()
					} else {
						withAnimation(.spring()) {
							dragOffset = .zero
						}
					}
				}
		)
		.animation(.spring(response: 0.3), value: dragOffset)
	}
}
