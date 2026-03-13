//
//  LoginScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//

import SwiftUI

///Login screen (Email + Phone )
struct LoginScreen: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showSafari = false
    @State private var legalURL: URL? = nil
    
    var body: some View {
		BackgroundContainer {
			VStack(spacing: 0) {
				
				// Logo Section
				VStack {
					VSpace(height: 107)
					LogoWithText()
					VSpace(height: 111)
				}
				
				// Login Form Container
				VStack(alignment: .center, spacing: 24) {
					
					Text(.loginToYourAccount)
						.font(.medium20)
						.foregroundColor(.whiteApp)

					// Segment Toggle
					AppSegmentedControl(
						selection: $viewModel.loginType,
						segments: [
							(key: .email, title: "Email"),
							(key: .phoneNumber, title: "Phone Number")
						]
					)
					
					// Input Fields
					if viewModel.loginType == .email {
						TextField(.emailAddress, text: $viewModel.email)
							.font(.medium16)
							.foregroundColor(.whiteApp)
							.padding()
							.background(Color.clear)
							.overlay(
								RoundedRectangle(cornerRadius: 12)
									.stroke(Color.white.opacity(0.2), lineWidth: 1)
							)
					} else {
						HStack(spacing: 12) {
							// Country Code Dropdown
							HStack(spacing: 6) {
								Text(viewModel.countryCode)
									.font(.medium18)
									.foregroundColor(.whiteApp)
								Image(systemName: "chevron.down")
									.foregroundColor(.whiteApp)
									.font(.system(size: 14, weight: .medium))
							}
							.padding(.horizontal, 16)
							.padding(.vertical, 16)
							.background(Color.clear)
							.overlay(
								RoundedRectangle(cornerRadius: 12)
									.stroke(Color.white.opacity(0.2), lineWidth: 1)
							)
							
							// Phone Input
							TextField("81313782626", text: $viewModel.phoneNumber)
								.keyboardType(.phonePad)
								.font(.medium18)
								.foregroundColor(.whiteApp)
								.padding()
								.background(Color.clear)
								.overlay(
									RoundedRectangle(cornerRadius: 12)
										.stroke(Color.white.opacity(0.2), lineWidth: 1)
								)
						}
					}

					// Send OTP Button
					AppButton(.sendOtp) {
						Task { await viewModel.sendOTP() }
					}
					
					if viewModel.isLoading {
						ProgressView()
							.tint(.white)
					}
					if let error = viewModel.errorMessage {
						Text(error)
							.font(.medium14)
							.foregroundColor(.red)
					}
					
					// Terms & Privacy
					VStack(spacing: 6) {
						Text("By continuing, you agree to our")
							.font(.medium16)
							.foregroundColor(.grayHint)
							.multilineTextAlignment(.center)
							.lineSpacing(2.5)

						HStack(spacing: 6) {
							Button(action: { presentLegal(urlString: "https://paceapp.net") }) {
								Text("Terms of Service")
									.font(.semiBold16)
									.foregroundColor(.whiteApp)
							}
							Text("and")
								.font(.medium16)
								.foregroundColor(.grayHint)
							Button(action: { presentLegal(urlString: "https://paceapp.net") }) {
								Text("Privacy Policy.")
									.font(.semiBold16)
									.foregroundColor(.whiteApp)
							}
						}
					}
					.padding(.bottom, 24 + 16)
				}
				.padding(.horizontal, 16)
				
				Spacer()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
		.sheet(isPresented: $showSafari) {
			if let url = legalURL {
				SafariWebView(url: url)
					.ignoresSafeArea()
			}
		}
		.onTapGesture {
			UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
		}
    }
	
	private func presentLegal(urlString: String) {
		if let url = URL(string: urlString) {
			legalURL = url
			showSafari = true
		}
	}
}

#Preview {
    LoginScreen()
}

import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor.white
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No dynamic updates needed.
    }
}

