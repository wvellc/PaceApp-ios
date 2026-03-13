//
//  AppSegmentedControl.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import SwiftUI

/// A reusable segmented control with an animated sliding selection indicator.
///
/// Generic over any `Hashable` & `CaseIterable` type whose segments are
/// identified by their `String` titles.
///
/// Usage:
/// ```swift
/// @State private var selected: LoginType = .phoneNumber
///
/// AppSegmentedControl(
///     selection: $selected,
///     titles: [.email: "Email", .phoneNumber: "Phone Number"]
/// )
/// ```
struct AppSegmentedControl<Segment: Hashable>: View {

	// MARK: - Properties

	@Binding var selection: Segment
	@Namespace private var segmentNamespace

	/// Ordered segments and their display titles.
	private let segments: [(key: Segment, title: String)]

	/// Visual configuration
	private let font: Font
	private let selectedForeground: Color
	private let unselectedForeground: Color
	private let selectedBackground: Color
	private let trackBackground: Color
	private let cornerRadius: CGFloat
	private let verticalPadding: CGFloat
	private let height: CGFloat?

	// MARK: - Init

	/// Creates an `AppSegmentedControl`.
	///
	/// - Parameters:
	///   - selection: Binding to the currently selected segment.
	///   - segments: Ordered array of `(key, title)` pairs.
	///   - font: Segment label font. Default `.medium16`.
	///   - selectedForeground: Text color for the active segment. Default `.whiteApp`.
	///   - unselectedForeground: Text color for inactive segments. Default `.whiteApp` at 50%.
	///   - selectedBackground: Fill color behind the active segment. Default vivid blue.
	///   - trackBackground: The track color behind all segments. Default `white` at 10%.
	///   - cornerRadius: Corner radius for both track and indicator. Default `12`.
	///   - verticalPadding: Padding inside each segment label. Default `12`.
	///   - height: Explicit height constraint. Default `44`.
	init(
		selection: Binding<Segment>,
		segments: [(key: Segment, title: String)],
		font: Font = .medium16,
		selectedForeground: Color = .whiteApp,
		unselectedForeground: Color = .whiteApp.opacity(0.5),
		selectedBackground: Color = Color(red: 43/255, green: 135/255, blue: 255/255),
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
		self.selectedBackground = selectedBackground
		self.trackBackground = trackBackground
		self.cornerRadius = cornerRadius
		self.verticalPadding = verticalPadding
		self.height = height
	}

	// MARK: - Convenience init (dictionary)

	/// Convenience initializer that accepts a dictionary and an explicit ordering.
	///
	/// - Parameters:
	///   - selection: Binding to the currently selected segment.
	///   - titles: Dictionary mapping each segment to its display title.
	///   - order: The order in which segments should appear.
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
		HStack(spacing: 0) {
			ForEach(segments.indices, id: \.self) { index in
				let segment = segments[index]
				segmentButton(segment.key, title: segment.title)
			}
		}
		.padding(4)
		.background(trackBackground)
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
		.frame(height: height)
	}

	// MARK: - Segment Button

	private func segmentButton(_ key: Segment, title: String) -> some View {
		let isSelected = selection == key
		return Button {
			HapticManager.shared.light()
			
			withAnimation(.easeInOut(duration: 0.25)) {
				selection = key
			}
		} label: {
			Text(title)
				.font(font)
				.foregroundColor(isSelected ? selectedForeground : unselectedForeground)
				.frame(maxWidth: .infinity)
				.padding(.vertical, verticalPadding)
				.background {
					if isSelected {
						RoundedRectangle(cornerRadius: cornerRadius)
							.fill(selectedBackground)
							.matchedGeometryEffect(id: "segmentIndicator", in: segmentNamespace)
					}
				}
		}
		.buttonStyle(.plain)
	}
}

// MARK: - Preview

#Preview {
	ZStack {
		Color.darkSeaBlue

		VStack(spacing: 32) {
			// Example with LoginType
			AppSegmentedControl(
				selection: .constant(LoginType.phoneNumber),
				segments: [
					(key: LoginType.email, title: "Email"),
					(key: LoginType.phoneNumber, title: "Phone Number")
				]
			)
		}
		.padding(.horizontal, 16)
	}
}
