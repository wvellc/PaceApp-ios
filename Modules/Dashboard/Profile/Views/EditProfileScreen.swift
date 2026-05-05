//
//  EditProfileScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import SwiftUI
import PhotosUI

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
	@State private var selectedImage: UIImage? = nil
	@State private var isPhotoPickerPresented: Bool = false
	@State private var profileImage: UIImage? = nil

	var body: some View {
		VStack(spacing: 0) {
			VStack(spacing: 32) {
				
				// MARK: Avatar
				avatarSection
				
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
		.onChange(of: profileImage) { _, newValue in
			if let image = newValue {
				self.selectedImage = image
			} else {
				self.selectedImage = UIImage(resource: .icPerson)
			}
		}
	}
	
	
	// MARK: - Avatar Section
	
	@ViewBuilder
	private var avatarSection: some View {
		let avatarShape = ProfilePhotoShape()
		
		VStack(spacing: 16) {
			ZStack(alignment: .bottomTrailing) {
				// Avatar image
				
				Color.whiteApp
					.overlay {
						ZStack {
							if let localImage = selectedImage {
								Image(uiImage: localImage)
									.resizable()
									.scaledToFill()
									.frame(width: 100, height: 108)
									.clipShape(avatarShape)
							} else {
								AsyncImage(url: URL(string: viewModel.avatarURL)) { image in
									image
										.resizable()
										.scaledToFill()
										.frame(width: 100, height: 108)
										.clipShape(avatarShape)
									
								} placeholder: {
									avatarShape
										.fill(.whiteApp)
										.frame(width: 100, height: 108)
										.overlay {
											Image(.icProfile)
												.resizable()
												.renderingMode(.template)
												.foregroundStyle(.grayHint)
												.scaledToFill()
												.frame(width: 60, height: 60)
										}
								}
							}
							
							Color.blackApp.opacity(0.7)
								.overlay {
									Image(.icCamera)
								}
						}

					}
					.frame(width: 100, height: 108)
					.clipShape(avatarShape)
					.imagePickerManager(isPresented: $isPhotoPickerPresented, selectedImage: $profileImage)

				
			}
			.onTapGesture {
				isPhotoPickerPresented = true
			}
			
			Text(.updatePhoto)
				.font(.medium16)
				.foregroundStyle(.whiteApp)
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
				lastName: lastName,
				selectedImage: selectedImage
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

