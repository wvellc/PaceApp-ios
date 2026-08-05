//
//  LoginScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

import SwiftUI
import CountryPicker

///Login screen (Email + Phone )
struct LoginScreen: View {
	
	//MARK: Environment
	@Environment(Router.self) private var router
	
	
	//MARK: States
	@State private var viewModel = LoginViewModel()
	@State private var showSafari = false
	@State private var legalURL: URL? = nil
	/// Prevents duplicate navigation pushes when reCAPTCHA completes and
	/// the onChange fires while the NavigationStack is still animating.
	@State private var hasNavigatedToOTP = false
	
	//Focus state
	@FocusState private var focus : LoginType?
	
	//Contry picker
	@State private var showPicker = false
	
	
	//MARK: Body
	var body: some View {
		BackgroundContainer {
			VStack(spacing: 0) {
				
				// Logo Section
				VStack {
					VSpace(height: 107)
					LogoWithText()
					VSpace(height: 111)
				}
				
				// Login Form Container
				VStack(alignment: .center, spacing: 24) {
					
					Text(.loginToYourAccount)
						.font(.medium20)
						.foregroundColor(.whiteApp)
					
					// Segment Toggle
					AppSegmentedControl(
						selection: $viewModel.loginType,
						segments: [
							(key: .email, title:String(localized: .email)),
							(key: .phoneNumber, title: String(localized: .phoneNumber))
						]
					)
					
					// Input Fields
					if viewModel.loginType == .email {
						
						//Email
						AppTextField(
							text: $viewModel.email,
							placeholder: .emailAddress,
							validation: .email,
							keyboardType: .emailAddress,
							autocapitalization: .never,
							borderColor: .white20,
							onValueChanged: { newValue in
								viewModel.email = newValue
							}
						)
						.focused($focus, equals: .email)
						.onSubmit { viewModel.validate(focus: &focus) }
						
					} else {
						// Phone field
						
						HStack(alignment:.top,spacing: 12) {
							// Country Code Picker
							Button(action: {showPicker.toggle()}) {
								Text(viewModel.countryCode.dialingCode ?? "+1")
									.font(.medium18)
									.foregroundColor(.whiteApp)
								Image(.icArrowDown)
									.foregroundColor(.whiteApp)
									.font(.system(size: 14, weight: .medium))
							}
							.padding(16)
							.background(Color.clear)
							.overlay(
								RoundedRectangle(cornerRadius: Constant.UI.defaultCornerRadius)
									.stroke(.white20, lineWidth: 1.2)
							)
							
							AppTextField(
								text: $viewModel.phoneNumber,
								placeholder: .phoneNumberPlaceholder,
								validation: .phoneNumber,
								textContentType: .telephoneNumber,
								keyboardType: .phonePad,
								borderColor: .white20,
								onValueChanged: { newValue in
									viewModel.phoneNumber = newValue
								}
							)
							.focused($focus, equals: .phoneNumber)
							.onSubmit { viewModel.validate(focus: &focus) }
							
						}
					}
					
					// Send OTP / Send Link Button
					// Disabled and dimmed while a request is in-flight to prevent double-taps.
					AppButton(
						viewModel.state == .sending ? .sending : (
							viewModel.loginType == .email ? .sendLoginLink : .sendOtp
						)
					) {
						Task { await viewModel.sendOTP() }
					}
					.disabled(!viewModel.isInputValid || viewModel.state == .sending)
					.opacity(viewModel.isInputValid && viewModel.state != .sending ? 1 : 0.5)
					
								
					// Terms & Privacy
					VStack(spacing: 6) {
						Text(.byContinuingYouAgreeToOur)
							.font(.medium16)
							.foregroundColor(.grayHint)
							.multilineTextAlignment(.center)
						
						HStack(spacing: 6) {
							Button(action: viewModel.openTermsOfService) {
								Text(.termsOfService)
									.font(.semiBold16)
									.foregroundColor(.whiteApp)
							}
							Text(.and)
								.font(.medium16)
								.foregroundColor(.grayHint)
							Button(action: viewModel.openPrivacyPolicy) {
								Text(.privacyPolicy)
									.font(.semiBold16)
									.foregroundColor(.whiteApp)
							}
						}
					}
					.padding(.bottom, 24 + 16)
				}
				.padding(.horizontal, 16)
				
				Spacer()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
		// Handles ALL navigation — ViewModel just fires events
		.onChange(of: viewModel.navigationEvent) { _, event in
			guard let event else { return }
			// Clear the event FIRST — before any async work — so a second
			// onChange firing (e.g. reCAPTCHA return path) doesn't double-navigate.
			viewModel.navigationEvent = nil
			handleNavigation(event)
		}
		.onChange(of: viewModel.loginType) { oldValue, newValue in
			// Reset the OTP navigation guard when the user switches login type.
			hasNavigatedToOTP = false
			focus = newValue
		}
		.sheet(isPresented: $showPicker) {
			CountryPickerView(
				configuration: Configuration(
					flagStyle: .circular,
					labelFont: .medium16,
					labelColor: .blackApp,
					detailFont: .regular17,
					detailColor: .blackApp,
					navigationTitleText: "Pick a country code",
				),
				selectedCountry: Binding<Country?>(
					get: { viewModel.countryCode },
					set: { newValue in
						if let country = newValue {
							viewModel.countryCode = country
							showPicker = false
						}
					}
				)
			)
			.foregroundStyle(.blackApp)
			.tint(.black)
		}
		.onAppear {
			// Reset navigation guard each time this screen becomes visible
			// (e.g. user pops back from OTP or reCAPTCHA returns mid-flow).
			hasNavigatedToOTP = false
			viewModel.navigationEvent = nil
			viewModel.state = .idle
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
				focus = viewModel.loginType
			}
			
			#if kDebug
			viewModel.phoneNumber = "9898989898"
			viewModel.email = "wvedeveloper@gmail.com"
			#endif
			
		}
		.onDisappear {
			focus = nil
		}
		
	}
	
	// MARK: - Navigation handler (all in one place, easy to read)
	private func handleNavigation(_ event: LoginViewModel.NavigationEvent) {
		switch event {
			case .privacyPolicy    : router.navigate(to: .privacyPolicy)
			case .tearmsOfService  : router.navigate(to: .termsOfService)
			case .sendOTP:
				// Guard prevents a duplicate push if the onChange fires a second time
				// while the NavigationStack is mid-animation (reCAPTCHA return race).
				guard !hasNavigatedToOTP else { return }
				if case .otpSent(let verificationID) = viewModel.state {
					hasNavigatedToOTP = true
					router.navigate(to: .verifyOTP(phoneNumber: viewModel.normalizedPhone(), verificationID: verificationID))
				}
		}
	}
}

#Preview {
	LoginScreen()
		.environment(Router())
	
}
