//
//  OTPVerificationScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/18/26.
//

import SwiftUI
import Combine

/// OTP verification screen
struct OTPVerificationScreen: View {
	@Environment(Router.self) private var router
	@FocusState private var isOTPFieldFocused: Bool

	@State private var viewModel: OTPVerificationViewModel

	init(phoneNumber: String, verificationID: String) {
		_viewModel = State(initialValue: OTPVerificationViewModel(
			phoneNumber: phoneNumber,
			verificationID: verificationID,
			resendCountdownStart: 60,
			otpLength: Constant.Config.OTPLength
		))
	}

	var body: some View {
		VStack {
			VSpace(height: 32)

			Text(.enter6DigitVerificationCodeSentToYourPhoneNumber)
				.font(.medium20)
				.foregroundColor(.whiteApp)
				.multilineTextAlignment(.leading)
				.lineSpacing(12)

			HStack {
				Spacer()
				
				VSpace(height: 38)
				
				Spacer()
			}

			// OTP field — dimmed and non-interactive while verifying
			OTPFieldView(numberOfFields: Constant.Config.OTPLength, otp: $viewModel.otp)
				.focused($isOTPFieldFocused)
				.disabled(viewModel.isVerifyingOTP)
				.opacity(viewModel.isVerifyingOTP ? 0.4 : 1)
				.onChange(of: viewModel.otp) { _, newOtp in
					if newOtp.count >= Constant.Config.OTPLength {
						isOTPFieldFocused = false
						viewModel.verifyOTPIfNeeded()
					}
				}

			VSpace(height: 20)

			// Verifying indicator — sits right below the OTP field
			// so the user knows their code is being checked
			if viewModel.isVerifyingOTP {
				HStack(spacing: 8) {
					Spacer()
					
					ProgressView()
						.progressViewStyle(.circular)
						.tint(.whiteApp)
						.scaleEffect(0.85)
					Text(.verifying)
						.font(.medium14)
						.foregroundStyle(.whiteApp.opacity(0.8))
					
					Spacer()
				}
				.transition(.opacity.combined(with: .scale(scale: 0.9)))
			} else {
				Color.clear.frame(height: 20) // stable height placeholder
			}

			VSpace(height: 16)

			// Resend area
			Group {
				if viewModel.isResending {
					// Sending state
					HStack(spacing: 8) {
						ProgressView()
							.progressViewStyle(.circular)
							.tint(.neonAquaBlue)
							.scaleEffect(0.85)
						Text(.sendingNewCode)
							.font(.semiBold14)
							.foregroundStyle(.neonAquaBlue.opacity(0.8))
					}
				} else if viewModel.isResendAvailable {
					// Resend button
					Button {
						viewModel.triggerResend()
					} label: {
						Text(.resendCode)
							.foregroundStyle(.neonAquaBlue)
							.font(.semiBold14)
					}
					.disabled(viewModel.isVerifyingOTP)
					
				} else {
					// Countdown
					Text("\(String(localized: .didntReceiveOtpResendOtpIn)) \(Text(formattedTime(viewModel.resendSecondsRemaining)).foregroundStyle(.whiteApp).font(.semiBold16))")
						.foregroundStyle(.whiteApp.opacity(0.8))
						.font(.semiBold14)
				}
			}
			.animation(.easeInOut(duration: 0.2), value: viewModel.isResending)
			.animation(.easeInOut(duration: 0.2), value: viewModel.isResendAvailable)

			VSpace(height: 34)

			Spacer(minLength: Constant.UI.defaultPadding)
		}
		.safeAreaPadding(Constant.UI.defaultPadding)
		.appBackground()
		.animation(.easeInOut(duration: 0.25), value: viewModel.isVerifyingOTP)
		.onAppear {
			Task { @MainActor in
				try? await Task.sleep(seconds: 0.1)
				isOTPFieldFocused = true
			}

			viewModel.onOTPVerified = {
				isOTPFieldFocused = false
				Router.shared.setupRootNavigation()
			}

			viewModel.onAppear()
		}
		.onDisappear {
			isOTPFieldFocused = false
			viewModel.onDisappear()
		}
	}

	// MARK: - Helpers
	private func formattedTime(_ seconds: Int) -> String {
		let m = seconds / 60
		let s = seconds % 60
		return String(format: "%02d:%02d", m, s)
	}
}

#Preview {
	OTPVerificationScreen(phoneNumber: "+15555555555", verificationID: "mock_verification_id")
		.environment(Router())
}
