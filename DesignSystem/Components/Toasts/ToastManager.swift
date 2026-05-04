//
//  ToastManager.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import SwiftUI
import Combine

// MARK: - Toast Manager (Singleton)
@MainActor
public final class ToastManager: ObservableObject {
	
	public static let shared = ToastManager()
	
	@Published public private(set) var currentToast: ToastValue?
	
	private var dismissTask: Task<Void, Never>?
	private var queue: [ToastValue] = []
	
	private init() {}
	
	// MARK: - Present
	public func present(_ toast: ToastValue) {
		queue.append(toast)
		showNextIfNeeded()
	}
	
	public func present(message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
		let toast = ToastValue(
			icon: Image(systemName: type.defaultIcon),
			message: message,
			type: type,
			duration: duration
		)
		present(toast)
	}
	
	// MARK: - Dismiss
	public func dismiss() {
		dismissTask?.cancel()
		withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
			currentToast = nil
		}
		// Show next in queue after animation
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			self?.showNextIfNeeded()
		}
	}
	
	// MARK: - Async task toast
	public func present<T>(
		message: String,
		task: @escaping () async throws -> T,
		onSuccess: @escaping (T) -> ToastValue,
		onFailure: @escaping (Error) -> ToastValue
	) {
		let loadingToast = ToastValue(
			icon: Image(systemName: "arrow.2.circlepath"),
			message: message,
			type: .loading,
			duration: .infinity  // stays until task completes
		)
		present(loadingToast)
		
		Task {
			do {
				let result = try await task()
				dismiss()
				try? await Task.sleep(nanoseconds: 300_000_000)
				present(onSuccess(result))
			} catch {
				dismiss()
				try? await Task.sleep(nanoseconds: 300_000_000)
				present(onFailure(error))
			}
		}
	}
	
	// MARK: - Private
	private func showNextIfNeeded() {
		guard currentToast == nil, !queue.isEmpty else { return }
		let next = queue.removeFirst()
		withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
			currentToast = next
		}
		scheduleDismiss(for: next)
	}
	
	private func scheduleDismiss(for toast: ToastValue) {
		guard toast.duration != .infinity else { return }
		dismissTask?.cancel()
		dismissTask = Task {
			try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
			guard !Task.isCancelled else { return }
			dismiss()
		}
	}
}
