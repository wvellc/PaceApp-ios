//
//  Array+Ext.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 6/16/26.
//

// MARK: - Array Extension Helper (add at bottom or in Utils)
extension Array {
	func chunked(into size: Int) -> [[Element]] {
		stride(from: 0, to: count, by: size).map {
			Array(self[$0..<Swift.min($0 + size, self.count)])
		}
	}
}
