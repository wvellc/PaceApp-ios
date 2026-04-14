//
//  ToastContainerView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import SwiftUI

enum GaitType: String, CaseIterable, Identifiable {
	case walking = "Walking"
	case running = "Running"
	var id: String { rawValue }
}

struct SetGaitStepView: View {
	@Bindable var viewModel: CreateAccountViewModel
	
	
	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			Text(.setYourWalkingStyleToMatchYourPaceAndMood)
				.font(.medium20)
				.foregroundColor(.whiteApp)
				.lineSpacing(10)
				.multilineTextAlignment(.leading)
			
			Spacer()
			
			Picker(.gait, selection: $viewModel.selectedGait) {
				ForEach(GaitType.allCases) { gait in
					Text(gait.rawValue)
						.font(.medium14)
						.tag(gait)
				}
			}
			.pickerStyle(.segmented)
			.tint(.radiantBlue)
			
			VStack(spacing: 18) {
				// Units picker styled as dropdown
				HStack {
					Text($viewModel.selectedUnit.wrappedValue)
						.font(.medium18)
						.foregroundColor(.whiteApp)
					Spacer()
					Image(.icDownArrow)
						.frame(width: 24, height: 24)
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 14)
				.frame(maxWidth: .infinity)
				.cardBackground(stroke: .whiteApp, bg: .clear)
				.overlay(
					Menu {
						ForEach($viewModel.units, id: \.self) { type in
							Button {
								viewModel.selectedUnit = type.wrappedValue
							} label: {
								Text(type.wrappedValue)
									.font(.medium18)
									.tag(type.wrappedValue)
							}
						}
					} label: {
						Color.white.opacity(0.001)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
					}
				)
				
				// Step length picker styled as dropdown
				// Lenth Value Picker
				HStack(spacing: 0) {
					// --- Integer Picker ---
					Picker("Integer Part", selection: Binding(
						get: { Int(viewModel.selectedStepLength) },
						set: { newValue in
							let fractionalPart = viewModel.selectedStepLength.truncatingRemainder(dividingBy: 1)
							viewModel.selectedStepLength = Double(newValue) + fractionalPart
						}
					)) {
						ForEach(0...9, id: \.self) { intVal in
							// Shows 01, 02... or 100, 101...
							Text(intVal < 100 ? String(format: "%02d", intVal) : "\(intVal)")
								.tag(intVal)
								.font(.medium18)
								.foregroundStyle(.whiteApp)

						}
					}
					.pickerStyle(.wheel)
					.frame(maxWidth: .infinity)
					.frame(height: 100)
					.clipped()
					
					Text(".")
						.font(.bold24)
						.baselineOffset(5) // Adjusts visual alignment of the dot
						.foregroundStyle(.whiteApp)

					
					// --- Fractional Picker ---
					Picker("Fractional Part", selection: Binding(
						get: {
							// Use rounded() to avoid 0.999999 precision issues
							Int((viewModel.selectedStepLength.truncatingRemainder(dividingBy: 1) * 100).rounded())
						},
						set: { newValue in
							let integerPart = floor(viewModel.selectedStepLength)
							viewModel.selectedStepLength = integerPart + (Double(newValue) / 100.0)
						}
					)) {
						ForEach(0...9, id: \.self) { frac in
							Text(String(format: "%d", frac))
								.tag(frac)
								.font(.medium18)
								.foregroundStyle(.whiteApp)
						}
					}
					.pickerStyle(.wheel)
					.frame(maxWidth: .infinity)
					.frame(height: 100)
					.clipped()
				}
				.foregroundStyle(.darkCharcoal)
				.padding(.horizontal, 16)
				.padding(.vertical, 14)
				.frame(maxWidth: .infinity)
				.cardBackground(stroke: .whiteApp, bg: .clear)
				
			}
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.top, 24)
	}
}

#Preview {
	SetGaitStepView(viewModel: CreateAccountViewModel())
		.appBackground()
}
