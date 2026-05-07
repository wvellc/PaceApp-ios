//
//  TimeFormatter.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/7/26.
//


// MARK: - TimeFormatter.swift
// Shared time parsing / formatting utility.
// Handles both "HH:mm:ss" and "-HH:mm:ss" (negative timeVar) from Garmin.

import Foundation

enum TimeFormatter {

    // MARK: String → Seconds

    /// Parses "HH:mm:ss", "mm:ss", or "-HH:mm:ss" → total seconds (negative if prefixed)
    static func toSeconds(from string: String) -> Int? {
        var s = string.trimmingCharacters(in: .whitespaces)
        let negative = s.hasPrefix("-")
        if negative { s = String(s.dropFirst()) }

        let parts = s.split(separator: ":").compactMap { Int($0) }
        var result: Int
        switch parts.count {
        case 3: result = parts[0] * 3600 + parts[1] * 60 + parts[2]
        case 2: result = parts[0] * 60 + parts[1]
        case 1: result = parts[0]
        default: return nil
        }
        return negative ? -result : result
    }

    // MARK: Seconds → String

    /// Formats seconds → "H:mm:ss" or "mm:ss" (no hours if < 3600)
    static func toString(seconds: Int) -> String {
        let absVal = abs(seconds)
        let sign   = seconds < 0 ? "-" : ""
        let h = absVal / 3600
        let m = (absVal % 3600) / 60
        let s = absVal % 60
        if h > 0 {
            return String(format: "%@%d:%02d:%02d", sign, h, m, s)
        } else {
            return String(format: "%@%d:%02d", sign, m, s)
        }
    }

    /// Short format: always "mm:ss" even for hours (useful in compact UI)
    static func toShortString(seconds: Int) -> String {
        let absVal = abs(seconds)
        let m = absVal / 60
        let s = absVal % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: TimeInterval → Duration string

    static func durationString(from start: TimeInterval, to stop: TimeInterval) -> String {
        let diff = Int(abs(stop - start))
        return toString(seconds: diff)
    }
}
