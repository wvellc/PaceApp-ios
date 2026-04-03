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
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Look-Back Intervals")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "1E3A8A"))

                    Spacer()

                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }

                HStack {
                    Picker("Intervals", selection: $viewModel.lookBackIntervals) {
                        ForEach(1...50, id: \.self) { val in
                            Text("\(val)").tag(val)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 100)
                    .clipped()

                    Spacer()
                }
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "DBEAFE"), lineWidth: 1.5)
                        .background(Color.white.cornerRadius(12))
                )
            }

            // Event Type
            VStack(alignment: .leading, spacing: 6) {
                Text("Event Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "1E3A8A"))

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
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "DBEAFE"), lineWidth: 1.5)
                            .background(Color.white.cornerRadius(12))
                    )
                }
            }
        }
    }
}
