//
//  RunIntervalsSectionView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/6/26.
//

import SwiftUI

// MARK: - RunIntervalsSectionView

struct RunIntervalsSectionView: View {

    let intervals: [RunInterval]
    let isExpanded: Bool
    let onToggle: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), alignment: .leading), count: 4)

    var body: some View {
        VStack(spacing: 0) {
			Divider()
				.padding(.bottom, 2)

            RunDetailSectionHeader(title: "Intervals", isExpanded: isExpanded, onToggle: onToggle)

            if isExpanded {
                Divider()
				
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(intervals) { interval in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(interval.label)
                                .font(.regular13)
								.foregroundStyle(.fashionGray)
                            Text(interval.time)
								.font(.semiBold17)
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
