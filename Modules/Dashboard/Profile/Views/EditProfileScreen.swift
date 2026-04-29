//
//  EditProfileScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/24/26.
//

import SwiftUI
import PhotosUI

struct EditProfileScreen: View {
	
	@Environment(Router.self) private var router
	@FocusState private var focusedField: Field?
	
	private enum Field {
		case firstName
		case lastName
	}

	// Shared ProfileViewModel passed from ProfileScreen
	@Environment(ProfileViewModel.self) var viewModel
	
	// or @EnvironmentObject var viewModel: ProfileViewModel
	// MARK: - Local edit state
	@State private var firstName: String = ""
	@State private var lastName: String = ""
	@State private var selectedPhotoItem: PhotosPickerItem? = nil
	@State private var selectedImage: UIImage? = nil
	@State private var isPhotoPickerPresented: Bool = false
	
	var body: some View {
		VStack(spacing: 0) {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 32) {
					
					// MARK: Avatar
					avatarSection
					
					// MARK: Input Fields
					inputSection
					
					Spacer(minLength: 20)
				}
				.padding(.horizontal, 20)
				.padding(.top, 24)
			}
			
			// MARK: Update Profile Button
			updateButton
				.padding(.horizontal, 20)
				.padding(.bottom, 36)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.appBackground()
		.navigationTitle("Edit Profile")
		.onAppear {
			// Populate local state from viewModel
			firstName = viewModel.firstName ?? ""
			lastName = viewModel.lastName ?? ""
		}
		.photosPicker(
			isPresented: $isPhotoPickerPresented,
			selection: $selectedPhotoItem,
			matching: .images
		)
		.onChange(of: selectedPhotoItem) { _, newItem in
			Task {
				if let data = try? await newItem?.loadTransferable(type: Data.self),
				   let uiImage = UIImage(data: data) {
					selectedImage = uiImage
				}
			}
		}
	}
	
	
	// MARK: - Avatar Section
	
	@ViewBuilder
	private var avatarSection: some View {
		let avatarShape = ProfilePhotoShape()
		
		VStack(spacing: 10) {
			ZStack(alignment: .bottomTrailing) {
				// Avatar image
				Group {
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
								.fill(Color.white.opacity(0.1))
								.frame(width: 100, height: 108)
								.overlay {
									ProgressView().tint(.white)
								}
						}
					}
				}
				.overlay {
					// Dim overlay on avatar
					avatarShape
						.fill(Color.black.opacity(0.35))
						.frame(width: 100, height: 108)
				}
				
				// Camera badge
				Button(action: {
					isPhotoPickerPresented = true
				}, label: {
					Circle()
						.fill(
							LinearGradient(
								colors: [Color(hex: "#4D9FFF"), Color(hex: "#1A6FE0")],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 32, height: 32)
						.overlay {
							Image(systemName: "camera.fill")
								.font(.system(size: 14))
								.foregroundStyle(.white)
						}
						.shadow(color: Color(hex: "#1A6FE0").opacity(0.5), radius: 6, x: 0, y: 3)
				})
				.offset(x: 4, y: 4)
			}
			.onTapGesture {
				isPhotoPickerPresented = true
			}
			
			Text("Update Photo")
				.font(.medium14)
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
		
		AppButton("Update Profile") {
			viewModel.updateProfile(
				firstName: firstName,
				lastName: lastName,
				selectedImage: selectedImage
			)
			router.navigateBack()
		}
	}
}

// MARK: - Preview

#Preview {
	
	@Previewable @Environment(ProfileViewModel.self) var viewModel

	
	EditProfileScreen()
		.environment(Router())
}

