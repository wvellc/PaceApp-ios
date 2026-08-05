//
//  AppWebViewScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/16/26.
//

import SwiftUI

/// App Web View Screen
struct AppWebViewScreen: View {
    
	//MARK: Property wrapper
    let requestUrl: String
    let title: String?
	@State private var errorMessage: String? = nil

	//MARK: Intializer
    init(requestUrl: String, title: String? = nil, errorMessage: String? = nil) {
        self.requestUrl = requestUrl
        self.title = title
        self.errorMessage = errorMessage
    }
    
	//MARK: View Builder
    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text(errorMessage)
					.font(.medium18)
					.foregroundColor(.redBoho)
                    .padding()
            }
            
            WebView(url: URL(string: requestUrl)!, errorMessage: $errorMessage)
                .edgesIgnoringSafeArea(.all)
        }
		.navigationAppTitle(title: .init(stringLiteral: (title ?? "").uppercased()))
    }
}


#Preview {
	AppWebViewScreen(requestUrl: NetworkConst.WebUrl.privacyPolicy, title: nil)
}
