//
//  OTPVerificationScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import Combine
import SwiftUI

@Observable
final class OTPVerificationViewModel {
    // MARK: - Published State
    var otp: String = ""
    var isVerifyingOTP: Bool = false
    var resendSecondsRemaining: Int
    var isResendAvailable: Bool = false
	

    // MARK: - Config
    let resendCountdownStart: Int
    let otpLength: Int

    // MARK: - Derived
    var isOTPComplete: Bool { otp.count == otpLength }

    // MARK: - Timer (manual connect)
    private let baseTimer: Timer.TimerPublisher
    private var timerSink: AnyCancellable?
    private var timerConnection: Cancellable?

    // MARK: - Routing callback
    var onOTPVerified: (() -> Void)?

    // MARK: - Initializer
    init(resendCountdownStart: Int = 60, otpLength: Int = 6) {
        self.resendCountdownStart = resendCountdownStart
        self.otpLength = otpLength
        self.resendSecondsRemaining = resendCountdownStart
        self.baseTimer = Timer.publish(every: 1, on: .main, in: .common)
    }

	//MARK: DeInitializer
	deinit {
		stopResendTimer()
	}

    // MARK: - Lifecycle hooks
    func onAppear() {
        startResendTimer()
    }

    func onDisappear() {
        stopResendTimer()
    }

    // MARK: - Timer Control
    func startResendTimer() {
        resendSecondsRemaining = resendCountdownStart
        isResendAvailable = false

        stopResendTimer()

        timerSink = baseTimer
            .sink { [weak self] _ in
                self?.handleTimerTick()
            }

        timerConnection = baseTimer.connect()
    }

    func stopResendTimer() {
        timerSink?.cancel()
        timerSink = nil
        timerConnection?.cancel()
        timerConnection = nil
    }

    private func handleTimerTick() {
        guard !isResendAvailable else { return }

        if resendSecondsRemaining > 0 {
            resendSecondsRemaining -= 1
        }

        if resendSecondsRemaining == 0 {
            isResendAvailable = true
            stopResendTimer()
        }
    }

    // MARK: - Actions
    func triggerResend() {
        // TODO: Call resend API
        startResendTimer()
    }

    @MainActor
    func verifyOTPIfNeeded() {
        guard isOTPComplete, !isVerifyingOTP else { return }


        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(550))
            await MainActor.run {
                guard let self else { return }
                self.isVerifyingOTP = false
                self.onOTPVerified?()
            }
        }
    }
	
}
