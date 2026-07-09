//
//  SetGaitStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import SwiftUI


// MARK: - Parent View

/// Stateless gait step view. All data flows in from the caller via `gaitData`,
/// `onRunningChange`, and `onWalkingChange` — no AppSession references.
struct SetGaitStepView: View {

    let gender: Gender
    let gaitData: GaitUserData
    let onRunningChange: (GaitData) -> Void
    let onWalkingChange: (GaitData) -> Void

    init(
        gender: Gender = .male,
        gaitData: GaitUserData? = nil,
        onRunningChange: @escaping (GaitData) -> Void = { _ in },
        onWalkingChange: @escaping (GaitData) -> Void = { _ in }
    ) {
        self.gender = gender
        self.gaitData = gaitData ?? gender.defaultGaitData
        self.onRunningChange = onRunningChange
        self.onWalkingChange = onWalkingChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(.setYourWalkingAndRunningStyleToMatchYourPaceAndMood)
                .font(.medium20)
                .foregroundColor(.whiteApp)
                .lineSpacing(10)
                .multilineTextAlignment(.leading)

            VStack(spacing: 24) {
                
				// Walking gait selector
                GaitSelectionView(
                    type: .walking,
                    gender: gender,
                    initialData: gaitData.walkingData,
                    onChange: onWalkingChange
                )
				
				// Running gait selector
				GaitSelectionView(
					type: .running,
					gender: gender,
					initialData: gaitData.runningData,
					onChange: onRunningChange
				)
            }

            Spacer()
        }
        .padding(.top, 24)
    }
}

#Preview {
    SetGaitStepView()
        .appBackground()
}

// MARK: - Gait Selection Card

/// A card that lets the user pick a unit (Meters/Feet) and step length
/// for a given gait type. Reads initial values from the provided `initialData`
/// and calls `onChange` whenever the user makes a selection.
struct GaitSelectionView: View {

    let type: GaitType
    let gender: Gender
    let onChange: (GaitData) -> Void

    @State private var selectedUnit: String
    /// Single source of truth for the full step length value (e.g. 2.7).
    /// Both wheel pickers read from and write back to this property.
    @State private var selectedStepLength: Double

    let units = ["Meters", "Feet"]

    // MARK: Init

    init(
        type: GaitType,
        gender: Gender = .male,
        initialData: GaitData? = nil,
        onChange: @escaping (GaitData) -> Void
    ) {
        self.type = type
        self.gender = gender
        self.onChange = onChange

        let data = initialData
        _selectedUnit = State(initialValue: data?.unit ?? "Feet")
        _selectedStepLength = State(initialValue: data?.stepLength ?? gender.defaultStepLength(for: type))
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
            .onChange(of: selectedUnit) { oldUnit, newUnit in
                // Convert the shown value so the measurement stays equivalent across units.
                selectedStepLength = GaitStrideCalculator.convert(selectedStepLength, fromUnit: oldUnit, toUnit: newUnit)
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
