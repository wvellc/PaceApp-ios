import SwiftUI

// MARK: - Look-Back Intervals Step

struct LookBackIntervalsStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel

    var body: some View {
        RunContentCard {
			RunEventHeaderCard {
				//TODO: Show Info toast
			}

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
                        ForEach(1...50, id: \.self) { val in
                            Text("\(val)")
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

                Menu {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Button(type.rawValue) {
                            viewModel.eventType = type
                        }
                    }
                } label: {
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
					.cardBackground()
                }

            }
        }
    }
}

#Preview {
	LookBackIntervalsStepView(viewModel: CreateRunEventViewModel())
}
