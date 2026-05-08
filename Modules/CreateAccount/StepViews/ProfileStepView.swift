//
//  ProfileStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI


// MARK: - ProfileStepView

/// Step 1 — first / last name + gender selection.
struct ProfileStepView: View {

	//MARK: States
    @Bindable var viewModel: CreateAccountViewModel
    @FocusState private var focusedField: Field?
	
	//MARK: Field enum
    private enum Field {
        case firstName
        case lastName
    }

	//MARK: View Builder
    var body: some View {
        VStack {

			VSpace(height: 60)
			
			Image("logo")
				.resizable()
				.scaledToFit()
				.frame(width: 135.55, height: 90.59)
				.shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
		
			VSpace(height: 60)

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
				
				
				
				genderSelectionView
					.padding(.top, 8)
            }

            Spacer()
        }
        .padding(.top, 24)
		.onAppear {
			focusedField = .firstName
		}
		.onDisappear {
			focusedField = nil
		}

    }

	// MARK: - Gender selection
	
	private var genderSelectionView: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(.gender)
				.font(.semiBold16)
				.foregroundStyle(.whiteApp)
			
			AppSegmentedControl(
				selection: $viewModel.selectedGender,
				segments: Gender.allCases.map {
					(key: $0, title: $0.rawValue)
				}
			)
		}
		.padding(.top, 8)
	}
}

#Preview {
	ProfileStepView(viewModel: CreateAccountViewModel())
		.appBackground()
}
