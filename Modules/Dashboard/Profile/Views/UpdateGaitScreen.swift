//
//  UpdateSetGait.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

struct UpdateGaitScreen: View {
	
	@Environment(\.dismiss) var dismiss
	
    var body: some View {
		VStack {
			ScrollView(showsIndicators: false) {
				SetGaitStepView()
			}
			.scrollBounceBehavior(.basedOnSize)
			
			AppButton(.close) {
				dismiss()
			}
		}
		.padding(Constant.UI.defaultPadding)
		.appBackground()
    }
}

#Preview {
	UpdateGaitScreen()
}
