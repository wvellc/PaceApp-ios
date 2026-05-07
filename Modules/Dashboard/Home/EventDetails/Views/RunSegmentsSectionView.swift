//
//  RunSegmentsSectionView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - RunSegmentsSectionView

struct RunSegmentsSectionView: View {

    let segments: [RunSegment]
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
			detailsSeprator()

			
            RunDetailSectionHeader(title: "Segments", isExpanded: isExpanded, onToggle: onToggle)

            if isExpanded {
				detailsSeprator()
						.padding(.top, 8)
				
                VStack(spacing: 10) {
                    ForEach(segments) { segment in
                        HStack {
                            Text("S\(segment.id)")
								.font(.semiBold16)
                                .foregroundStyle(.darkCharcoal)
                                .frame(width: 28, alignment: .leading)
                            Spacer()
                            Text("\(segment.formattedGoalTime) / \(String(format: "%.2f", segment.distance))mi")
                                .font(.semiBold16)
                                .foregroundStyle(.darkCharcoal)
                        }
                    }
                }
                .padding(.top, 12)
				.transition(.opacity.combined(with: .move(edge: .top).combined(with: .scale)))
            }
        }
    }
}
