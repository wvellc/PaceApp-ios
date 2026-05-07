import SwiftUI

// MARK: - Look-Back Intervals Step

struct LookBackIntervalsStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel

    var body: some View {
        RunContentCard {
			RunEventHeaderCard()

            // Look-Back Intervals
            VStack(alignment: .leading, spacing: 0) {
                HStack {
					AppLabel(title: .lookBackIntervals, font: .semiBold20)

                    Spacer()

					// Green dot indicator
					Button {
						//TODO: Show toast message
					} label: {
						Image("icInfo")
							.frame(width: 24, height: 24)
							.padding(11)
					}

                }

				HStack(alignment: .center) {
                    Picker("Intervals", selection: $viewModel.lookBackIntervals) {
						ForEach(1...(Int(viewModel.distance.rounded())), id: \.self) { val in
                            Text(String(format: "%02d", val))
								.font(.medium18)
                                .tag(val)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 100)
                    .clipped()

                    Spacer()
                }
                .padding(.horizontal, 12)
				.cardBackground()

            }
			.padding(.bottom, 8)


            // Event Type
            VStack(alignment: .leading, spacing: 8) {
				AppLabel(title: .eventType, font: .semiBold20)

				HStack {
					Text(viewModel.eventType.rawValue)
						.font(.medium18)
						.foregroundColor(.darkCharcoal)
					Spacer()
					Image(.icDownArrow)
						.frame(width: 24, height: 24)
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 14)
				.frame(maxWidth: .infinity)
				.cardBackground()
				.overlay(
					Menu {
						ForEach(ActivityType.allCases, id: \.self) { type in
							Button(type.rawValue) {
								viewModel.eventType = type
							}
						}
					} label: {
						Color.white.opacity(0.001)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
					}
				)

            }
        }
    }
}

#Preview {
	LookBackIntervalsStepView(viewModel: CreateRunEventViewModel())
}

