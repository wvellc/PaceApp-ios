//
//  ToolBar+Ext.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/17/26.
//

import SwiftUI

extension ToolbarContent {
	@ToolbarContentBuilder
	func hideGlassBackgroundIfAvailable() -> some ToolbarContent {
		if #available(iOS 26.0, *) {
			// Apply the new iOS 26+ modifier
			self.sharedBackgroundVisibility(.hidden)
		} else {
			// Fallback for older versions (effect doesn't exist)
			self
		}
	}
}

extension UIBarButtonItem {
	func removeLiquidGlass() {
		if #available(iOS 26.0, *) {
			// This property specifically removes the "capsule" background
			self.hidesSharedBackground = true
		}
	}
}
