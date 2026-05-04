//
//  ToastContainerView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import SwiftUI

// MARK: - Toast Container
struct ToastContainerView: View {
	@ObservedObject var manager: ToastManager
	let position: ToastPosition
	
	var body: some View {
		Group {
			if let toast = manager.currentToast {
				ToastView(toast: toast) {
					manager.dismiss()
				}
				.padding(.horizontal, 16)
				.transition(
					.asymmetric(
						insertion: .move(edge: position == .top ? .top : .bottom)
							.combined(with: .opacity)
							.combined(with: .scale(scale: 0.95)),
						removal: .move(edge: position == .top ? .top : .bottom)
							.combined(with: .opacity)
					)
				)
				.id(toast.id)
			}
		}
		.animation(.spring(response: 0.45, dampingFraction: 0.82), value: manager.currentToast?.id)
	}
}
