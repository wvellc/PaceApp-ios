//
//  ProfileStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI
import PhotosUI


// MARK: - ProfileStepView

/// Step 1 — photo upload + first / last name entry.
struct ProfileStepView: View {

    @Bindable var viewModel: CreateAccountViewModel
    @FocusState private var focusedField: Field?
	@State private var isPhotoPickerPresented = false
	
    private enum Field {
        case firstName
        case lastName
    }

    var body: some View {
        VStack {

            // Subtitle
            Text("Set up your account to track your pace, performance, and progress in real time.")
				.font(.medium20)
                .foregroundStyle(.whiteApp)
				.lineSpacing(10)
                .frame(maxWidth: .infinity, alignment: .leading)

		
			VSpace(height: 32)
			
            // Avatar picker
		avatarView
			.imagePickerManager(isPresented: $isPhotoPickerPresented, selectedImage: $viewModel.selectedPhotoItem)
            .onChange(of: viewModel.selectedPhotoItem) { _, _ in
                Task { await viewModel.loadPhoto() }
            }
            
			VSpace(height: 42)

            // Name fields
            VStack(spacing: 16) {
                AppTextField(
                    text: $viewModel.firstName,
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
                    text: $viewModel.lastName,
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

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
//		.onChange(of: viewModel.selectedPhotoItem) { oldValue, newValue in
//			if newValue != nil {
//				Task { await viewModel.loadPhoto() }
//			} else {
//				viewModel.profileImage = nil
//			}
//		}
		.onAppear {
			focusedField = .firstName
		}
		.onDisappear {
			focusedField = nil
		}

    }

    // MARK: - Avatar well

    @ViewBuilder
    private var avatarView: some View {
        let avatarShape = ProfilePhotoShape()

        VStack(spacing: 16) {
            ZStack {

                avatarShape
					.fill(.whiteApp)
                    .frame(width: 100, height: 108)
                    .overlay {
                        if let image = viewModel.profileImage {
                            image
                                .resizable()
                                .scaledToFill()
								.frame(width: 100, height: 108)
                                .clipShape(avatarShape)
                        } else {
							Image(.icCamera)
								.frame(width: 54, height: 54)
                        }
                    }
					.onTapGesture {
						isPhotoPickerPresented = true
					}

            }

			Text(.addPhoto)
                .font(.medium16)
				.foregroundStyle(.whiteApp)
        }
    }
}

#Preview {
	ProfileStepView(viewModel: CreateAccountViewModel())
		.appBackground()
}
