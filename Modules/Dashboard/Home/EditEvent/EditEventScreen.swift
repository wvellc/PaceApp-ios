//
//  EditEventScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//

import SwiftUI

/// Edit event name and location screen
struct EditEventScreen: View {
	
	@Binding var eventData: ActivityData?

	//MARK: Environment
	@Environment(\.dismiss) var dismiss
	
	//MARK: States
	@FocusState private var focusedField: EventDetailsStepViewField?
	@State private var eventName: String = ""
	@State private var location: String = ""

	//MARK: View Builder
	var body: some View {
		VStack(spacing: 16) {
			
			//Event Name
			AppTextField(
				text: $eventName,
				placeholder: LocalizedStringResource(
					stringLiteral: eventData?.title ?? ""
				),
				validation: .name,
				leadingView: AnyView(Image(.icEventName)),
			)
			.focused($focusedField, equals: .eventName)
			.onSubmit {
				focusedField = .location
			}
			
			//Event Location
			AppTextField(
				text: $location,
				placeholder: LocalizedStringResource(
					stringLiteral: eventData?.location ?? ""
				),
				validation: .location,
				leadingView: AnyView(Image(.icLocation)),
				submitLabel: .done,
			)
			.focused($focusedField, equals: .location)
			.onSubmit {
				focusedField = nil
			}
			
			Spacer(minLength: 10)
			
			//Footer buttons
			HStack(spacing: 16) {
				//Cancel
				AppButton(.cancel, style: .secondary) {
					dismiss()
				}
				
				//Save
				AppButton(.save) {
					saveEvent()
				}
			}
		}
		.padding(Constant.UI.defaultPadding)
		.appBackground()
		.navigationBarTitleDisplayMode(.inline)
		.navigationAppTitle(title: "Edit \(eventData?.gaitType?.label ?? "")")
		.onChange(of: focusedField) { oldField, newField in
			focusedField = newField
		}
	}
	
	// MARK: - Methods
	private func saveEvent() {
		if validateEventDetails() {
			//Update data using two way binding
			eventData?.title = eventName
			eventData?.location = location
			
			//Close screen
			dismiss()
		}
	}
	
	// MARK: - Validation
	func validateEventDetails() -> Bool {
		if eventName.trimmingCharacters(in: .whitespaces).isEmpty {
			DispatchQueue.main.async {
				self.focusedField = .eventName
			}
			ToastManager.shared.present(.warning(String(localized: .eventNameIsRequired)))
			return false
		}
		
		if location.trimmingCharacters(in: .whitespaces).isEmpty {
			DispatchQueue.main.async {
				self.focusedField = .location
			}
			ToastManager.shared.present(.warning(String(localized: .locationIsRequired)))
			return false
		}
		
		focusedField = nil
		return true
	}

}
