//
//  ReauthDeleteSheets.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/9/26.
//

import SwiftUI

// MARK: - ReauthOTPSheet
//
// Phone re-authentication before account deletion — the user enters the OTP sent to
// their own signed-in number. Verifying does NOT sign them out.

struct ReauthOTPSheet: View {

	let phone: String
	let verificationID: String
	let onVerified: () -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var otp = ""
	@State private var isVerifying = false

	var body: some View {
		VStack(spacing: 24) {
			VSpace(height: 16)

			Text("Confirm it's you")
				.font(.bold24)
				.foregroundStyle(.whiteApp)

			Text("Enter the code sent to \(phone) to permanently delete your account. This can't be undone.")
				.font(.medium16)
				.foregroundStyle(.white50)
				.multilineTextAlignment(.center)

			OTPFieldView(numberOfFields: 6, otp: $otp)
				.padding(.vertical, 8)

			AppButton("Verify & Delete") { verify() }
				.disabled(otp.count < 6 || isVerifying)
				.opacity(otp.count < 6 || isVerifying ? 0.6 : 1)

			Button("Cancel") { dismiss() }
				.font(.semiBold16)
				.foregroundStyle(.white50)

			Spacer()
		}
		.padding(24)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.appBackground()
		.overlay {
			if isVerifying {
				ZStack {
					Color.black.opacity(0.4).ignoresSafeArea()
					ProgressView().tint(.whiteApp).scaleEffect(1.4)
				}
			}
		}
	}

	private func verify() {
		guard otp.count == 6, !isVerifying else { return }
		isVerifying = true
		Task { @MainActor in
			do {
				try await AuthManager.shared.reauthenticateWithPhone(verificationID: verificationID, code: otp)
				isVerifying = false
				dismiss()
				onVerified()
			} catch {
				isVerifying = false
				otp = ""
				ToastManager.shared.present(.error(AuthErrorMapper.message(for: error)))
			}
		}
	}
}

// MARK: - EmailReauthWaitSheet
//
// Email re-authentication: the link was sent to the signed-in user's email. Deletion
// runs from the `onOpenURL` handler once they tap it; this sheet just waits.

struct EmailReauthWaitSheet: View {

	let email: String
	let onCancel: () -> Void

	var body: some View {
		VStack(spacing: 20) {
			VSpace(height: 24)

			ProgressView()
				.tint(.whiteApp)
				.scaleEffect(1.4)

			Text("Check your email")
				.font(.bold24)
				.foregroundStyle(.whiteApp)

			Text("We sent a confirmation link to \(email). Tap it to permanently delete your account.")
				.font(.medium16)
				.foregroundStyle(.white50)
				.multilineTextAlignment(.center)

			Button("Cancel") { onCancel() }
				.font(.semiBold16)
				.foregroundStyle(.white50)

			Spacer()
		}
		.padding(24)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.appBackground()
	}
}
