//
//  RunSegmentsSectionView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - RunSegmentsSectionView
//
// Renders the collapsible Segments section on EventDetailsScreen.
// Active events: one line per row — goal time / planned distance.
// Completed events: two lines — actual (top, prominent) + goal (bottom, muted).

struct RunSegmentsSectionView: View {

	let segments: [SegmentRow]
	let isExpanded: Bool
	let onToggle: () -> Void
	var distanceUnit: String = "mi"  // "mi" or "km" — passed from parent for legacy callers

	var body: some View {
		VStack(spacing: 0) {
			detailsSeprator()

			RunDetailSectionHeader(title: "Segments", isExpanded: isExpanded, onToggle: onToggle)

			if isExpanded {
				detailsSeprator()
					.padding(.top, 8)

				VStack(spacing: 12) {
					ForEach(segments) { row in
						segmentRow(row)
					}
				}
				.padding(.top, 12)
				.transition(.opacity.combined(with: .move(edge: .top).combined(with: .scale)))
			}
		}
	}

	// MARK: - Row

	@ViewBuilder
	private func segmentRow(_ row: SegmentRow) -> some View {
		HStack(alignment: .top, spacing: 8) {

			// Segment label — "S1", "S2"…
			Text("S\(row.id + 1)")
				.font(.semiBold16)
				.foregroundStyle(.darkCharcoal)
				.frame(width: 28, alignment: .leading)

			Spacer()

			if row.isCompleted {
				// Completed: actual on top (prominent), goal underneath (muted)
				VStack(alignment: .trailing, spacing: 2) {
					// Actual elapsed time — always present when isCompleted
					HStack(spacing: 4) {
						Image(systemName: "checkmark.circle.fill")
							.font(.system(size: 12))
							.foregroundStyle(.fluorescentMint)
						Text(actualLine(row))
							.font(.semiBold16)
							.foregroundStyle(.darkCharcoal)
					}
					// Planned goal — muted subtitle
					Text("goal: \(row.goalTime) / \(row.plannedDistance)")
						.font(.regular13)
						.foregroundStyle(.grayHint)
				}
			} else {
				// Active: goal only
				Text("\(row.goalTime) / \(row.plannedDistance)")
					.font(.semiBold16)
					.foregroundStyle(.darkCharcoal)
			}
		}
	}

	/// Formats the actual line — "00:00:44 / 1.00 mi" or "00:00:44" when distance is nil.
	private func actualLine(_ row: SegmentRow) -> String {
		guard let time = row.actualTime else { return "—" }
		if let dist = row.actualDistance {
			return "\(time) / \(dist)"
		}
		return time
	}
}
