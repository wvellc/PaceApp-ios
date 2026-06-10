//
//  MeasureUnit.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

// MARK: - MeasureUnit

enum MeasureUnit: String, CaseIterable, Codable, Equatable {
    case km    = "Kms"
    case miles = "Miles"

    var fullName: String {
        switch self {
        case .km:    return "Kilometers"
        case .miles: return "Miles"
        }
    }
}
