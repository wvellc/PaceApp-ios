//
//  DistanceType.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/3/26.
//

// MARK: -  Measure Unit Enums
enum MeasureUnit: String, CaseIterable {
    case km = "Kms"
	case miles = "Miles"
	
	var fullName: String {
		switch self {
			case .km: return "Kilometers"
			case .miles: return "Miles"
		}
	}
}
