//
//  AppConfig.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

// AppConfig.swift

import SwiftUI

// MARK: - General Config for PACE Project
struct Constant {
	
	// MARK: App Level
	struct App {
		static let appName                  = "PACE APP"
		static let validPasswordLength      = 8
	}
	
	// MARK: UI Level
	struct UI {
		static let animationDuration        = 0.3
		static let glassBlurRadius: CGFloat = 20
		static let cornerRadius: CGFloat    = 20
		static let listRowSpacing: CGFloat  = 12
		
		//Opacity
		static let defaultOpacity: CGFloat  = 1.0
		static let disabledOpacity: CGFloat  = 0.5
	}
}
