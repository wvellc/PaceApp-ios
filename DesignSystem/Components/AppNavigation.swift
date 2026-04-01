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

