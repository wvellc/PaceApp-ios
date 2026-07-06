//
//  SwipeToDeleteRow.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/6/26.
//
//  A lightweight swipe-to-reveal delete row for use OUTSIDE of a `List`.
//  SwiftUI's `.swipeActions` only works inside a `List`; the Home screen lays
//  its upcoming events out in a VStack inside a ScrollView, where that modifier
//  is silently ignored. This wraps any row content and reveals a trailing
//  delete button on a left swipe, while leaving vertical scrolling intact.
//

import SwiftUI

// MARK: - Swipe To Delete Row

struct SwipeToDeleteRow<Content: View>: View {

	// MARK: - Input

	/// Tap on the row body (when closed) — e.g. push a detail screen.
	let onTap: () -> Void
	/// Tap on the revealed delete button.
	let onDelete: () -> Void
	@ViewBuilder let content: () -> Content

	// MARK: - State

	/// Width of the revealed delete action (circle + surrounding spacing).
	private let actionWidth: CGFloat = 84
	/// Live horizontal offset while dragging.
	@State private var offset: CGFloat = 0
	/// Resting offset (0 = closed, -actionWidth = open).
	@State private var restingOffset: CGFloat = 0

	// MARK: - Body

	var body: some View {
		ZStack(alignment: .trailing) {
			deleteAction
			content()
				.offset(x: offset)
				.gesture(dragGesture)
				.onTapGesture {
					// An open row closes on tap; a closed row forwards the tap.
					if offset != 0 { close() } else { onTap() }
				}
		}
	}

	// MARK: - Delete Action

	private var deleteAction: some View {
		// Circular red delete button matching the History screen's swipe action,
		// vertically centred and inset from the trailing edge for spacing.
		Button {
			close()
			onDelete()
		} label: {
			Image(systemName: "trash.fill")
				.font(.title2)
				.foregroundStyle(.whiteApp)
				.frame(width: 56, height: 56)
				.background(Circle().fill(Color.redBoho))
		}
		.padding(.trailing, 12)
		// Hidden until the row starts sliding open.
		.opacity(offset < 0 ? 1 : 0)
	}

	// MARK: - Gesture

	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 12)
			.onChanged { value in
				// Ignore mostly-vertical drags so the outer ScrollView keeps scrolling.
				guard abs(value.translation.width) > abs(value.translation.height) else { return }
				offset = min(0, max(restingOffset + value.translation.width, -actionWidth))
			}
			.onEnded { _ in
				// Snap open past the halfway point, otherwise snap closed.
				let shouldOpen = offset < -actionWidth / 2
				withAnimation(.easeOut(duration: 0.2)) {
					restingOffset = shouldOpen ? -actionWidth : 0
					offset = restingOffset
				}
			}
	}

	private func close() {
		withAnimation(.easeOut(duration: 0.2)) {
			restingOffset = 0
			offset = 0
		}
	}
}
