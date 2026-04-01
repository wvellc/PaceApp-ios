//
//  HomeViewModel.swift
//  PaceApp
//
//  Created by OpenAI on 8/30/25.
//

import SwiftUI

@Observable
final class HomeViewModel {

    let metrics: [HomeMetric] = [
        .init(symbolName: "heart.fill", value: "60", unit: "bpm"),
        .init(symbolName: "scope", value: "12", unit: "hrs"),
        .init(symbolName: "alarm", value: "-01:10", unit: "m /sec"),
        .init(symbolName: "clock.fill", value: "7:20", unit: "m /sec"),
        .init(symbolName: "figure.run.circle", value: "9:09", unit: "min/mile")
    ]
}

struct HomeMetric: Identifiable {
    let id = UUID()
    let symbolName: String
    let value: String
    let unit: String
}
