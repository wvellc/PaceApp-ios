//
//  HomeScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/31/26.
//

import SwiftUI

struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()
    @State private var showPairWatch = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: App Navigation bar
            AppNavigation(trailing: {
                Button(action: {
                    // TODO: Show notification screen
                }, label: {
                    RoundedRectangle(cornerRadius: 100)
                        .foregroundStyle(.whiteApp)
                        .overlay(content: {
                            Image(.icNotification)
                                .resizable()
                                .frame(width: 20, height: 20)
                        })
                })
            })

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: User name & sync status
                    VStack(alignment: .leading) {
                        Text("GM, Jack")
                            .font(.bold28)
                            .foregroundColor(.whiteApp)
                        Text("Not Synced Yet!")
                            .font(.medium14)
                            .foregroundColor(.white50)
                    }

                    // MARK: Home data & Pair watch view
                    if showPairWatch {
                        PairWatchView {
                            showPairWatch = true
                        }
                    } else {
                        if #available(iOS 26.0, *) {
                            GlassEffectContainer(spacing: 15) {
                                metricRow
                            }
                        } else {
                            metricRow
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .appBackground()
    }

    private var metricRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(viewModel.metrics) { metric in
                    HomeMetricCard(metric: metric)
                }
            }
            .padding(16)
        }
    }
}


#Preview {
    HomeScreen()
}

