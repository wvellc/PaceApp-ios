//
//  HomeViewModel.swift
//  PaceApp
//
//  Created by OpenAI on 8/30/25.
//

import SwiftUI

///Home View Model
@Observable
final class HomeViewModel {
 
	//MARK: Variables
	
	//Metrics
	var metrics: [HomeMetric]
    private var timer: Timer?
	var isHighPerformance: Bool = false

	//MARK: Intializer
    init() {
        self.metrics = [
            .init(symbol: "icMatricsBpm", value: "60", unit: "bpm"),
            .init(symbol: "icMatricsHrs", value: "12", unit: "hrs"),
            .init(symbol: "icMatricsGoalTime", value: "-01:10", unit: "m /sec"),
            .init(symbol: "icMatricsRemaining", value: "7:20", unit: "m /sec"),
            .init(symbol: "icMatricsPace", value: "9:09", unit: "min/mile")
        ]

        // Start a timer to update values every second for prototyping
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

	//MARK: DeIntializer
    deinit {
        timer?.invalidate()
    }

	//MARK: Methods
    private func tick() {
        func twoDigits(_ n: Int) -> String { String(format: "%02d", n) }
        isHighPerformance.toggle()

        metrics = metrics.enumerated().map { index, metric in
            // Choose symbol by common flag (no swapping)

			switch index {
            case 0: // bpm
                let bpm = Int.random(in: 55...110)
					return HomeMetric(symbol: metric.symbol, value: "\(bpm)", unit: "bpm")
            case 1: // hrs
                let hrs = Int.random(in: 6...16)
                return HomeMetric(symbol: metric.symbol, value: "\(hrs)", unit: "hrs")
            case 2: // goal time (signed mm:ss)
                let negative = Bool.random()
                let m = Int.random(in: 0...1)
                let s = Int.random(in: 0...59)
                let sign = negative ? "-" : ""
                return HomeMetric(symbol: metric.symbol, value: "\(sign)\(twoDigits(m)):\(twoDigits(s))", unit: "m /sec")
            case 3: // remaining (mm:ss)
                let m = Int.random(in: 0...12)
                let s = Int.random(in: 0...59)
                return HomeMetric(symbol: metric.symbol, value: "\(m):\(twoDigits(s))", unit: "m /sec")
            case 4: // pace (min/mile)
                let m = Int.random(in: 7...12)
                let s = Int.random(in: 0...59)
                return HomeMetric(symbol: metric.symbol, value: "\(m):\(twoDigits(s))", unit: "min/mile")
            default:
                return HomeMetric(symbol: metric.symbol, value: metric.value, unit: metric.unit)
            }
        }
    }
}

struct HomeMetric: Identifiable {
    let id = UUID()
    let symbol: String
    let value: String
    let unit: String
}
