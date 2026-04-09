import SwiftUI

// MARK: - Step 3: Goal Time

struct GoalTimeStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel

    var body: some View {
        RunContentCard {
			RunEventHeaderCard {
				//TODO: Show Info toast
			}

			AppLabel(title: .pleaseSpecifyYourGoalTime)
			
            HStack(spacing: 0) {
				
				Spacer()
					.frame(width: 24, height: 24)

				
				Spacer()
				
				
                // Hours picker
                Picker("Hours", selection: $viewModel.goalHours) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h))
							.tag(h)
							.font(.medium18)
							.foregroundStyle(.darkCharcoal)

                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 100)
                .clipped()

                Text(":")
					.font(.medium20)
					.foregroundColor(.darkCharcoal)
					.padding(.horizontal, 4)

                // Minutes picker
                Picker("Minutes", selection: $viewModel.goalMinutes) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m))
							.tag(m)
							.font(.medium18)
							.foregroundStyle(.darkCharcoal)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 100)
                .clipped()

                Spacer()

				Image(.icOverTime)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
			.cardBackground()
        }
    }
}

#Preview {
	GoalTimeStepView(viewModel: CreateRunEventViewModel())
}
