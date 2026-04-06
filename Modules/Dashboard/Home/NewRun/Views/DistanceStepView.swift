import SwiftUI

// MARK: - Step 2: Distance

struct DistanceStepView: View {
	
    @Bindable var viewModel: CreateRunEventViewModel


//    init(viewModel: CreateRunEventViewModel) {
//        self._viewModel = Bindable(wrappedValue: viewModel)
//        Self.configureSegmentedAppearance()
//    }
	
    var body: some View {
        RunContentCard {
			RunEventHeaderCard {
				//TODO: Show Info toast
			}

			AppLabel(title: .pleaseSpecifyYourDistance)

            // Km / Miles Toggle
            Picker("Distance Type", selection: $viewModel.distanceType) {
                ForEach(DistanceType.allCases, id: \.self) { type in
					Text(type.rawValue)
						.tag(type)
						.padding()
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.distanceType) { _, _ in
                // Reset to a valid value in new range
                viewModel.distance = viewModel.distanceRange.first ?? 1.0
            }
			.tint(.radiantBlue)

            // Distance Value Picker
            HStack {
                Picker("Distance", selection: $viewModel.distance) {
                    ForEach(viewModel.distanceRange, id: \.self) { val in
                        Text(String(format: "%.1f", val))
                            .tag(val)
							.font(.medium18)
							.foregroundStyle(.darkCharcoal)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .clipped()
				.tint(.darkCharcoal)
				
//                Text(viewModel.distanceType.rawValue)
//					.font(.medium18)
//					.foregroundColor(.darkCharcoal)
//					.frame(width: 60)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
					.stroke(.grayHint, lineWidth: 1)
                    .background(Color.white.cornerRadius(12))
            )
        }
    }
}

#Preview("DistanceStepView") {
    let vm = CreateRunEventViewModel()
//	vm.distanceType = .km
//    vm.distance = vm.distanceRange.first ?? 1.0

	DistanceStepView(viewModel: vm)
        .padding()
}
