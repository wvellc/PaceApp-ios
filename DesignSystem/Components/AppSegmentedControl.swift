//
//  AppSegmentedControl.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import SwiftUI

struct AppSegmentedControl<Segment: Hashable>: View {
	
	// MARK: - Properties (Untouched)
	@Binding var selection: Segment
	@Namespace private var segmentNamespace
	private let segments: [(key: Segment, title: String)]
	private let font: Font
	private let selectedForeground: Color
	private let unselectedForeground: Color
	private let selectedFill: AnyShapeStyle
	private let trackBackground: Color
	private let cornerRadius: CGFloat
	private let verticalPadding: CGFloat
	private let height: CGFloat?
	
	// MARK: - Drag state
	@State private var segmentWidth: CGFloat = 0
	/// Using a CGFloat? to represent the absolute X position of the finger during drag
	@State private var dragLocationX: CGFloat? = nil
	
	// MARK: - Init
	init(
		selection: Binding<Segment>,
		segments: [(key: Segment, title: String)],
		font: Font = .medium14,
		selectedForeground: Color = .whiteApp,
		unselectedForeground: Color = .whiteApp.opacity(0.5),
		selectedFill: AnyShapeStyle? = nil,
		selectedGradientStart: Color = Color(red: 31/255, green: 151/255, blue: 234/255),
		selectedBackground: Color = Color(red: 14/255, green: 118/255, blue: 189/255),
		trackBackground: Color = Color.white.opacity(0.1),
		cornerRadius: CGFloat = 12,
		verticalPadding: CGFloat = 12,
		height: CGFloat? = 44
	) {
		self._selection = selection
		self.segments = segments
		self.font = font
		self.selectedForeground = selectedForeground
		self.unselectedForeground = unselectedForeground
		self.selectedFill = selectedFill ?? AnyShapeStyle(
			LinearGradient(
				colors: [selectedGradientStart, selectedBackground],
				startPoint: .top,
				endPoint: .bottom
			)
		)
		self.trackBackground = trackBackground
		self.cornerRadius = cornerRadius
		self.verticalPadding = verticalPadding
		self.height = height
	}
	
	// MARK: - Convenience init
	init(
		selection: Binding<Segment>,
		titles: [Segment: String],
		order: [Segment]
	) where Segment: Hashable {
		self.init(
			selection: selection,
			segments: order.compactMap { key in
				titles[key].map { (key: key, title: $0) }
			}
		)
	}
	
	// MARK: - Body
	var body: some View {
		GeometryReader { geo in
			let horizontalPadding: CGFloat = 4
			let totalAvailableWidth = geo.size.width - (horizontalPadding * 2)
			let cellWidth = totalAvailableWidth / CGFloat(segments.count)
			let selectedIndex = segments.firstIndex(where: { $0.key == selection }) ?? 0
			
			// Calculate pillX at the top level of the body so both ZStack and Gesture can see it
			let currentPillX: CGFloat = {
				if let dragX = dragLocationX {
					let centerAdjust = cellWidth / 2
					let raw = dragX - centerAdjust - horizontalPadding
					return min(max(raw, 0), totalAvailableWidth - cellWidth)
				}
				return CGFloat(selectedIndex) * cellWidth
			}()
			
			ZStack(alignment: .leading) {
				RoundedRectangle(cornerRadius: cornerRadius)
					.fill(trackBackground)
				
				// Selection Pill
				RoundedRectangle(cornerRadius: cornerRadius - 2)
					.fill(selectedFill)
					.frame(width: cellWidth)
					.padding(horizontalPadding)
					.offset(x: currentPillX) // Use the locally computed value
					.animation(dragLocationX != nil ? .interactiveSpring() : .spring(response: 0.3, dampingFraction: 0.75), value: currentPillX)
				
				HStack(spacing: 0) {
					ForEach(segments.indices, id: \.self) { index in
						Text(segments[index].title)
							.font(font)
							.foregroundColor(selection == segments[index].key ? selectedForeground : unselectedForeground)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
							.contentShape(Rectangle())
							.onTapGesture {
								HapticManager.shared.light()
								withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
									selection = segments[index].key
								}
							}
					}
				}
				.padding(horizontalPadding)
			}
			.focusable(false)
			.gesture(
				DragGesture(minimumDistance: 0, coordinateSpace: .local)
					.onChanged { value in
						dragLocationX = value.location.x
					}
					.onEnded { _ in
						// 1. Calculate where the pill center is at the moment of release
						let pillCenter = currentPillX + (cellWidth / 2)
						
						// 2. Identify the target index based on the "50% area" logic
						let targetIndex = Int((pillCenter / cellWidth).rounded(.down))
						let clampedIndex = max(0, min(targetIndex, segments.count - 1))
						
						// 3. Get the key for the potential new selection
						let newSelection = segments[clampedIndex].key
						
						// 4. Only trigger haptic and binding update if the selection has actually changed
						if selection != newSelection {
							HapticManager.shared.light()
							withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
								selection = newSelection
							}
						}
						
						// 5. Always clear the drag state to snap the pill (either to new or old position)
						withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
							dragLocationX = nil
						}
					}
			)
		}
		.frame(height: height)
	}
	
	// MARK: - Segment Button
	private func segmentButton(_ key: Segment, title: String) -> some View {
		let isSelected = selection == key
		return Text(title)
			.font(font)
			.foregroundColor(isSelected ? selectedForeground : unselectedForeground)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.padding(.vertical, verticalPadding)
			.contentShape(Rectangle())
			.onTapGesture {
				HapticManager.shared.light()
				withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
					selection = key
				}
			}
	}
}
// MARK: - Preview

#Preview {
	
	@Previewable @State var selected: LoginType = .email
	
	ZStack {
		Color.darkSeaBlue

		VStack(spacing: 32) {
			// Example with LoginType
			AppSegmentedControl(
				selection: $selected,
				segments: [
					(key: LoginType.email, title: "Email"),
					(key: LoginType.phoneNumber, title: "Phone Number")
				]
			)
		}
		.padding(.horizontal, 16)
	}
}
