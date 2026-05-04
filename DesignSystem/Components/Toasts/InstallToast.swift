//
//  InstallToast.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import SwiftUI

// MARK: - Toast Position
public enum ToastPosition {
	case top
	case bottom
}

// MARK: - Environment Key for presentToast
private struct PresentToastKey: EnvironmentKey {
	static let defaultValue: (ToastValue) -> Void = { toast in
		Task { @MainActor in
			ToastManager.shared.present(toast)
		}
	}
}

extension EnvironmentValues {
	public var presentToast: (ToastValue) -> Void {
		get { self[PresentToastKey.self] }
		set { self[PresentToastKey.self] = newValue }
	}
}

// MARK: - Install Toast Modifier
struct InstallToastModifier: ViewModifier {
	let position: ToastPosition
	@StateObject private var manager = ToastManager.shared
	
	func body(content: Content) -> some View {
		content
			.environment(\.presentToast) { toast in
				manager.present(toast)
			}
			.overlay(alignment: position == .top ? .top : .bottom) {
				ToastContainerView(manager: manager, position: position)
//					.padding(.top, position == .top ? safeAreaTop() : 0)
//					.padding(.bottom, position == .bottom ? safeAreaBottom() : 0)
					.padding(position == .top ? .top : .bottom, 8)
			}
	}
	
	private func safeAreaTop() -> CGFloat {
		(UIApplication.shared.connectedScenes.first as? UIWindowScene)?
			.windows.first?.safeAreaInsets.top ?? 0
	}
	
	private func safeAreaBottom() -> CGFloat {
		(UIApplication.shared.connectedScenes.first as? UIWindowScene)?
			.windows.first?.safeAreaInsets.bottom ?? 0
	}
}

public extension View {
	func installToast(position: ToastPosition = .bottom) -> some View {
		modifier(InstallToastModifier(position: position))
	}
}
