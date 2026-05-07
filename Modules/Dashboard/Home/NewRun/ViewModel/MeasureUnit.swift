//
//  DistanceType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

// MARK: -  Measure Unit Enums
/// Distance/pace measurement unit
enum MeasureUnit: String, Codable, CaseIterable, Identifiable {
	case miles      = "Miles"
	case kilometers = "Kms"
	case feet       = "ft"
	case meters     = "m"

	static var allCases: [MeasureUnit] {
		[.miles, .kilometers]
	}

	
	var id: String { rawValue }
	
	var shortLabel: String {
		switch self {
			case .miles:      return "mi"
			case .kilometers: return "km"
			case .feet:       return "ft"
			case .meters:     return "m"
		}
	}
	
	var isImperial: Bool {
		self == .miles || self == .feet
	}

	var garminRawValue: String {
		rawValue
	}
}
