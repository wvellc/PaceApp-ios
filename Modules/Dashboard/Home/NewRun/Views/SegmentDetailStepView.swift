import SwiftUI

// MARK: - Step 6+: Segment Detail View

struct SegmentDetailStepView: View {
	@Bindable var viewModel: CreateRunEventViewModel
	
	private var currentSegment: RunSegment? {
		guard viewModel.currentSegmentIndex < viewModel.segments.count else { return nil }
		return viewModel.segments[viewModel.currentSegmentIndex]
	}
	
	private var segmentLabel: String {
		"S\(viewModel.currentSegmentIndex + 1)"
	}
	
	var body: some View {
		RunContentCard(content:  {
			RunEventHeaderCard()
				
			if let segment = currentSegment {
				let distBinding = Binding<Float>(
					get: { segment.distance },
					set: { viewModel.updateSegmentDistance($0, at: viewModel.currentSegmentIndex) }
				)
					
				let hrsBinding = Binding<Int>(
					get: {
						segment.goalHours
					},
					set: {
						viewModel
							.updateSegmentGoalTime(
								hours: $0,
								minutes: segment.goalMinutes,
								seconds: segment.goalSeconds,
								at: viewModel.currentSegmentIndex
							)
					}
				)
					
				let minBinding = Binding<Int>(
					get: { segment.goalMinutes
					},
					set: {
						viewModel
							.updateSegmentGoalTime(
								hours: segment.goalHours,
								minutes: $0,
								seconds: segment.goalSeconds,
								at: viewModel.currentSegmentIndex
							)
					}
				)
				let secBinding = Binding<Int>(
					get: { segment.goalSeconds
					},
					set: {
						viewModel
							.updateSegmentGoalTime(
								hours: segment.goalHours,
								minutes: segment.goalMinutes,
								seconds: $0,
								at: viewModel.currentSegmentIndex
							)
					}
				)
					
				// Distance Row
				SegmentDistancePickerRow(
					label: "\(segmentLabel) Distance",
					unit: viewModel.distanceType.rawValue,
					selected: distBinding
				)
					
				// Goal Time Row
				SegmentTimePickerRow(
					label: "\(segmentLabel) Estimated Goal Finish Time",
					hours: hrsBinding,
					minutes: minBinding,
					seconds: secBinding
				)
					
				// Validation error (only on last segment)
				if let error = viewModel.segmentValidationError {
					HStack(spacing: 6) {
						Image(systemName: "exclamationmark.circle.fill")
							.foregroundColor(.redBoho)
						Text(error)
							.font(.regular13)
							.foregroundColor(.redBoho)
					}
					.padding(.top, 4)
				}
				
			} else {
				Text("No segments to display.")
					.font(Font.regular13)
			}
		}, spacing: 24)
	}
}

#Preview("Sample Segments") {
	
	SegmentDetailStepView(viewModel: CreateRunEventViewModel())
		.padding()
}
