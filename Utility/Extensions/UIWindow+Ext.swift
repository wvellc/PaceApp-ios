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
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }) as? UIWindowScene else {
            return .zero // Return zero bounds if no active scene found
        }
        return windowScene.screen.bounds
    }

    /// Returns the current key window from the active scene.
    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    /// Applies a native push-style CATransition (right → left) to the key window's layer.
    ///
    /// This is the correct way to animate a root-level swap in SwiftUI — unlike
    /// `.transition` + `.id`, the CATransition fires on the UIKit layer **after**
    /// SwiftUI has already committed the new view tree, so only one screen is ever
    /// visible at a time.  No bleed-through, no side-by-side rendering.
    ///
    /// - Parameter forward: `true` → slide right-to-left (push).
    ///                       `false` → slide left-to-right (pop / back).
    static func setRootTransition(forward: Bool = true) {
        let transition = CATransition()
        transition.duration = 0.35
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = forward ? .fromRight : .fromLeft
        keyWindow?.layer.add(transition, forKey: kCATransition)
    }
}
