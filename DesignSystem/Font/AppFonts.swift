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
	static let paceExtraBold34: Font = Gilroy.extraBold.size(34)
	
	// Bold
	static let paceBold28: Font      = Gilroy.bold.size(28)
	
	// SemiBold
	static let paceSemiBold20: Font  = Gilroy.semiBold.size(20)
	
	// Medium
	static let paceMedium17: Font    = Gilroy.medium.size(17)
	
	// Regular
	static let paceRegular17: Font   = Gilroy.regular.size(17)
	
	// Light
	static let paceLight15: Font     = Gilroy.light.size(15)
}
