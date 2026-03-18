//
//  AppConfig.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

// AppConfig.swift

import SwiftUI

// MARK: - General Constant for PACE Project
struct Constant {
	
	// MARK: App Config
	struct Config {
		static let validPasswordLength		= 8
		static let OTPLength				= 6
	}
	
	// MARK: UI Constants
	struct UI {
		static let animationDuration        = 0.3
		static let glassBlurRadius: CGFloat = 20
		static let listRowSpacing: CGFloat  = 12
		
		//Opacity
		static let defaultOpacity: CGFloat  	= 1.0
		static let disabledOpacity: CGFloat  = 0.5
		static let shadowOpacity				= CGFloat(0.1)
		
		static let defaultKeyboardToolBarHeight = CGFloat(44)
		
		//Radius
		static let defaultCornerRadius	= CGFloat(8)
		static let cardCornerRadius 		= CGFloat(12)
		
		//Border
		static let defaultBorderWidth = CGFloat(1)
		
		//Padding
		static let defaultPadding = CGFloat(16)

	}
}
