//
//  PaceSpacing.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/11/26.
//

import SwiftUI

/// Handle Vertical space
struct VSpace: View {
	var height: Double = 10
	
	var body: some View {
		Spacer()
			.frame(height: height)
	}
}

/// Handle Horizontal space
struct HSpace: View {
	var width: Double = 10
	
	var body: some View {
		Spacer()
			.frame(width: width)
	}
}

