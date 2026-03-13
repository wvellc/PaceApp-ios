//
//  CGFloat+Ext.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import SwiftUI

extension CGFloat {
    /// Base design width used in Figma (iPhone 13 Mini)
    private static let baseDesignWidth: CGFloat = 375.0
    
    /// Base design height used in Figma (iPhone 13 Mini)
    private static let baseDesignHeight: CGFloat = 812.0

    /// Calculates a proportional width based on the current device's screen width relative to the base design.
    static func getProportionalWidth(_ value: CGFloat) -> CGFloat {
        let screenWidth = UIWindow.currentScreenBounds.width
        return (value / baseDesignWidth) * screenWidth
    }

    /// Calculates a proportional height based on the current device's screen height relative to the base design.
    static func getProportionalHeight(_ value: CGFloat) -> CGFloat {
        let screenHeight = UIWindow.currentScreenBounds.height
        return (value / baseDesignHeight) * screenHeight
    }
}

extension Double {
    /// Returns the proportional width based on the screen width
    func proportionalWidth() -> CGFloat {
        return CGFloat.getProportionalWidth(CGFloat(self))
    }

    /// Returns the proportional height based on the screen height
    func proportionalHeight() -> CGFloat {
        return CGFloat.getProportionalHeight(CGFloat(self))
    }
}

extension Int {
    /// Returns the proportional width based on the screen width
    func proportionalWidth() -> CGFloat {
        return CGFloat.getProportionalWidth(CGFloat(self))
    }

    /// Returns the proportional height based on the screen height
    func proportionalHeight() -> CGFloat {
        return CGFloat.getProportionalHeight(CGFloat(self))
    }
}
