//
//  DualRangeSlider.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/16/26.
//

import SwiftUI

// MARK: - Dual Range Slider
struct DualRangeSlider: View {
	
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
