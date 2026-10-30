//
//  SubscriptionDetailView.swift
//  PaceApp
//

import SwiftUI

/// Dark plan-details dialog shown when a subscriber taps the "Subscribed" row.
/// Mirrors the reference layout — Active Plan header, stat rows, renewal date —
/// in the app's theme, and keeps Manage Subscription reachable for cancelling.
struct SubscriptionDetailView: View {

	let planName: String
	let planPeriod: String
	let renewalDate: Date?
	let willRenew: Bool
	var onManage: () -> Void
	var onClose: () -> Void

	var body: some View {
		ZStack {
			// Dimmed backdrop — tap to dismiss.
			Color.black.opacity(0.6)
				.ignoresSafeArea()
				.onTapGesture { onClose() }

			card
				.padding(.horizontal, 32)
		}
	}

	// MARK: - Card

	private var card: some View {
		VStack(spacing: 20) {
			VStack(spacing: 6) {
				Text("Active Plan")
					.font(.medium14)
					.foregroundStyle(.white50)
				Text(planName)
					.font(.bold24)
					.foregroundStyle(.fluorescentMint)
			}

			Divider().overlay(Color.white.opacity(0.12))

			VStack(spacing: 14) {
				detailRow(label: "Events", value: "Unlimited")
				detailRow(label: "Billing", value: planPeriod)
				if let renewalDate {
					detailRow(label: willRenew ? "Next Renewal" : "Expires On", value: formatted(renewalDate))
				}
			}

			VStack(spacing: 12) {
				Button(action: onManage) {
					Text("Manage Subscription")
						.font(.semiBold14)
						.foregroundStyle(.whiteApp)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 12)
						.background(AppGradients.button)
						.clipShape(Capsule())
				}
				Button(action: onClose) {
					Text("Close")
						.font(.semiBold14)
						.foregroundStyle(.whiteApp)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 12)
						.overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
				}
			}
		}
		.padding(24)
		.background(.darkSeaBlue, in: RoundedRectangle(cornerRadius: 20))
		.overlay(
			RoundedRectangle(cornerRadius: 20)
				.strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
		)
	}

	// MARK: - Helpers

	private func detailRow(label: String, value: String) -> some View {
		HStack {
			Text(label)
				.font(.medium14)
				.foregroundStyle(.white50)
			Spacer()
			Text(value)
				.font(.semiBold16)
				.foregroundStyle(.whiteApp)
		}
	}

	private func formatted(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM d, yyyy"
		return formatter.string(from: date)
	}
}
