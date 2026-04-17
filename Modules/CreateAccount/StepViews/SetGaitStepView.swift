//
//  SetGaitStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import SwiftUI

// MARK: - Gait Type Enum

/// Represents the two supported gait modes: walking and running.
enum GaitType: String, CaseIterable, Identifiable {
	case walking = "Walking"
	case running = "Running"
	var id: String { rawValue }
}

// MARK: - Data Models

/// Top-level container holding gait data for both walking and running.
struct GaitUserData: Identifiable, Codable {
	var id = UUID()
	var walkingData: GaitData
	var runningData: GaitData
	
	enum CodingKeys: String, CodingKey {
		case id, walkingData, runningData
	}
}

/// Stores the step length and unit for a single gait type.
struct GaitData: Identifiable, Codable {
	var id = UUID()
	var stepLength: Double
	var unit: String  // e.g. "Meters" or "Feet"
	
	enum CodingKeys: String, CodingKey {
		case id, stepLength, unit
	}
}

// MARK: - Parent View

struct SetGaitStepView: View {
	@Bindable var viewModel: CreateAccountViewModel
	
	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			Text(.setYourWalkingStyleToMatchYourPaceAndMood)
				.font(.medium20)
				.foregroundColor(.whiteApp)
				.lineSpacing(10)
				.multilineTextAlignment(.leading)
			
			VStack(spacing: 24) {
				// Running gait selector — saves to AppSession on change
				GaitSelectionView(type: .running) { data in
					AppSession.userGaitData?.runningData = data
				}
				
				// Walking gait selector — saves to AppSession on change
				GaitSelectionView(type: .walking) { data in
					AppSession.userGaitData?.walkingData = data
				}
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

// MARK: - Gait Selection Card

/// A card that lets the user pick a unit (Meters/Feet) and step length
/// for a given gait type. Reads initial values from AppSession and
/// calls `onChange` whenever the user makes a selection.
struct GaitSelectionView: View {
	
	let type: GaitType
	let onChange: (GaitData) -> Void
	
	@State private var selectedUnit: String
	/// Single source of truth for the full step length value (e.g. 2.7).
	/// Both wheel pickers read from and write back to this property.
	@State private var selectedStepLength: Double
	
	let units = ["Meters", "Feet"]
	
	// MARK: Init
	
	init(type: GaitType, onChange: @escaping (GaitData) -> Void) {
		self.type = type
		self.onChange = onChange
		
		// Pull previously saved data for this gait type from AppSession
		let savedData: GaitData? = type == .running
		? AppSession.userGaitData?.runningData
		: AppSession.userGaitData?.walkingData
		
		// Fall back to sensible defaults if no saved data exists
		_selectedUnit = State(initialValue: savedData?.unit ?? "Meters")
		_selectedStepLength = State(initialValue: savedData?.stepLength ?? 2.0)
	}
	
	// MARK: Helpers
	
	/// Fires the onChange callback with the latest GaitData.
	private func notifyChange() {
		onChange(GaitData(stepLength: selectedStepLength, unit: selectedUnit))
	}
	
	// MARK: Body
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			
			// Section label e.g. "Walking" / "Running"
			Text(type.rawValue)
				.font(.semiBold17)
				.foregroundColor(.whiteApp)
			
			AppSegmentedControl(
				selection: $selectedUnit,
				segments: units.map { (key: $0, title: $0) }
			)
			.onChange(of: selectedUnit) { _, _ in
				notifyChange()
			}
			
			// MARK: Step Length Wheel Picker (integer . fractional)
			HStack(spacing: 0) {
				
				// --- Integer Picker (00–09) ---
				Picker("Integer Part", selection: Binding(
					get: { Int(selectedStepLength) },
					set: { newValue in
						// Preserve the fractional part when integer changes
						let fractionalPart = selectedStepLength.truncatingRemainder(dividingBy: 1)
						selectedStepLength = Double(newValue) + fractionalPart
						notifyChange()
					}
				)) {
					ForEach(0...9, id: \.self) { intVal in
						// Show two-digit format for values under 100 (e.g. 02, 07)
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
				
				// Decimal point separator
				Text(".")
					.font(.bold24)
					.baselineOffset(5) // Visually aligns dot to the centre of the picker digits
					.foregroundStyle(.whiteApp)
				
				// --- Fractional Picker (0–9) ---
				Picker("Fractional Part", selection: Binding(
					get: {
						// Use rounded() to avoid floating-point precision issues (e.g. 0.999999)
						Int((selectedStepLength.truncatingRemainder(dividingBy: 1) * 10).rounded())
					},
					set: { newValue in
						// Preserve the integer part when fractional digit changes
						let integerPart = floor(selectedStepLength)
						selectedStepLength = integerPart + (Double(newValue) / 10.0)
						notifyChange()
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
			.frame(maxWidth: .infinity)
			.cardBackground(stroke: .whiteApp, bg: .clear)
		}
	}
}
