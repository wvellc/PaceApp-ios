//
//  EditProfileScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import SwiftUI

/// Edito profile screen
struct EditProfileScreen: View {
	
	@FocusState private var focusedField: Field?
	@Environment(\.dismiss) var dismiss
	
	private enum Field {
		case firstName
		case lastName
	}

	var viewModel: ProfileViewModel

	// MARK: - Local edit state
	@State private var firstName: String = ""
	@State private var lastName: String = ""

	var body: some View {
		VStack(spacing: 0) {
			VStack(spacing: 32) {
				
				// MARK: Input Fields
				inputSection
				
				Spacer(minLength: 20)
				
				// MARK: Update Profile Button
				updateButton
				
			}
			.padding(.horizontal, 20)
			.padding(.top, 24)
			.padding(.bottom, 36)
			
			
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.appBackground()
		.navigationTitle(.editProfile)
		.navigationBarTitleDisplayMode(.inline)
		.onAppear {
			// Populate local state from viewModel
			firstName = viewModel.firstName ?? ""
			lastName = viewModel.lastName ?? ""
		}
	}
	
	// MARK: - Input Section
	
	@ViewBuilder
	private var inputSection: some View {
		// Name fields
		VStack(spacing: 16) {
			AppTextField(
				text: $firstName,
				placeholder: .firstName,
				leadingView: AnyView(
					Image(.icPerson)
				),
				textContentType: .givenName,
				autocapitalization: .words,
				submitLabel: .next
			)
			.focused($focusedField, equals: .firstName)
			.onSubmit {
				focusedField = .lastName
			}
			
			AppTextField(
				text: $lastName,
				placeholder: .lastName,
				leadingView: AnyView(
					Image(.icPerson)
				),
				textContentType: .familyName,
				autocapitalization: .words,
				submitLabel: .done
			)
			.focused($focusedField, equals: .lastName)
			.onSubmit {
				focusedField = nil
			}
		}
	}
	
	// MARK: - Update Button
	
	@ViewBuilder
	private var updateButton: some View {
		
		AppButton(.updateProfile) {
			viewModel.updateProfile(
				firstName: firstName,
				lastName: lastName
			)
			
			dismiss()
		}
	}
}

// MARK: - Preview

#Preview {
	
	@Previewable @State var profileVM = ProfileViewModel()

	EditProfileScreen(viewModel: profileVM)
		.environment(Router())
		.environment(ProfileViewModel())
}
