import SwiftUI

// MARK: - Step 4: Segment Choice (Yes/No)

struct SegmentChoiceStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel

    var body: some View {
        RunContentCard {
			RunEventHeaderCard {
				//TODO: Show Info toast
			}

            Text("Do you want to run with segments?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1E3A8A"))

            HStack(spacing: 16) {
                SegmentChoiceButton(
                    title: "Yes",
                    isSelected: viewModel.wantsSegments == true,
                    color: Color(hex: "22C55E")
                ) {
                    viewModel.wantsSegments = true
                }

                SegmentChoiceButton(
                    title: "No",
                    isSelected: viewModel.wantsSegments == false,
                    color: Color(hex: "EF4444")
                ) {
                    viewModel.wantsSegments = false
                }
            }
        }
    }
}

private struct SegmentChoiceButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isSelected ? color : color.opacity(0.5)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isSelected ? 1.03 : 1.0)
                .animation(.spring(response: 0.25), value: isSelected)
        }
    }
}

