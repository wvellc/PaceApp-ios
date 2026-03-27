//
//  ConnectStravaStepView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/24/26.
//

import SwiftUI

// MARK: - ConnectStravaStepView

/// Step 3 — Strava profile URL entry + connect CTA.
struct ConnectStravaStepView: View {

    @Bindable var viewModel: CreateAccountViewModel

    var body: some View {
        VStack {

            // Subtitle
            Text("Sync your activities and compete with friends for the segment.")
				.font(.medium20)
				.foregroundStyle(.whiteApp)
				.lineSpacing(10)
				.frame(maxWidth: .infinity, alignment: .leading)

			VSpace(height: 64)

            // Strava logo — replace Image(.icStrava) once asset is added
			Image(.stravaLogo)
				.resizable()
				.frame(width: 100, height: 108)

			VSpace(height: 42)
			
            // Profile URL field
            AppTextField(
                text: $viewModel.stravaProfileURL,
                placeholder: "strava.com/athletes/...",
                leadingView: AnyView(
					Image(.icSync)
						.frame(width: 24, height: 24)
                ),
                keyboardType: .URL,
                autocapitalization: .never
            )

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
}

#Preview {
	ConnectStravaStepView(viewModel: CreateAccountViewModel())
		.appBackground()
}
