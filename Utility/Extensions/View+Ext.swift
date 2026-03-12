//
//  ViewExtensions.swift
//  recoverytrak
//
//  Created by FURKAN VIJAPURA on 07/11/24.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder func modifyIf<Content: View>(
        _ condition: @autoclosure () -> Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, apply: (Self) -> T) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }
    
    func onTap(tapped: @escaping () -> Void) -> some View {
        modifier(OnTap(tapped: tapped))
    }
    
    func setDisabled(_ disabled: Bool) -> some View {
        modifier(SetDisabled(disabled: disabled))
    }
    
    func addShadow(offsetX: CGFloat = 0, offsetY: CGFloat = 0) -> some View {
        modifier(AddShadow(offsetX: offsetX, offsetY: offsetY))
    }
    
    func addRoundRectBorderOverlay(
        _ borderColor: Color,
        borderWidth: CGFloat = Dimens.defaultBorderWidth,
        cornerRadius: CGFloat = Dimens.defaultCornerRadius,
        roundCorners: UIRectCorner = .allCorners
    ) -> some View {
        modifier(AddRoundRectBorderOverlay(
            borderColor: borderColor,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            corners: roundCorners
        ))
    }
    
    func addRoundedBackgroundColor(
        _ backgroundColor: Color,
        cornerRadius: CGFloat = Dimens.defaultCornerRadius,
        roundCorners: UIRectCorner = .allCorners,
        addShadow: Bool = false
    ) -> some View {
        modifier(
            AddRoundedBackgroundColor(
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                corners: roundCorners,
                addShadow: addShadow
            )
        )
    }
    
    func viewSize(_ size: CGFloat) -> some View {
        self.frame(width: size, height: size)
    }
    
    func circleBackground(_ color: Color) -> some View {
        self.background {
            Circle().fill(color)
        }
    }
    
}

private struct OnTap: ViewModifier {
    var tapped: () -> Void
    
    func body(content: Content) -> some View {
        Button {
            tapped()
        } label: {
            content
        }
    }
}

private struct SetDisabled: ViewModifier {
    var disabled: Bool
    
    func body(content: Content) -> some View {
        return content
            .disabled(disabled)
            .allowsHitTesting(!disabled)
			.opacity(disabled ? Constant.UI.disabledOpacity : Dimens.defaultOpacity)
    }
}

private struct AddShadow: ViewModifier {
    var offsetX: CGFloat
    var offsetY: CGFloat
    
    func body(content: Content) -> some View {
        return content
            .shadow(
                color: Color.steelBlue.opacity(Dimens.shadowOpacity),
                radius: Dimens.defaultCornerRadius,
                x: offsetX,
                y: offsetY
            )
    }
}

private struct AddRoundRectBorderOverlay: ViewModifier {
    var borderColor: Color
    var borderWidth: CGFloat
    var cornerRadius: CGFloat
    var corners: UIRectCorner
    
    func body(content: Content) -> some View {
        return content
            .overlay(
                ViewShape(roundCorners: corners, radius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
}

private struct AddRoundedBackgroundColor: ViewModifier {
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var corners: UIRectCorner
    var addShadow: Bool
    
    func body(content: Content) -> some View {
        return content
            .background(
                backgroundColor
                    .clipShape(ViewShape(roundCorners: corners, radius: cornerRadius))
                    .modifyIf(addShadow, transform: { background in
                        background
                            .addShadow(offsetX: 0, offsetY: 2)
                    })
            )
    }
}

struct ViewShape: Shape {
    var roundCorners = UIRectCorner.allCorners
    var radius: CGFloat = Dimens.defaultCornerRadius
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: roundCorners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct FixedDynamicTypeSize: ViewModifier {
	var size: DynamicTypeSize = .medium
	
	func body(content: Content) -> some View {
		content
			.environment(\.dynamicTypeSize, size)
	}
}

extension View {
	func fixedDynamicTypeSize(_ size: DynamicTypeSize = .medium) -> some View {
		self.modifier(FixedDynamicTypeSize(size: size))
	}
}

struct ScaledFont: ViewModifier {
	@Environment(\.sizeCategory) var sizeCategory
	var name: String
	var size: Double
	
	func body(content: Content) -> some View {
		let scaledSize = UIFontMetrics.default.scaledValue(for: size)
		return content.font(.custom(name, size: scaledSize))
	}
}

extension View {
	func scaledFont(name: String, size: Double) -> some View {
		return self.modifier(ScaledFont(name: name, size: size))
	}
}
