//
//  RunAnalysisSectionView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - RunAnalysisSectionView

struct RunAnalysisSectionView: View {
	let viewModel: EventDetailsViewModel
	let isExpanded: Bool
	let onToggle: () -> Void
	
	// Define a 2-column grid layout
	private let columns = [
		GridItem(.flexible(), alignment: .center),
		GridItem(.flexible(), alignment: .center)
	]
	
	// Helper struct to manage the pairing
	private struct StatItem: Identifiable {
		let id = UUID()
		let label: String
		let value: String? // Optional to handle nil data
	}
	
	/// Builds the stats grid dynamically.
	/// Fields with "—" values are hidden to keep the display clean.
	/// Active events show: Event Distance, Finish Time Goal, Look-Back Intervals, Segments.
	/// Completed events additionally show: Completed Distance, Total Time Taken, Time Variance, Average Heart Rate.
	private var stats: [StatItem] {
		[
			StatItem(label: "Event Distance",      value: viewModel.eventDistance),
			StatItem(label: "Completed Distance",  value: viewModel.completedDistance),
			StatItem(label: "Finish Time Goal",    value: viewModel.finishTimeGoal),
			StatItem(label: "Total Time Taken",    value: viewModel.totalTimeTaken),
			StatItem(label: "Time Variance",       value: viewModel.timeVariance),
			StatItem(label: "Look-Back Intervals", value: viewModel.lookBackIntervals),
			StatItem(label: "Segments",            value: viewModel.segmentsCount),
			StatItem(label: "Average Heart Rate",  value: viewModel.averageHeartRate)
		].filter { $0.value != nil && $0.value != "—" }
	}
	
	var body: some View {
		VStack(spacing: 0) {
			detailsSeprator()
			
			RunDetailSectionHeader(title: "Analysis", isExpanded: isExpanded, onToggle: onToggle)
			
			if isExpanded {
				detailsSeprator()
					.padding(.vertical, 8)
				
				// Use LazyVGrid for dynamic flow
				LazyVGrid(columns: columns, spacing: 16) {
					// .compactMap filters out any items where the value is nil
					ForEach(stats.filter { $0.value != nil }) { stat in
						statCell(label: stat.label, value: stat.value ?? "")
					}
				}
				.padding(.top, 12)
				.transition(.opacity.combined(with: .move(edge: .top).combined(with: .scale)))
			}
		}
	}
	
	@ViewBuilder
	private func statCell(label: String, value: String) -> some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(label)
				.font(.regular13)
				.foregroundStyle(.fashionGray)
			Text(value)
				.font(.semiBold17)
				.foregroundStyle(.darkCharcoal)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}
