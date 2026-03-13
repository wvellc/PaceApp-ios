//
//  Typography.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

// MARK: - PACE Type Scale
// Naming convention: pace + Weight + Size
// Self-documenting — weight and size are explicit at every call site
extension Font {
	
	// ExtraBold
	static let extraBold34: Font = Gilroy.extraBold.size(34)
	
	// Bold
	static let bold28: Font      = Gilroy.bold.size(28)
	
	// SemiBold
	static let semiBold16: Font  = Gilroy.semiBold.size(16)
	static let semiBold20: Font  = Gilroy.semiBold.size(20)
	static let semiBold32: Font  = Gilroy.semiBold.size(32)
	
	// Medium
	static let medium14: Font    = Gilroy.medium.size(14)
	static let medium16: Font    = Gilroy.medium.size(16)
	static let medium18: Font    = Gilroy.medium.size(18)
	static let medium20: Font    = Gilroy.medium.size(20)
	
	// Regular
	static let paceRegular17: Font   = Gilroy.regular.size(17)
	
	// Light
	static let light32: Font     = Gilroy.light.size(32)
}
