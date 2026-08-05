//
//  SafariView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/23/26.
//

import SafariServices
import SwiftUI

/// Wraps SFSafariViewController so a URL can be opened in-app via Safari, presented as a sheet.
struct SafariView: UIViewControllerRepresentable {
	
	// MARK: - Properties
	let url: URL
	
	// MARK: - UIViewControllerRepresentable
	func makeUIViewController(context: Context) -> SFSafariViewController {
		let configuration = SFSafariViewController.Configuration()
		configuration.entersReaderIfAvailable = false
		let controller = SFSafariViewController(url: url, configuration: configuration)
		controller.preferredControlTintColor = UIColor(Color.neonAquaBlue)
		return controller
	}
	
	func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
		// Static URL — nothing to update after creation.
	}
}
