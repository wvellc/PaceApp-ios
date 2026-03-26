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
        VStack(spacing: 0) {

            // Subtitle
            Text("Sync your activities and compete with friends for the segment.")
                .font(.medium18)
                .foregroundStyle(.whiteApp)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 40)

            // Strava logo — replace Image(.icStrava) once asset is added
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.orange)
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.run")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 40)

            // Profile URL field
            AppTextField(
                text: $viewModel.stravaProfileURL,
                placeholder: "strava.com/athletes/...",
                leadingView: AnyView(
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.grayHint)
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
