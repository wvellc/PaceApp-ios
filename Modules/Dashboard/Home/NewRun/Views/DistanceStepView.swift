import SwiftUI

// MARK: - Step 2: Distance

struct DistanceStepView: View {
	
	@Bindable var viewModel: CreateRunEventViewModel

	var body: some View {
		RunContentCard {
			RunEventHeaderCard()
			
			AppLabel(title: .pleaseSpecifyYourDistance)
			
			// Km / Miles Toggle
//			Picker("Distance Type", selection: $viewModel.distanceType) {
//				ForEach(DistanceType.allCases, id: \.self) { type in
//					Text(type.rawValue)
//						.tag(type)
//						.padding()
//				}
//			}
//			.pickerStyle(.segmented)
			AppSegmentedControl(
				selection: $viewModel.distanceType,
				segments: MeasureUnit.allCases.map { (key: $0, title: $0.rawValue) },
				unselectedForeground: .darkCharcoal,
				trackBackground: .grayHint
			)
			.onChange(of: viewModel.distanceType) { _, newState in
				// Reset to a valid value in new range
				viewModel.distance = viewModel.distanceRange.first ?? 1.0
			}
			.tint(.radiantBlue)
			
			// Distance Value Picker
			HStack {
				// Integer part 0...999 with leading zeros (00, 01, ... 999)
				Picker("Integer Distance", selection: Binding(
					get: {
						let clamped = max(0, min(999, Int(viewModel.distance)))
						return clamped
					},
					set: { (newValue: Int) in
						let fractional = viewModel.distance - floor(viewModel.distance)
						let clampedInt = max(0, min(999, newValue))
						viewModel.distance = Float(clampedInt) + fractional
					}
				)) {
					ForEach(1...999, id: \.self) { intVal in
						// Format with at least two digits for small numbers
						let text = intVal < 100 ? String(format: "%02d", intVal) : String(intVal)
						Text(text)
							.tag(intVal)
							.font(.medium18)
							.foregroundStyle(.darkCharcoal)
					}
				}
				.pickerStyle(.wheel)
				.frame(maxWidth: .infinity)
				.frame(height: 100)
				.clipped()
				.tint(.darkCharcoal)
				
				Text(".")
					.font(.bold24)
					.foregroundStyle(.darkCharcoal)
					.baselineOffset(5) // Adjusts visual alignment of the dot

				
				// Fractional part in hundredths (00, 01, ... 99) representing .00 to .99
				Picker("Fractional Distance", selection: Binding(
					get: {
						let fractional = viewModel.distance - floor(viewModel.distance)
						let hundredths = Int((fractional * 100).rounded())
						return max(0, min(99, hundredths))
					},
					set: { (newValue: Int) in
						let clampedHundredths = max(0, min(99, newValue))
						let intPart = Int(viewModel.distance)
						viewModel.distance = Float(intPart) + Float(clampedHundredths) / 100.0
					}
				)) {
					ForEach(0...99, id: \.self) { frac in
						Text(String(format: "%02d", frac))
							.tag(frac)
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
