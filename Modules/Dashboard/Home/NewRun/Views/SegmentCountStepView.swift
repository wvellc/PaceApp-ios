//
//  SegmentCountStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/6/26.
//

import SwiftUI

// MARK: - Step 5: Segment Count
struct SegmentCountStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel
    @State private var inputText: String = ""

    var body: some View {
        RunContentCard {
			RunEventHeaderCard()
			

			AppLabel(title: "Great! How many segments would you like for this run?")

			AppTextField(
				text: $inputText,
				placeholder: "e.g. 3",
				textContentType: .none,
				keyboardType: .numberPad,
				autocapitalization: .never,
				submitLabel: .done,
				borderColor: .fashionGray,
				foregroundStyle: .darkCharcoal,
				onValueChanged: { newValue in
					// Allow max 2 digit number (iOS 17+ onChange signature)
					let filtered = newValue.filter { $0.isNumber }
					let truncated = String(filtered.prefix(2))
					inputText = truncated
					if let val = Int(truncated), val >= viewModel.minSegments, val <= viewModel.maxSegments {
						viewModel.segmentCount = val
					}
				}
			)
			.onAppear {
				inputText = "\(viewModel.segmentCount)"
			}
        }
    }
}

#Preview {
	SegmentCountStepView(viewModel: CreateRunEventViewModel())
		.appBackground()
}
