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
		static let validPasswordLength      = 8
	}
	
	// MARK: UI Constants
	struct UI {
		public static let animationDuration        = 0.3
		public static let glassBlurRadius: CGFloat = 20
		public static let listRowSpacing: CGFloat  = 12
		
		//Opacity
		public static let defaultOpacity: CGFloat  	= 1.0
		public static let disabledOpacity: CGFloat  = 0.5
		public static let shadowOpacity				= CGFloat(0.1)
		
		public static let defaultKeyboardToolBarHeight = CGFloat(44)
		
		//Radius
		public static let defaultCornerRadius	= CGFloat(8)
		public static let cardCornerRadius 		= CGFloat(12)
		public static let textFieldCornerRadius = CGFloat(20)
		
		//Border
		public static let defaultBorderWidth = CGFloat(1)


	}
}
