//
//  WebView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/16/26.
//


import WebKit
import SwiftUI

/// URL Based Web View for internal use
struct WebView: UIViewRepresentable {
	
	//MARK: Properties
	var url: URL
	@Binding var errorMessage: String? // Binding to show error messages in the UI
	
	//MARK: Method's
	func makeUIView(context: Context) -> WKWebView {
		let webView = WKWebView()
		webView.navigationDelegate = context.coordinator // Set the coordinator as the delegate
		
		// Add loading indicator
		let indicator = UIActivityIndicatorView(style: .large)
		indicator.startAnimating()
		indicator.color = .radiantBlue
		indicator.tag = 999 // Assign a tag for later identification
		indicator.translatesAutoresizingMaskIntoConstraints = false
		webView.addSubview(indicator)
		
		// Center the indicator
		NSLayoutConstraint.activate([
			indicator.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
			indicator.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
		])
		
		return webView
	}
	
	func updateUIView(_ uiView: WKWebView, context: Context) {
		let request = URLRequest(url: url)
		uiView.load(request)
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator(errorMessage: $errorMessage)
	}
	
	class Coordinator: NSObject, WKNavigationDelegate {
		@Binding var errorMessage: String?
		
		init(errorMessage: Binding<String?>) {
			_errorMessage = errorMessage
		}
		
		// Method to handle errors during web page loading
		func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
			errorMessage = "Failed to load the page: \(error.localizedDescription)"
			removeLoadingIndicator(from: webView)
		}
		
		func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
			errorMessage = "Failed to load the page: \(error.localizedDescription)"
			removeLoadingIndicator(from: webView)
		}
		
		// Handle when navigation finishes successfully
		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			errorMessage = nil // Clear the error message if page loaded successfully
			removeLoadingIndicator(from: webView)
		}
		
		// Helper method to remove the loading indicator
		private func removeLoadingIndicator(from webView: WKWebView) {
			if let indicator = webView.viewWithTag(999) as? UIActivityIndicatorView {
				indicator.stopAnimating()
				indicator.removeFromSuperview()
			}
		}
	}
}
