//
//  FilterSheetView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import SwiftUI

// MARK: - Filter Sheet View
struct FilterSheetView: View {
 
    // MARK: Bindings (shared from HistoryViewModel)
    @Binding var distanceMin: Double
    @Binding var distanceMax: Double
    @Binding var filterDate: Date?
    @Binding var filterLocation: String
	
    // MARK: Actions
    var onApply: () -> Void
    var onClear: () -> Void
    var onDismiss: () -> Void
 
    // MARK: Constants
    private let absoluteMin: Double = 0
    private let absoluteMax: Double = 150
 
    // MARK: Body
    var body: some View {
		VStack(alignment: .leading) {
			
			// ── Header ────────────────────────────────────────────
			headerRow
				.padding(.horizontal, 20)
				.padding(.top, 36)
				.padding(.bottom, 28)
			
			// ── Distance Range ────────────────────────────────────
			distanceSection
				.padding(.horizontal, 20)
			
			// ── Date ─────────────────────────────────────────────
			dateSection
				.padding(.horizontal, 20)
				.padding(.top, 28)
			
			// ── Location ──────────────────────────────────────────
			locationSection
				.padding(.horizontal, 20)
				.padding(.top, 24)
			
			// ── Bottom Buttons ────────────────────────────────────
			bottomButtons
				.padding(.horizontal, 20)
				.padding(.bottom, 36)
				.padding(.top, 24)
			
		}
		.fixedSize(horizontal: false, vertical: true)
    }
}
 
// MARK: - Subviews
private extension FilterSheetView {
 
    // MARK: Header Row
    var headerRow: some View {
        HStack {
			Text(.filter)
				.font(.semiBold24)
				.lineSpacing(16)
				.foregroundColor(.darkCharcoal)
 
            Spacer()
 
            Button(action: onDismiss) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
						.fill(Color(.grayHint))
                        .frame(width: 24, height: 24)
						.padding(.horizontal, 2)
 
                    Image(systemName: "xmark")
						.font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.red)
                }
            }
        }
    }
 
    // MARK: Distance Section
    var distanceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
			Text(.distanceBy)
				.font(.semiBold20)
				.foregroundColor(.darkCharcoal)

 
            // Dual-handle range slider
            DualRangeSlider(
                minValue: $distanceMin,
                maxValue: $distanceMax,
                absoluteMin: absoluteMin,
                absoluteMax: absoluteMax
            )
 
            // Min / Max labels
            HStack {
                VStack(alignment: .leading, spacing: 2) {
					Text(.mi(Int(distanceMin)))
						.font(.semiBold20)
						.foregroundColor(.darkCharcoal)
					Text(.min)
						.font(.medium16)
						.foregroundColor(.fashionGray)
                }
 
                Spacer()
 
                VStack(alignment: .trailing, spacing: 2) {
					Text(.mi(Int(distanceMax)))
						.font(.semiBold20)
						.foregroundColor(.darkCharcoal)
					Text(.max)
						.font(.medium16)
						.foregroundColor(.fashionGray)
                }
            }
        }
    }
 
    // MARK: Date Section
    var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
			Text(.date)
				.font(.semiBold20)
				.foregroundColor(.darkCharcoal)
			
			DatePicker("", selection: selectedDateBinding, displayedComponents: .date)
				.font(.semiBold20)
				.foregroundColor(.darkCharcoal)
				.gaugeStyle(.accessoryCircular)
				.tint(.blackApp)
				.padding(10)
				.cardBackground()
				.overlay {
					HStack {
						Image(.icDate)
							.padding(.leading, Constant.UI.defaultPadding)
						
						Spacer()
					}
				}
        }
    }

	var selectedDateBinding: Binding<Date> {
		Binding(
			get: { filterDate ?? Date() },
			set: { filterDate = $0 }
		)
	}
 
    // MARK: Location Section
    var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
			Text(.location)
				.font(.semiBold20)
				.foregroundColor(.darkCharcoal)
			
			AppTextField(
				text: $filterLocation,
				placeholder: "e.g. City",
				validation: .custom(regex: "^[\\p{L}\\s\\-\\']{2,50}$"),
				autocapitalization: .words, // Better for city names than .sentences
				borderColor: .fashionGray,
				foregroundStyle: .darkCharcoal
			)
			.foregroundColor(.darkCharcoal)
        }
    }
 
    // MARK: Bottom Buttons
    var bottomButtons: some View {
        HStack(spacing: 12) {
            // Clear All
			AppButton(.clearAll, style: .secondary, action: onClear)
 
            // Show Results
			AppButton(.showResults) {
				onApply()
				onDismiss()
			}
        }
		.frame(height: 54)
    }
}
 
