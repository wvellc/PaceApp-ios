//
//  AppTextField.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/16/26.
//

import SwiftUI

// MARK: - AppTextField

struct AppTextField: View {
	
	// MARK: - Property Wrappers
	@Binding private var text: String
	@State private var isValid: Bool = true
	@State private var hasInteracted: Bool = false
	
	// MARK: - Input Properties
	private var placeholder: LocalizedStringResource?
	private var validation: ValidationType?
	
	/// Optional leading icon view
	private var leadingView: AnyView?
	
	/// Optional trailing view
	private var trailingView: AnyView?
	
	private var textContentType: UITextContentType?
	private var keyboardType: UIKeyboardType
	private var autocapitalization: TextInputAutocapitalization
	
	private let onValueChanged: ((String) -> Void)?
	
	private var submitLabel: SubmitLabel
	private var bgColor: Color
	private var borderColor: Color
	private var foregroundStyle: Color
	
	// MARK: - Init (Binding<String>)
	init(
		text: Binding<String>,
		placeholder: LocalizedStringResource? = nil,
		validation: ValidationType? = nil,
		leadingView: AnyView? = nil,
		trailingView: AnyView? = nil,
		textContentType: UITextContentType? = .none,
		keyboardType: UIKeyboardType = .default,
		autocapitalization: TextInputAutocapitalization = .sentences,
		submitLabel: SubmitLabel = .next,
		bgColor: Color = .clear,
		borderColor: Color = .whiteApp,
		foregroundStyle: Color = .grayHint,
		onValueChanged: ((String) -> Void)? = nil,
	) {
		self._text = text
		self.placeholder = placeholder
		self.validation = validation
		self.leadingView = leadingView
		self.trailingView = trailingView
		self.textContentType = textContentType
		self.keyboardType = keyboardType
		self.autocapitalization = autocapitalization
		self.onValueChanged = onValueChanged
		self.submitLabel = submitLabel
		self.bgColor = bgColor
		self.borderColor = borderColor
		self.foregroundStyle = foregroundStyle
	}
	
	// MARK: - Computed
	private var getBorderColor: Color {
		if !isValid && hasInteracted {
			return Color.redBoho          // ← invalid: red border
		}
		return borderColor
	}
	
	// MARK: - Body
	
	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			
			// Field container
			HStack(alignment: .center, spacing: 8) {
				
				// Leading icon
				if let leadingView {
					leadingView
				}
				
				// Text input
				TextField(placeholder ?? "",
						  text: $text,
						  prompt: Text(placeholder ?? "")
					.foregroundStyle(.grayHint.opacity(0.8))
					.font(.medium18)
				)
				.font(.medium18)
				.keyboardType(keyboardType)
				.textContentType(textContentType)
				.textInputAutocapitalization(autocapitalization)
				.submitLabel(submitLabel)
				.autocorrectionDisabled(true)
				.foregroundStyle(foregroundStyle)
				.onChange(of: text) { _, newValue in
					hasInteracted = true
					isValid = newValue.trimmingCharacters(in: .whitespaces).isEmpty
					? true
					: ValidationProvider.isValid(
						text: newValue,
						type: validation ?? .none
					)
					onValueChanged?(newValue)
				}
				
				
				// Trailing icon
				if let trailingView {
					trailingView
				}
			}
			.padding(16)
			.background(
				// Border overlay
				RoundedRectangle(cornerRadius: Constant.UI.defaultCornerRadius)
					.fill(bgColor)
					.stroke(getBorderColor, lineWidth: 1.2)
			)
			.animation(.easeInOut(duration: 0.2), value: isValid)
			
			// Inline validation error message
			if !isValid && hasInteracted && validation?.validationMessage != nil {
				Text(validation!.validationMessage)
					.font(.regular17)
					.foregroundColor(.redBoho)
					.padding(.top, 4)
					.transition(.opacity.combined(with: .move(edge: .top)))
					.animation(.easeInOut(duration: 0.5), value: isValid)
			}
		}
	}
}



// MARK: - Preview

#Preview {
	PreviewWrapper()
}

private struct PreviewWrapper: View {
	@State private var firstName = ""
	@State private var email = ""
	@State private var password = ""
	@State private var confirmPw = ""
	@State private var phone = ""
	@State private var search = ""
	@State private var isSecure = true
	
	var body: some View {
		ZStack {
			Color(red: 0.08, green: 0.14, blue: 0.36)
				.ignoresSafeArea()
			
			ScrollView {
				VStack(spacing: 16) {
					
					// Name field with leading person icon
					AppTextField(
						text: $firstName,
						placeholder: "First Name",
						validation: .name,
						leadingView: AnyView(
							Image(systemName: "person.fill")
								.foregroundColor(.gray)
						),
						textContentType: .givenName,
						autocapitalization: .words,
						onValueChanged: { _ in }
					)
					
					// Email field
					AppTextField(
						text: $email,
						placeholder: "Enter your email",
						validation: .email,
						leadingView: AnyView(
							Image(systemName: "envelope.fill")
								.foregroundColor(.gray)
						),
						textContentType: .emailAddress,
						keyboardType: .emailAddress,
						autocapitalization: .never,
						onValueChanged: { _ in }
					)
					
					// Phone field
					AppTextField(
						text: $phone,
						placeholder: "+91 00000 00000",
						validation: .phoneNumber,
						leadingView: AnyView(
							Image(systemName: "phone.fill")
								.foregroundColor(.gray)
						),
						textContentType: .telephoneNumber,
						keyboardType: .phonePad,
						autocapitalization: .never,
						onValueChanged: { _ in }
					)
					
					// Search bar with filter icon (no validation)
					AppTextField(
						text: $search,
						placeholder: "Search here...",
						leadingView: AnyView(
							Image(systemName: "magnifyingglass")
								.foregroundColor(.gray)
						),
						trailingView: AnyView(
							Button { /* filter action */ } label: {
								Image(systemName: "line.3.horizontal.decrease.circle.fill")
									.foregroundColor(.gray)
							}
						),
						onValueChanged: { _ in }
					)
				}
				.padding(24)
			}
		}
	}
}
