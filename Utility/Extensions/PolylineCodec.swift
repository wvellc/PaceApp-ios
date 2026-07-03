//
//  PolylineCodec.swift
//  PaceApp
//
//  Encodes/decodes GPS route traces using the Google encoded-polyline
//  algorithm (5 decimal-place precision). This is the Firestore best
//  practice for large coordinate datasets: a long run's GPS trace goes
//  from tens of KB as a raw [lat, lng] array to a few KB as a single
//  compact string, keeping event documents well under Firestore's 1MB
//  document limit and reducing read/write bandwidth.
//
//  Reference: https://developers.google.com/maps/documentation/utilities/polylinealgorithm

import Foundation
import CoreLocation

// MARK: - PolylineCodec

enum PolylineCodec {

	private static let precision: Double = 1e5

	// MARK: - Encode

	/// Encodes a full route into a single compact polyline string.
	static func encode(_ coordinates: [CLLocationCoordinate2D]) -> String {
		guard !coordinates.isEmpty else { return "" }

		var output = ""
		var previousLat = 0
		var previousLng = 0

		for coordinate in coordinates {
			let lat = Int(round(coordinate.latitude * precision))
			let lng = Int(round(coordinate.longitude * precision))

			output += encodeValue(lat - previousLat)
			output += encodeValue(lng - previousLng)

			previousLat = lat
			previousLng = lng
		}

		return output
	}

	private static func encodeValue(_ value: Int) -> String {
		var v = value << 1
		if value < 0 { v = ~v }

		var output = ""
		while v >= 0x20 {
			output.append(Character(UnicodeScalar(UInt8((0x20 | (v & 0x1f)) + 63))))
			v >>= 5
		}
		output.append(Character(UnicodeScalar(UInt8(v + 63))))
		return output
	}

	// MARK: - Decode

	/// Decodes a polyline string back into an ordered route.
	static func decode(_ polyline: String) -> [CLLocationCoordinate2D] {
		guard !polyline.isEmpty else { return [] }

		var coordinates: [CLLocationCoordinate2D] = []
		let chars = Array(polyline.utf8)
		var index = 0
		var lat = 0
		var lng = 0

		while index < chars.count {
			guard let deltaLat = decodeValue(chars, &index) else { break }
			lat += deltaLat
			guard let deltaLng = decodeValue(chars, &index) else { break }
			lng += deltaLng

			coordinates.append(CLLocationCoordinate2D(
				latitude: Double(lat) / precision,
				longitude: Double(lng) / precision
			))
		}

		return coordinates
	}

	private static func decodeValue(_ chars: [UInt8], _ index: inout Int) -> Int? {
		var result = 0
		var shift = 0
		var byte: Int

		repeat {
			guard index < chars.count else { return nil }
			byte = Int(chars[index]) - 63
			index += 1
			result |= (byte & 0x1f) << shift
			shift += 5
		} while byte >= 0x20

		return (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
	}
}
