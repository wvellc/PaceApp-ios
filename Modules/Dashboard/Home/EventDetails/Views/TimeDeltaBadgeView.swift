//
//  TimeDeltaBadgeView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//

import SwiftUI

// MARK: - TimeDeltaBadgeView
struct TimeDeltaBadgeView: View {

    let timeDelta: String
    let isNegative: Bool
    let percent: String

	private var color: Color { !isNegative ? .redBoho : .fluorescentMint }
	private var textColor: Color { !isNegative ? .whiteApp : .darkCharcoal }

    var body: some View {
        HStack {
			Image(.icOvertime)
				.renderingMode(.template)
				.frame(width: 24, height: 24)
			
            Text(timeDelta)
				.font(.semiBold16)
			
            Spacer()
			
            Text(percent)
                .font(.semiBold16)
        }
		.foregroundStyle(textColor)
        .padding(.horizontal, 8)
		.padding(.vertical, 4.5)
        .background(color)
		.clipShape(Capsule())
    }
}
