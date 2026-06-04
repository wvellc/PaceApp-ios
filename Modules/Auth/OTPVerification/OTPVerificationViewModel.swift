//
//  OTPVerificationViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import Combine
import SwiftUI
import FirebaseAuth

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
        otp = ""
        startResendTimer()
        
        // Re-invoke Firebase to send a new SMS to the same phone number.
        guard let phoneNumber = AppSession.userDetails?.phoneNumber, !phoneNumber.isEmpty else { return }
        
        Task { @MainActor in
            do {
                let verificationID = try await AuthManager.shared.sendOTP(phoneNumber: phoneNumber)
                // Overwrite the old verification ID so the next verify attempt uses the latest code.
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            } catch {
                ToastManager.shared.present(.error(error.localizedDescription))
            }
        }
    }

    @MainActor
    func verifyOTPIfNeeded() {
        guard isOTPComplete, !isVerifyingOTP else { return }
        isVerifyingOTP = true

        Task { [weak self] in
            do {
                guard let self = self else { return }
                guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
                    throw NSError(
                        domain: "OTPVerificationViewModel",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Verification ID not found. Please try sending OTP again."]
                    )
                }
                
                let user = try await AuthManager.shared.verifyOTP(verificationID: verificationID, code: self.otp)
                
                self.persistUserSession(userId: user.uid, phoneNumber: user.phoneNumber)
                
                await MainActor.run {
                    self.isVerifyingOTP = false
                    self.onOTPVerified?()
                }
            } catch {
                await MainActor.run {
                    self?.isVerifyingOTP = false
                    ToastManager.shared.present(.error(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Session Persistence

    /// Persists user session on successful verification.
    private func persistUserSession(userId: String, phoneNumber: String?) {
        var user = AppSession.userDetails
        if user == nil {
            user = UserModel(uuid: userId)
        } else {
            user?.uuid = userId
        }
        if let phone = phoneNumber {
            user?.phoneNumber = phone
        }
        AppSession.userDetails = user
        AppSession.userId = userId
        AppSession.isUserAuthenticated = true
    }
	
}
