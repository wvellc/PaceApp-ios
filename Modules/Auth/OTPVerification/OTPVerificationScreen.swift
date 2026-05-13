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

	@State private var viewModel = OTPVerificationViewModel(
		resendCountdownStart: 60,
		otpLength: Constant.Config.OTPLength
	)

	var body: some View {
		VStack {
			VSpace(height: 32)

			Text(.enter6DigitVerificationCodeSentToYourPhoneNumber)
				.font(.medium20)
				.foregroundColor(.whiteApp)
				.multilineTextAlignment(.leading)
				.lineSpacing(12)

			VSpace(height: 38)

			OTPFieldView(numberOfFields: Constant.Config.OTPLength, otp: $viewModel.otp)
				.focused($isOTPFieldFocused)
				.onChange(of: viewModel.otp) { oldOtp, newOtp in
					if newOtp.count >= Constant.Config.OTPLength {
						isOTPFieldFocused = false
						viewModel.verifyOTPIfNeeded()
					}
				}

			VSpace(height: 24)

			Group {
				if viewModel.isResendAvailable {
					Button {
						viewModel.triggerResend()
					} label: {
						Text(.resendCode)
							.foregroundStyle(.neonAquaBlue)
							.font(.semiBold14)
					}
				} else {
					Text("\(String(localized: .didntReceiveOtpResendOtpIn)) \(Text(formattedTime(viewModel.resendSecondsRemaining)).foregroundStyle(.whiteApp).font(.semiBold16))")
						.foregroundStyle(.whiteApp.opacity(0.8))
						.font(.semiBold14)

				}
			}

			VSpace(height: 34)

			AppButton(.next) {
				viewModel.verifyOTPIfNeeded()
			}
			.setDisabled(!(viewModel.isOTPComplete) || viewModel.isVerifyingOTP)
			.ignoresSafeArea(.keyboard, edges: .bottom)

			Spacer(minLength: Constant.UI.defaultPadding)
		}
		.safeAreaPadding(Constant.UI.defaultPadding)
		.appBackground()
		.onAppear {
			Task { @MainActor in
				try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
				isOTPFieldFocused = true
			}
			
			viewModel.onOTPVerified = { [weak router] in
				// 1. Create a transaction
				var transaction = Transaction()
				
				// 2. Attach the completion handler
				// This block executes on the Main Thread automatically
				transaction.addAnimationCompletion {
					router?.setRoot(.accountCreation)
				}
				
				// 3. Execute the state change within that transaction
				withTransaction(transaction) {
					isOTPFieldFocused = false
				}
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
	OTPVerificationScreen()
		.environment(Router())
}
