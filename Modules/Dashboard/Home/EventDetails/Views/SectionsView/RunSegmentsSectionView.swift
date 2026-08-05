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
			
			Text( row.isCompleted ? actualLine(row) : "\(row.goalTime) / \(row.plannedDistance)")
				.font(.semiBold16)
				.foregroundStyle(.darkCharcoal)
				.frame(maxWidth: .infinity)

			Spacer()
			
			Text(row.isCompleted ? "Completed" : "Awaiting")
				.font(.semiBold11)
				.foregroundStyle(row.isCompleted ? .darkCharcoal : .fashionGray)
				.frame(width: 76 ,height: 20, alignment: .center)
				.background(row.isCompleted ? .fluorescentMint : .grayHint)
				.cornerRadius(16)

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

#Preview {
	RunSegmentsSectionView(segments: [
		SegmentRow(id: 1, goalTime: "00:00:23", plannedDistance: "0.10mi"),
		SegmentRow(id: 2, goalTime: "00:10:23", plannedDistance: "0.10mi"),
		SegmentRow(id: 3, goalTime: "00:25:23", plannedDistance: "5.10mi", actualTime: "00:00:23", actualDistance: "2.5mi"),
	], isExpanded: true, onToggle: {
		
	}, distanceUnit: "DDDDD").background(Color.white)
}
