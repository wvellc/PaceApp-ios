import SwiftUI

// MARK: - Step 1: Event Details

struct EventDetailsStepView: View {
	@State var viewModel: CreateRunEventViewModel

    @FocusState private var focusedField: EventDetailsStepViewField?

    var body: some View {
        VStack(spacing: 18) {
			
			//Event Name
            AppTextField(
				text: $viewModel.eventName,
				placeholder: .eventName,
				validation: .name,
				leadingView: AnyView(Image(.icEventName)),
            )
			.focused($focusedField, equals: .eventName)
			.onSubmit {
				focusedField = .location
			}

			//Event Location
            AppTextField(
				text: $viewModel.location,
				placeholder: .location,
				validation: .location,
				leadingView: AnyView(Image(.icLocation)),
				submitLabel: .done,
            )
            .focused($focusedField, equals: .location)
			.onSubmit {
				focusedField = nil
			}

			//Event Date
            DatePickerField(date: $viewModel.eventDate,
                           minDate: viewModel.minDate,
                           maxDate: viewModel.maxDate
			)

			
        }
		.padding(.top, 32)
		.onChange(of: viewModel.focusedField) { oldField, newField in
			focusedField = newField
		}
    }
}

#Preview {
	EventDetailsStepView(viewModel: CreateRunEventViewModel())
		.padding()
		.appBackground()
}

