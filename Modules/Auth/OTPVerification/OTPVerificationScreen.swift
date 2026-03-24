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
	
	@State private var otp: String = ""
	@FocusState private var isOTPFieldFocused: Bool
	@State private var isVerifyingOTP: Bool = false
	
	// MARK: - Resend Timer State
	@State private var resendSecondsRemaining: Int = 60 * 2 // total seconds (2 min)
	@State private var isResendAvailable: Bool = false
	
	private let resendCountdownStart: Int = 60 * 2
	private var isOTPComplete: Bool { otp.count == Constant.Config.OTPLength }
	
	// Combine timer publisher (manual control, no autoconnect)
	private let resendTimer = Timer.publish(every: 1, on: .main, in: .common)
	
	// Hold cancellable reference to stop/start timer
	@State private var resendTimerCancellable: AnyCancellable?
	@State private var resendTimerConnection: Cancellable?
	
	var body: some View {
		
		VStack {
			VSpace(height: 32)
			
			Text(.enter6DigitVerificationCodeSentToYourPhoneNumber)
				.font(.medium20)
				.foregroundColor(.whiteApp)
				.multilineTextAlignment(.leading)
				.lineHeight(.loose)
			
			VSpace(height: 38)
			
			OTPFieldView(numberOfFields: Constant.Config.OTPLength, otp: $otp)
				.focused($isOTPFieldFocused)
				.onChange(of: otp) { _, newOtp in
					if newOtp.count == Constant.Config.OTPLength {
						isOTPFieldFocused = false
						verifyOTPIfNeeded()
					}
				}
			
			VSpace(height: 24)
			
			Group {
				if isResendAvailable {
					Button {
						triggerResend()
					} label: {
						Text(.resendCode)
							.foregroundStyle(.neonAquaBlue)
							.font(.semiBold14)
					}
				} else {
					Text("\(String(localized: .didntReceiveOtpResendOtpIn)) \(Text(formattedTime(resendSecondsRemaining)).foregroundStyle(.whiteApp).font(.semiBold16))")
						.foregroundStyle(.whiteApp.opacity(0.8))
						.font(.semiBold14)

				}
			}
			
			VSpace(height: 34)
			
			AppButton(.next) {
				verifyOTPIfNeeded()
			}
			.setDisabled(!isOTPComplete || isVerifyingOTP)
			.ignoresSafeArea(.keyboard, edges: .bottom)
			
			Spacer(minLength: Constant.UI.defaultPadding)
		}
		.safeAreaPadding(Constant.UI.defaultPadding)
		.appBackground()
		
		// MARK: - Lifecycle
		.onAppear {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self.isOTPFieldFocused = true
			}
			
			startResendTimer() // Start timer when screen appears
		}
		.onDisappear {
			stopResendTimer() // Clean up to avoid memory leaks
		}
	}
	
	// MARK: - Timer Control
	
	/// Starts the resend countdown timer
	private func startResendTimer() {
		resendSecondsRemaining = resendCountdownStart
		isResendAvailable = false
		
		// Cancel previous timer if exists
		stopResendTimer()
		
		// Subscribe to timer events
		resendTimerCancellable = resendTimer
			.sink { _ in
				handleTimerTick()
			}
		
		//IMPORTANT: Connect the timer
		resendTimerConnection = resendTimer.connect()
	}
	
	/// Stops the timer safely
	private func stopResendTimer() {
		resendTimerCancellable?.cancel()
		resendTimerCancellable = nil
	}
	
	/// Called every second
	private func handleTimerTick() {
		guard !isResendAvailable else { return }
		
		if resendSecondsRemaining > 0 {
			resendSecondsRemaining -= 1
		}
		
		if resendSecondsRemaining == 0 {
			isResendAvailable = true
			stopResendTimer() // Stop timer when done
		}
	}
	
	// MARK: - Actions
	
	private func triggerResend() {
		// TODO: Call resend API
		
		// Restart countdown
		startResendTimer()
	}
	
	private func verifyOTPIfNeeded() {
		guard isOTPComplete, !isVerifyingOTP else { return }
		
		// Dismiss the keyboard before starting verification
		isOTPFieldFocused = false
		isVerifyingOTP = true
		
		Task {
			// Temporary success delay until real OTP verification is wired
			try? await Task.sleep(for: .milliseconds(550))
			await MainActor.run {
				isVerifyingOTP = false
				router.navigate(to: .OTPVerified, fadeIn: true)
			}
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
