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
			.font(.semiBold24)
			.foregroundColor(.darkCharcoal)
		
	}
}

