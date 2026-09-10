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

	/// Resolves a unit from its fullName string (e.g. "Kilometers" → .km).
	/// Used when decoding legacy Firestore documents that stored the fullName value.
	init?(fullName: String) {
		if let match = MeasureUnit.allCases.first(where: { $0.fullName == fullName }) {
			self = match
		} else {
			return nil
		}
	}

	/// Resolves an event's stored measure — "Miles" is miles, anything else ("Kilometers", legacy "Kms") is km.
	init(measure: String) {
		self = measure == MeasureUnit.miles.rawValue ? .miles : .km
	}

	/// Short distance label, e.g. "mi" / "km".
	var shortLabel: String {
		self == .miles ? "mi" : "km"
	}
}
