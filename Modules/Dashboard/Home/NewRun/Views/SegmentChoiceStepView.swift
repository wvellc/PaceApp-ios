import SwiftUI

// MARK: - Step 4: Segment Choice (Yes/No)

struct SegmentChoiceStepView: View {
	
	//MARK: Property
    @Bindable var viewModel: CreateRunEventViewModel
	
	//MARK: Environment
	@Environment(\.presentToast) var presentToast

	//MARK: View Builder
    var body: some View {
        RunContentCard {
			RunEventHeaderCard()
				.overlay(alignment: .topTrailing) {
					Button {
						//Show Info toast
						presentToast(
							.info(
								"Segment can divied your run into parts with different distance",
								icon: Image(.icInfo)
							)
						)
						
					} label:{
						Image("icInfo")
							.frame(width: 24, height: 24)
							.padding(11)
					}
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
					textColor: viewModel.wantsSegments != false ? .blackApp : .whiteApp
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
                .background(color)
                .cornerRadius(Constant.UI.defaultCornerRadius)
                .overlay(
					RoundedRectangle(cornerRadius: Constant.UI.defaultCornerRadius)
						.inset(by: 0.60)
						.stroke(.fashionGray, lineWidth: 2)
					
                )
				.opacity(isSelected ? 1 : 0.25)
                .animation(.spring(response: 0.25), value: isSelected)
        }
    }
}

#Preview {
	SegmentChoiceStepView(viewModel: CreateRunEventViewModel())
}
