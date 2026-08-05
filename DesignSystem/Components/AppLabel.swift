//
//  LabelNewRun.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/6/26.
//

import SwiftUI

///Label for new run flow
struct AppLabel: View {
	
	//MARK: Variables
	var title: LocalizedStringResource
	var font: Font
	
	init(title: LocalizedStringResource, font: Font = .semiBold24) {
		self.title = title
		self.font = font
	}
	
	//MARK: Body
	var body: some View {
		//Label
		Text(title)
			.font(font)
			.foregroundColor(.darkCharcoal)
			.tracking(0.54)
			.lineSpacing(5)

		
	}
}

#Preview {
	AppLabel(title: .doYouWantToRunWithSegments, font: .medium24)
		.padding(.horizontal, 60)
}
