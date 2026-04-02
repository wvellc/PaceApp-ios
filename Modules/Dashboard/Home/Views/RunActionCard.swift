//
//  RunActionCard.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/2/26.
//

import SwiftUI

struct RunActionCard: View {
    private static let cardHeight: CGFloat = 152
    @State private var isUserTapped = false

    let action: RunAction

	
    var body: some View {
		
		VStack(alignment: .leading, spacing: 0) {
			Image(action.symbol)
				.frame(width: 70, height: 70)
			
			Spacer(minLength: 10)
			
			Text(action.title)
				.font(.semiBold17)
				.foregroundStyle(.darkCharcoal)
				.multilineTextAlignment(.leading)
		}
		.padding(16)
		.frame(maxWidth: .infinity, minHeight: Self.cardHeight, maxHeight: Self.cardHeight, alignment: .topLeading)
		.background(.whiteApp, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
		.overlay(alignment: .bottomTrailing) {
			Image(.isRunPlaceholder)
				.resizable()
				.scaledToFit()
				.frame(width: 85.93, height: 102)
				.offset(x: 3, y: 12)
		}
        .scaleEffect(isUserTapped ? 0.92 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isUserTapped)
		.onTapGesture {
			// Provide a quick press animation and trigger action after a slight delay
			isUserTapped = true
			
			Task {
				try? await Task.sleep(for: .milliseconds(80))
				isUserTapped = false
				
				try? await Task.sleep(for: .milliseconds(100))
				action.action()
			}
		}
    }
}

struct RunAction: Identifiable {
	let id = UUID()
	let title: String
	let symbol: String
	let action: () -> Void
	
	static let items: [RunAction] = [
		RunAction(title: "New Run", symbol: "icNewRun", action: {}),
		RunAction(title: "Favorite Run", symbol: "icFavoriteRun", action: {}),
		RunAction(title: "Saved Run", symbol: "icSavedRun", action: {}),
		RunAction(title: "Last Run", symbol: "icLastRun", action: {})
	]
}
