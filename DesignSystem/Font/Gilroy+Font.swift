//
//  Gilroy+Font.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

// MARK: - Gilroy Font Cases
enum Gilroy: String {
	case light     = "Gilroy-Light"
	case regular   = "Gilroy-Regular"
	case medium    = "Gilroy-Medium"
	case semiBold  = "Gilroy-SemiBold"
	case bold      = "Gilroy-Bold"
	case extraBold = "Gilroy-ExtraBold"
	
	func size(_ size: CGFloat) -> Font {
		.custom(self.rawValue, size: size)
	}
	
	func fixedSize(_ size: CGFloat) -> Font {
		.custom(self.rawValue, fixedSize: size)
	}
}