// MARK: - Filter Input Field
private struct FilterInputField: View {
    @Binding var text: String
    let placeholder: String
    var trailingIcon: AnyView? = nil
 
    var body: some View {
		AppTextField(text: $text,
					 placeholder: LocalizedStringResource(stringLiteral: placeholder),
					 trailingView: trailingIcon,
					 autocapitalization: .sentences
		)
    }
}
 
// MARK: - Dual Range Slider
private struct DualRangeSlider: View {
 
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let absoluteMin: Double
    let absoluteMax: Double
 
    // Geometry state
    @State private var sliderWidth: CGFloat = 0
 
    private let thumbSize: CGFloat = 40
    private let trackHeight: CGFloat = 8
	private let activeColor  = Color(.neonAquaBlue)
	private let inactiveColor = Color(.grayHint)
 
    // MARK: Body
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let range = absoluteMax - absoluteMin
 
            // Fractional positions [0..1]
            let minFrac = CGFloat((minValue - absoluteMin) / range)
            let maxFrac = CGFloat((maxValue - absoluteMin) / range)
 
            let minX = minFrac * (width - thumbSize) + thumbSize / 2
            let maxX = maxFrac * (width - thumbSize) + thumbSize / 2
 
            ZStack(alignment: .leading) {
                // ── Full Track ────────────────────────────────────
                Capsule()
                    .fill(inactiveColor)
                    .frame(height: trackHeight)
                    .padding(.horizontal, thumbSize / 2)
 
                // ── Active Track ──────────────────────────────────
                Capsule()
                    .fill(activeColor)
                    .frame(width: maxX - minX, height: trackHeight)
                    .offset(x: minX)
 
                // ── Min Thumb ─────────────────────────────────────
                thumb(symbol: true)
                    .position(x: minX, y: geo.size.height / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newFrac = max(0, min(Double(value.location.x / width), 1))
                                let newVal  = absoluteMin + newFrac * range
                                minValue    = min(newVal, maxValue - 1)
                            }
                    )
 
                // ── Max Thumb ─────────────────────────────────────
                thumb(symbol: true)
                    .position(x: maxX, y: geo.size.height / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newFrac = max(0, min(Double(value.location.x / width), 1))
                                let newVal  = absoluteMin + newFrac * range
                                maxValue    = max(newVal, minValue + 1)
                            }
                    )
            }
            .frame(height: thumbSize)
        }
        .frame(height: thumbSize)
    }
 
    // MARK: Thumb
    @ViewBuilder
    private func thumb(symbol: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .overlay(
                    Circle()
                        .stroke(activeColor, lineWidth: 4)
                )
 
            // Drag handle lines (≡)
            VStack(spacing: 4) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule()
						.fill(Color(.fashionGray))
                        .frame(width: 14, height: 2)
                }
            }
        }
    }
}
 
// MARK: - Preview
#Preview {
    @Previewable @State var min: Double = 10
    @Previewable @State var max: Double = 150
    @Previewable @State var date: Date?
    @Previewable @State var location: String = ""
 
    FilterSheetView(
        distanceMin: $min,
        distanceMax: $max,
        filterDate: $date,
        filterLocation: $location,
        onApply: { },
        onClear: { },
        onDismiss: { }
    )
	.background(Color.white)
	// Rounded top corners only
	.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

}
