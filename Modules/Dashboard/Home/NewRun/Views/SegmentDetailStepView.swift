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
        RunContentCard {
			RunEventHeaderCard {
				//TODO: Show Info toast
			}

            if let segment = currentSegment {
                let distBinding = Binding<Double>(
                    get: { segment.distance },
                    set: { viewModel.updateSegmentDistance($0, at: viewModel.currentSegmentIndex) }
                )
                let minBinding = Binding<Int>(
                    get: { segment.goalMinutes },
                    set: { viewModel.updateSegmentGoalTime(minutes: $0, seconds: segment.goalSeconds, at: viewModel.currentSegmentIndex) }
                )
                let secBinding = Binding<Int>(
                    get: { segment.goalSeconds },
                    set: { viewModel.updateSegmentGoalTime(minutes: segment.goalMinutes, seconds: $0, at: viewModel.currentSegmentIndex) }
                )

                // Distance Row
                SegmentDistancePickerRow(
                    label: "\(segmentLabel) Distance",
                    unit: viewModel.distanceType.rawValue,
                    options: viewModel.segmentDistanceRange,
                    selected: distBinding
                )

                // Goal Time Row
                SegmentTimePickerRow(
                    label: "\(segmentLabel) Estimated Goal Finish Time",
                    minutes: minBinding,
                    seconds: secBinding
                )

                // Validation error (only on last segment)
                if viewModel.isOnLastSegment, let error = viewModel.segmentValidationError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(Color(hex: "EF4444"))
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "EF4444"))
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}
