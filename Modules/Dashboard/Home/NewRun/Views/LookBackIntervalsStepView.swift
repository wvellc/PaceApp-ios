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

                HStack {
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
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "1E3A8A"))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "6B7280"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
					.cardBackground()
                }
            }
        }
    }
}

#Preview {
	LookBackIntervalsStepView(viewModel: CreateRunEventViewModel())
}
