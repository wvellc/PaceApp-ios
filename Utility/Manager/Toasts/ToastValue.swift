//
//  ToastValue.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/14/26.
//

import SwiftUI

// MARK: - Toast Type
public enum ToastType {
	case info
	case success
	case error
	case warning
	case loading
	
	var defaultIcon: String {
		switch self {
			case .info:     return "info.circle.fill"
			case .success:  return "checkmark.circle.fill"
			case .error:    return "xmark.circle.fill"
			case .warning:  return "exclamationmark.triangle.fill"
			case .loading:  return "arrow.2.circlepath"
		}
	}
	
	var tintColor: Color {
		switch self {
			case .info:     return .radiantBlue
			case .success:  return .fluorescentMint
			case .error:    return .redBoho
			case .warning:  return .orange
			case .loading:  return .grayHint
		}
	}
}

// MARK: - Toast Button
public struct ToastButton {
	public let title: String
	public let color: Color
	public let action: () -> Void
	
	public init(title: String, color: Color = .blue, action: @escaping () -> Void) {
		self.title = title
		self.color = color
		self.action = action
	}
}

// MARK: - Toast Value
public struct ToastValue: Identifiable {
	public let id = UUID()
	public let icon: Image?
	public let message: String
	public let type: ToastType
	public let duration: TimeInterval
	public let button: ToastButton?
	
	public init(
		icon: Image? = nil,
		message: String,
		type: ToastType = .info,
		duration: TimeInterval = 3.0,
		button: ToastButton? = nil
	) {
		self.icon = icon
		self.message = message
		self.type = type
		self.duration = duration
		self.button = button
	}
	
	// Convenience initializers
	public static func success(_ message: String, icon: Image? = nil, duration: TimeInterval = 3.0) -> ToastValue {
		ToastValue(icon: icon ?? Image(systemName: "checkmark.circle.fill"), message: message, type: .success, duration: duration)
	}
	
	public static func error(_ message: String, icon: Image? = nil, duration: TimeInterval = 3.0) -> ToastValue {
		ToastValue(icon: icon ?? Image(systemName: "xmark.circle.fill"), message: message, type: .error, duration: duration)
	}
	
	public static func warning(_ message: String, icon: Image? = nil, duration: TimeInterval = 3.0) -> ToastValue {
		ToastValue(icon: icon ?? Image(systemName: "exclamationmark.triangle.fill"), message: message, type: .warning, duration: duration)
	}
	
	public static func info(_ message: String, icon: Image? = nil, duration: TimeInterval = 3.0) -> ToastValue {
		ToastValue(icon: icon ?? Image(systemName: "info.circle.fill"), message: message, type: .info, duration: duration)
	}
}
