import SwiftUI

// MARK: - Step 2: Distance

struct DistanceStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel

    var body: some View {
        RunContentCard {
			RunEventHeaderCard {
				//TODO: Show Info toast
			}

            Text("Please specify your distance.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1E3A8A"))

            // Km / Miles Toggle
            HStack(spacing: 0) {
                ForEach(DistanceType.allCases, id: \.self) { type in
                    Button {
                        viewModel.distanceType = type
                        // Reset to a valid value in new range
                        viewModel.distance = viewModel.distanceRange.first ?? 1.0
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(viewModel.distanceType == type ? .white : Color(hex: "1E3A8A"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.distanceType == type
                                ? Color(hex: "3B82F6")
                                : Color.clear
                            )
                    }
                }
            }
            .background(Color(hex: "EFF6FF"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "BFDBFE"), lineWidth: 1)
            )

            // Distance Value Picker
            HStack {
                Picker("Distance", selection: $viewModel.distance) {
                    ForEach(viewModel.distanceRange, id: \.self) { val in
                        Text(String(format: "%.1f", val))
                            .tag(val)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipped()

                Text(viewModel.distanceType.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B7280"))
            }
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "DBEAFE"), lineWidth: 1.5)
                    .background(Color.white.cornerRadius(12))
            )
        }
    }
}
