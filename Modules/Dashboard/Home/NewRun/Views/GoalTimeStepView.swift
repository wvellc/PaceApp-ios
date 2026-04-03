import SwiftUI

// MARK: - Step 3: Goal Time

struct GoalTimeStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel

    var body: some View {
        RunContentCard {
			RunEventHeaderCard {
				//TODO: Show Info toast
			}

            Text("Please specify your goal time.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1E3A8A"))

            HStack(spacing: 0) {
                // Hours picker
                Picker("Hours", selection: $viewModel.goalHours) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 100)
                .clipped()

                Text(":")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "1E3A8A"))
                    .padding(.horizontal, 4)

                // Minutes picker
                Picker("Minutes", selection: $viewModel.goalMinutes) {
                    ForEach(0..<60, id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 100)
                .clipped()

                Spacer()

                Image(systemName: "drop.fill")
                    .foregroundColor(Color(hex: "3B82F6"))
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "DBEAFE"), lineWidth: 1.5)
                    .background(Color.white.cornerRadius(12))
            )
        }
    }
}
