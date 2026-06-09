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
    var isResending: Bool = false
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
        guard isResendAvailable, !isResending else { return }

        Task { @MainActor in
            guard !phoneNumber.isEmpty else {
                ToastManager.shared.present(.error("Phone number not found. Please go back and try again."))
                return
            }

            isResending = true
            do {
                let newVerificationID = try await AuthManager.shared.sendOTP(phoneNumber: phoneNumber)
                self.verificationID = newVerificationID
                ToastManager.shared.present(.success("A new code has been sent."))
                startResendTimer()
            } catch {
                ToastManager.shared.present(.error(error.localizedDescription))
            }
            isResending = false
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
                self.isVerifyingOTP = false
                ToastManager.shared.present(.error("Session expired. Please go back and request a new code."))
                return
            }

            do {
                let user = try await AuthManager.shared.verifyOTP(
                    verificationID: self.verificationID,
                    code: self.otp
                )

                // The auth state listener in AuthManager fires immediately after
                // signIn and begins fetching the Firestore profile asynchronously.
                // We must wait for that fetch to complete before calling
                // setupRootNavigation() — otherwise userDetails is nil,
                // staticRoot() returns .auth, and the user sees LoginScreen flash.
                //
                // Wait up to 5 seconds for userDetails to be populated.
                // For a new user the listener creates a placeholder synchronously
                // (on 404), so this resolves almost instantly in practice.
                await self.waitForUserDetails(uid: user.uid)

                self.isVerifyingOTP = false
                self.onOTPVerified?()

            } catch {
                self.isVerifyingOTP = false
                self.otp = ""
                ToastManager.shared.present(.error(error.localizedDescription))
            }
        }
    }

    /// Polls AuthManager.shared.userDetails until it is set for the given uid,
    /// or until the timeout expires. Prevents routing before the auth listener
    /// has finished its Firestore profile fetch.
    private func waitForUserDetails(uid: String, timeoutSeconds: Double = 5) async {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if AuthManager.shared.userDetails?.uuid == uid {
                return
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        // Timeout — ensure at minimum a placeholder exists so routing works.
        if AuthManager.shared.userDetails == nil {
            var placeholder = UserModel(uuid: uid)
            if let phone = Auth.auth().currentUser?.phoneNumber {
                placeholder.phoneNumber = phone
            }
            AuthManager.shared.userDetails = placeholder
        }
    }
}
