//
//  AppNavigation.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/1/26.
//

import SwiftUI

struct AppNavigation<Leading: View, Trailing: View>: View {
	let leading: Leading
	let trailing: Trailing
	
	init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
		self.leading = leading()
		self.trailing = trailing()
	}
	
	// Convenience initializer for when you only want to provide one or no custom views
	init() where Leading == EmptyView, Trailing == EmptyView {
		self.init(leading: { EmptyView() }, trailing: { EmptyView() })
	}
	
	init(@ViewBuilder leading: () -> Leading) where Trailing == EmptyView {
		self.init(leading: leading, trailing: { EmptyView() })
	}
	
	init(@ViewBuilder trailing: () -> Trailing) where Leading == EmptyView {
		self.init(leading: { EmptyView() }, trailing: trailing)
	}
	
	var body: some View {
		HStack {
			leading
				.frame(width: 32, height: 32)
			
			Spacer()
			
			HStack(alignment: .center) {
				Image(.logo) // Assuming .logo is an existing ImageResource
					.resizable()
					.frame(width: 35.5, height: 24)
				Text(.paceApp) // Assuming .paceApp is an existing StringResource or similar
					.font(.extraBold18) // Assuming .extraBold18 is a custom font extension
					.foregroundStyle(.whiteApp) // Assuming .whiteApp is a custom color extension
					.tracking(1.09)
			}
			.scaledToFit()
			
			Spacer()
			
			trailing
				.frame(width: 32, height: 32)
		}
		.padding()
		.frame(maxWidth: .infinity, idealHeight: 34)
	}
}

// MARK: - Shared Back Button Label

/// Reusable back-button label: white circle with a blue chevron.
/// Use this inside any `ToolbarItem` label closure.
struct AppBackButtonLabel: View {
	var body: some View {
		Image(systemName: "chevron.left")
			.font(.system(size: 16, weight: .semibold))
			.foregroundStyle(.whiteApp)
			.padding(8)
	}
}

// MARK: - AppBackButtonStyle (View modifier – hides system bar & injects toolbar)

struct AppBackButtonStyle: ViewModifier {
	let onTap: VoidCallback
	
	func body(content: Content) -> some View {
		content
			.navigationBarBackButtonHidden(true)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button(action: onTap) {
						AppBackButtonLabel()
					}
				}
//				.hideGlassBackgroundIfAvailable()
			}
	}
}

// MARK: - AppBackButtonToolbarContent (ToolbarContentBuilder compatible)

/// Drop this directly inside a `@ToolbarContentBuilder` block when the screen
/// already owns its own `.toolbar { }` modifier and you need the back button
/// alongside other `ToolbarItem`s.
struct AppBackButtonToolbarContent: ToolbarContent {
	let onTap: VoidCallback

	var body: some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button(action: onTap) {
				AppBackButtonLabel()
			}
		}
//		.hideGlassBackgroundIfAvailable()
	}
}

// MARK: - View extension (attaches full modifier — back button + hidden system bar)

extension View {
	/// Hides the system back button and injects the styled back button into the
	/// navigation bar. Use on screens that do **not** have their own toolbar block.
	func globalBackButton(onTap: @escaping VoidCallback) -> some View {
		modifier(AppBackButtonStyle(onTap: onTap))
	}
}
// MARK: - ToolbarContentBuilder extension

extension ToolbarContent {
	/// Returns the styled back-button `ToolbarItem`.
	/// Call this inside a `@ToolbarContentBuilder` block, e.g.:
	/// ```
	/// AppBackButtonToolbarContent { dismiss() }
	/// ```
}

