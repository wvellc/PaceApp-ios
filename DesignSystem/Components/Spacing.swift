//
//  PaceSpacing.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

/// Handle Vertical space
struct VSpace: View {
	var height: Double = 8.0
	var isProportional: Bool = true
	
	var body: some View {
		Spacer()
			.frame(height: isProportional ? height.proportionalHeight() : height)
	}
}

/// Handle Horizontal space
struct HSpace: View {
	var width: Double = 8.0
	var isProportional: Bool = true
	
	var body: some View {
		Spacer(minLength: isProportional ? width.proportionalWidth() : width)
			.frame(width: isProportional ? width.proportionalWidth() : width)
	}
}

