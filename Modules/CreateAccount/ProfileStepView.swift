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

    var body: some View {
        VStack(spacing: 0) {

            // Subtitle
            Text("Set up your account to track your pace, performance, and progress in real time.")
                .font(.medium18)
                .foregroundStyle(.whiteApp)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 40)

            // Avatar picker
            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                avatarView
            }
            .onChange(of: viewModel.selectedPhotoItem) { _, _ in
                Task { await viewModel.loadPhoto() }
            }
            .padding(.bottom, 32)

            // Name fields
            VStack(spacing: 16) {
                AppTextField(
                    text: $viewModel.firstName,
                    placeholder: "First Name",
                    leadingView: AnyView(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.grayHint)
                    ),
                    textContentType: .givenName,
                    autocapitalization: .words
                )

                AppTextField(
                    text: $viewModel.lastName,
                    placeholder: "Last Name",
                    leadingView: AnyView(
                        Image(systemName: "person.fill")
                            .foregroundStyle(.grayHint)
                    ),
                    textContentType: .familyName,
                    autocapitalization: .words
                )
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    // MARK: - Avatar well

    @ViewBuilder
    private var avatarView: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image = viewModel.profileImage {
                    // Show selected photo
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else {
                    // Placeholder icon
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.blue)
                        )
                }
            }

            Text("Add Photo")
                .font(.medium16)
                .foregroundStyle(.whiteApp)
        }
    }
}
