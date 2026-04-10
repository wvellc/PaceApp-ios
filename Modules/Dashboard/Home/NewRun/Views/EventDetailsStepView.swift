import SwiftUI

// MARK: - Step 1: Event Details

struct EventDetailsStepView: View {
    @Bindable var viewModel: CreateRunEventViewModel

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case eventName
        case location
    }

    var body: some View {
        VStack(spacing: 16) {
			
			//Event Name
            AppTextField(
				text: $viewModel.eventName,
				placeholder: .eventName,
				leadingView: AnyView(Image(.icEventName)),
				borderColor: .fashionGray
            )
			.focused($focusedField, equals: .eventName)
			.onSubmit {
				focusedField = .location
			}

			//Event Location
            AppTextField(
				text: $viewModel.location,
				placeholder: .location,
				leadingView: AnyView(Image(.icLocation)),
				submitLabel: .done,
				borderColor: .fashionGray
            )
            .focused($focusedField, equals: .location)
			.onSubmit {
				focusedField = nil
			}

			//Event Date
            DatePickerField(date: $viewModel.eventDate,
                           minDate: viewModel.minDate,
                           maxDate: viewModel.maxDate)

			
            if let error = viewModel.eventDetailsError {
                Text(error)
					.font(.regular13)
					.foregroundColor(.redBoho)
                    .padding(.top, 4)
            }
        }
		.padding(.top, 32)
    }
}

#Preview {
	EventDetailsStepView(viewModel: CreateRunEventViewModel())
		.padding()
		.appBackground()
}

// MARK: - Date Picker Field
private struct DatePickerField: View {
    @Binding var date: Date
    let minDate: Date
    let maxDate: Date
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            HStack(spacing: 12) {
                Image("icEventDate")
					.frame(width: 24, height: 24)

                Text(date.formatted(date: .abbreviated, time: .omitted))
					.font(.medium20)
					.foregroundColor(.whiteApp)
					

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.medium20)
                    .foregroundColor(.fashionGray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
				RoundedRectangle(cornerRadius: Constant.UI.defaultCornerRadius)
					.stroke(.fashionGray, lineWidth: 1)
            )
        }
        .sheet(isPresented: $showPicker) {
			DatePickerSheet(date: $date, minDate: minDate, maxDate: maxDate)
				.fixedSize(horizontal: false, vertical: true)
				.presentationDetents([.height(434)])
				.presentationDragIndicator(.visible)
				

        }
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    @Binding var date: Date
    let minDate: Date
    let maxDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
				Text(.selectDate)
					.font(.semiBold17)
					.foregroundStyle(.blackApp)
				
                Spacer()
				Button(.done) { dismiss() }
					.font(.semiBold17)
					.foregroundColor(.radiantBlue)
            }
			.padding(.top, 18)

            DatePicker(
                "",
                selection: $date,
                in: minDate...maxDate,
                displayedComponents: .date
            )
			.datePickerStyle(.graphical)
			.tint(.radiantBlue)
			
			
		}
		.padding(.horizontal, Constant.UI.defaultPadding)

    }
}
