//
//  RunDetailSectionHeader.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - RunDetailSectionHeader
// Shared collapsible header: title left, animated +/− right.

struct RunDetailSectionHeader: View {

    let title: String
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
		HStack(alignment: .center) {
            Text(title)
                .font(.semiBold16)
                .foregroundStyle(.darkCharcoal)

            Spacer()

			ZStack {
				Image(.icPlus)
					.frame(width: 18, height: 18)
					.opacity(isExpanded ? 0 : 1)
					.scaleEffect(isExpanded ? 0.4 : 1)
				
				Image(.icMinus)
					.frame(width: 18, height: 18)
					.opacity(isExpanded ? 1 : 0)
					.scaleEffect(isExpanded ? 1 : 0.4)
			}
			.frame(width: 22, height: 22)
			.animation(.spring(response: 0.3, dampingFraction: 0.65), value: isExpanded)

        }
		.padding(.vertical, 8)
		.onTap {
			onToggle()
		}
    }
}



