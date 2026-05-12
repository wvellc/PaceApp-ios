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
    @State private var isKeyboardVisible: Bool = false
	
	//MARK: Field enum
    private enum Field {
        case firstName
        case lastName
    }

	//MARK: View Builder
    var body: some View {
        VStack {

			VSpace(height: 60)
			
            Group {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 135.55, height: 90.59)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
                    .opacity(isKeyboardVisible ? 0 : 1)
                    .scaleEffect(isKeyboardVisible ? 0.95 : 1)
            }
            .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
			.safeAreaPadding()
		
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
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
				isKeyboardVisible = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
				isKeyboardVisible = false
            }
        }
		.onDisappear {
            focusedField = nil
			NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        .onChange(of: focusedField) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                isKeyboardVisible = newValue != nil
            }
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
