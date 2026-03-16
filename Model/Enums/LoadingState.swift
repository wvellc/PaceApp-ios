//
//  LoadingState.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/16/26.
//

///Loading state
enum LoadingState {
	case show
	case hide
	
	var isLoading: Bool {
		self == .show
	}
	
	// Use 'mutating' so the function can change the value of the instance
	mutating func hide() {
		self = .hide
	}
	
	mutating func show() {
		self = .show
	}
}
