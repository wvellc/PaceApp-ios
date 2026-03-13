//
//  UIWindow+Ext.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/13/26.
//

import SwiftUI

extension UIWindow {
    /// Helper to get the current screen bounds safely across iOS versions
    static var currentScreenBounds: CGRect {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }) as? UIWindowScene else {
            return .zero // Return zero bounds if no active scene found, avoids using deprecated UIScreen.main.bounds
        }
        return windowScene.screen.bounds
    }
}
