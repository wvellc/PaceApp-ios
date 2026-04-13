import SwiftUI

// MARK: - Step 4: Segment Choice (Yes/No)

struct SegmentChoiceStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel

    var body: some View {
        RunContentCard {
			RunEventHeaderCard {
				//TODO: Show Info toast
			}

			
			AppLabel(title: .doYouWantToRunWithSegments)

            HStack(spacing: 16) {
                SegmentChoiceButton(
					title: .yes,
                    isSelected: viewModel.wantsSegments == true,
					color: .fluorescentMint,
					textColor: .darkCharcoal
                ) {
                    viewModel.wantsSegments = true
                }

                SegmentChoiceButton(
					title: .no,
                    isSelected: viewModel.wantsSegments == false,
					color: .redBoho,
					textColor: .whiteApp
                ) {
                    viewModel.wantsSegments = false
                }
            }
        }
    }
}

private struct SegmentChoiceButton: View {
	let title: LocalizedStringResource
    let isSelected: Bool
    let color: Color
	let textColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
				.font(.medium18)
				.foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isSelected ? color : color.opacity(0.25)
                )
                .cornerRadius(Constant.UI.defaultCornerRadius)
                .overlay(
					RoundedRectangle(cornerRadius: Constant.UI.defaultCornerRadius)
						.inset(by: 0.60)
						.stroke(.fashionGray, lineWidth: 2)
					
                )
                .animation(.spring(response: 0.25), value: isSelected)
        }
    }
}

#Preview {
	SegmentChoiceStepView(viewModel: CreateRunEventViewModel())
}
