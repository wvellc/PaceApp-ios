//
//  SubscriptionDetailView.swift
//  PaceApp
//

import SwiftUI

/// Light plan-details dialog shown when a subscriber taps the "Subscribed" row.
/// Pace Pro header, the plan facts and renewal date, then a Close button.
struct SubscriptionDetailView: View {

	let planName: String
	let planPeriod: String
	let renewalDate: Date?
	let willRenew: Bool
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
			Text(planName)
				.font(.bold24)
				.foregroundStyle(.black)

			Divider().overlay(Color.black.opacity(0.12))

			VStack(spacing: 14) {
				detailRow(label: "Events", value: "Unlimited")
				detailRow(label: "Billing", value: planPeriod)
				if let renewalDate {
					detailRow(label: willRenew ? "Next Renewal" : "Expires On", value: formatted(renewalDate))
				}
			}

			// Close (bordered).
			Button(action: onClose) {
				Text("Close")
					.font(.semiBold14)
					.foregroundStyle(.black)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 12)
					.overlay(Capsule().strokeBorder(Color.black.opacity(0.25), lineWidth: 1))
			}
		}
		.padding(24)
		.background(.white, in: RoundedRectangle(cornerRadius: 20))
	}

	// MARK: - Helpers

	private func detailRow(label: String, value: String) -> some View {
		HStack {
			Text(label)
				.font(.medium14)
				.foregroundStyle(.black.opacity(0.6))
			Spacer()
			Text(value)
				.font(.semiBold16)
				.foregroundStyle(.black)
		}
	}

	private func formatted(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM d, yyyy"
		return formatter.string(from: date)
	}
}
