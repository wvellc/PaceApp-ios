//
//  UpdateSetGait.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

///Update gait units
struct UpdateGaitScreen: View {
	
	//MARK: Environment
	@Environment(\.dismiss) var dismiss
	
	//MARK: View Builder
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
