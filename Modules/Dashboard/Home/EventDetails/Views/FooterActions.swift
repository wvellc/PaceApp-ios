//
//  SavedFavoriteRow.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - Details footer action
struct FooterActions: View {
	
	let onDelete: () -> Void
	let onDublicate: () -> Void
	
	var body: some View {
		if #available(iOS 26.0, *) {
			GlassEffectContainer(spacing: 12) {
				actions
			}
		} else {
			actions
		}
	}
	
	@ViewBuilder
	var actions: some View {
		HStack(spacing: 12) {
			DetailButton(
				title: "Delete",
				icon:  "trash.fill",
				color: .redBoho,
				action: onDelete
			)
			
			DetailButton(
				title: "Duplicate",
				icon: "plus.square.fill.on.square.fill",
				color: .whiteApp ,
				action: onDublicate
			)
		}
	}
}


// MARK: - Detail Glass  Button
private struct DetailButton: View {
	
	let title: String
	let icon: String
	let color: Color
	let action: () -> Void
	
	@State private var isPressed = false
	
	var body: some View {
		Button(action: action) {
			HStack(alignment:.center, spacing: 7) {
				Image(systemName: icon)
					.font(.medium16)
					.foregroundStyle(color)
				Text(title)
					.font(.medium16)
					.foregroundStyle(color)
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, 4)
		}
		.frame(height: 54)
		.contentShape(Capsule())
		.scaleEffect(isPressed ? 0.96 : 1)
		.animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
		.simultaneousGesture(
			DragGesture(minimumDistance: 0)
				.onChanged { _ in if !isPressed { isPressed = true } }
				.onEnded   { _ in isPressed = false }
		)
		.modifier(HomeMetricCardGlassModifier())
		
	}
}
