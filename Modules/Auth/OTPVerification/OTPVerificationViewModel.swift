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

    // MARK: - Properties
    let phoneNumber: String
    var verificationID: String

    // MARK: - State
    var otp: String = ""
    var isVerifyingOTP: Bool = false
    var resendSecondsRemaining: Int
    var isResendAvailable: Bool = false

    // MARK: - Config
    let resendCountdownStart: Int
    let otpLength: Int

    // MARK: - Derived
    var isOTPComplete: Bool { otp.count == otpLength }

    // MARK: - Timer
    private let baseTimer: Timer.TimerPublisher
    private var timerSink: AnyCancellable?
    private var timerConnection: Cancellable?

    // MARK: - Routing callback
    var onOTPVerified: (() -> Void)?

    // MARK: - Init
    init(phoneNumber: String, verificationID: String, resendCountdownStart: Int = 60, otpLength: Int = 6) {
        self.phoneNumber = phoneNumber
        self.verificationID = verificationID
        self.resendCountdownStart = resendCountdownStart
        self.otpLength = otpLength
        self.resendSecondsRemaining = resendCountdownStart
        self.baseTimer = Timer.publish(every: 1, on: .main, in: .common)
    }

    deinit { stopResendTimer() }

    // MARK: - Lifecycle hooks
    func onAppear()    { startResendTimer() }
    func onDisappear() { stopResendTimer() }

    // MARK: - Timer Control
    func startResendTimer() {
        resendSecondsRemaining = resendCountdownStart
        isResendAvailable = false
        stopResendTimer()
        timerSink = baseTimer.sink { [weak self] _ in self?.handleTimerTick() }
        timerConnection = baseTimer.connect()
    }

    func stopResendTimer() {
        timerSink?.cancel();      timerSink = nil
        timerConnection?.cancel(); timerConnection = nil
    }

    private func handleTimerTick() {
        guard !isResendAvailable else { return }
        if resendSecondsRemaining > 0 { resendSecondsRemaining -= 1 }
        if resendSecondsRemaining == 0 {
            isResendAvailable = true
            stopResendTimer()
        }
    }

    // MARK: - Resend OTP
    //
    // Re-triggers the Firebase phone verification using the stored phone number.
    func triggerResend() {
        guard isResendAvailable else { return }

        Task { @MainActor in
            guard !phoneNumber.isEmpty else {
                ToastManager.shared.present(.error("Phone number not found. Please go back and try again."))
                return
            }

            do {
                // Re-send the OTP — AuthManager returns the new verificationID.
                let newVerificationID = try await AuthManager.shared.sendOTP(phoneNumber: phoneNumber)
                self.verificationID = newVerificationID
                ToastManager.shared.present(.success("A new code has been sent."))
                startResendTimer()
            } catch {
                ToastManager.shared.present(.error(error.localizedDescription))
            }
        }
    }

    // MARK: - Verify OTP

    @MainActor
    func verifyOTPIfNeeded() {
        guard isOTPComplete, !isVerifyingOTP else { return }
        isVerifyingOTP = true

        Task { [weak self] in
            guard let self else { return }

            guard !self.verificationID.isEmpty else {
                await MainActor.run {
                    self.isVerifyingOTP = false
                    ToastManager.shared.present(.error("Session expired. Please go back and request a new code."))
                }
                return
            }

            do {
                let user = try await AuthManager.shared.verifyOTP(
                    verificationID: self.verificationID,
                    code: self.otp
                )
                
                // Fetch the user profile from Firestore so userDetails is ready before we route.
                _ = try? await AuthManager.shared.fetchUserProfileInfo(userId: user.uid)
                
                self.persistUserSession(userId: user.uid, phoneNumber: user.phoneNumber)

                await MainActor.run {
                    self.isVerifyingOTP = false
                    self.onOTPVerified?()
                }
            } catch {
                await MainActor.run {
                    self.isVerifyingOTP = false
                    // Clear the entered code so the user can retry cleanly.
                    self.otp = ""
                    ToastManager.shared.present(.error(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Session Persistence

    private func persistUserSession(userId: String, phoneNumber: String?) {
        var user = AuthManager.shared.userDetails ?? UserModel(uuid: userId)
        user.uuid = userId
        if let phone = phoneNumber { user.phoneNumber = phone }
        AuthManager.shared.userDetails = user
    }
}
