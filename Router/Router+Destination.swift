//
//  Router+Destination.swift
//  pace
//	Created by FURKAN VIJAPURA on 3/12/26.

//  Maps every `Destinations` case to its SwiftUI view.
//

import SwiftUI

/// Router management
extension Router {
	
	// MARK: - Root view resolver
	
	/// Returns the correct entry-point view for the current `root` flow.
	@ViewBuilder
	func rootView() -> some View {
		switch root {
			case .welcome: WelcomeScreen()
			case .auth:       LoginScreen()
			case .dashboard:  DashboardView()   //tab-bar
		}
	}
	
	// MARK: - Destination resolver
	
	/// Resolves a `Destinations` case into its SwiftUI view.
	@ViewBuilder
	func destination(for destination: Destinations) -> some View {
		switch destination {
				
				// ----------------------------------------------------------------
				// MARK: Auth
				// ----------------------------------------------------------------
				
			case .login			: LoginScreen()
			case .createAccount	: CreateAccountScreen()
			case .verifyOTP		: EmptyView()

				// ----------------------------------------------------------------
				// MARK: Home
				// ----------------------------------------------------------------
				
			case .home			: EmptyView()
				
				// ----------------------------------------------------------------
				// MARK: Profile
				// ----------------------------------------------------------------
				
			case .profile		: EmptyView()
		
				
				// ----------------------------------------------------------------
				// MARK: Settings
				// ----------------------------------------------------------------
				
			case .settings		: EmptyView()
			case .termsOfService:
				AppWebViewScreen(
					requestUrl: NetworkConst.WebUrl.termsOfService
				)
			case .privacyPolicy	:
				AppWebViewScreen(
					requestUrl: NetworkConst.WebUrl.privacyPolicy
				)
			
		}
	}
}
