//
//  DevelopedByView.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/4/26.
//

import SwiftUI

///Developer by WVE view
struct DevelopedByView : View {
	
	//MARK: States
	let item: SettingsMenuItem
	@Binding var isDevelopedByExpanded: Bool
	
	//MARK: View Builder
	var body: some View {
		VStack(spacing: 0) {
			
			// MARK: Header row — always visible
			HStack(spacing: 16) {
				Circle()
					.fill(.neonAquaBlue)
					.frame(width: 42, height: 42)
					.overlay {
						Image(item.icon)
							.resizable()
							.renderingMode(.template)
							.foregroundStyle(.whiteApp)
							.frame(width: 22, height: 22)
					}
				
				Text(item.title)
					.font(.semiBold16)
					.foregroundStyle(.darkCharcoal)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(Constant.UI.padding12)
			.contentShape(Rectangle())
			.onTapGesture {
				withAnimation(.easeInOut(duration: 0.1)) {
					isDevelopedByExpanded.toggle()
				}
			}
			
			// MARK: Expanded content — WveLabs logo + Visit Website button
			if isDevelopedByExpanded {
				HStack(spacing: 30) {
					
					// WveLabs logo — ZoomIn (scale from 0 → 1, no delay)
					Image(.icWveLabsLogo)
						.resizable()
						.renderingMode(.template)
						.foregroundStyle(.darkCharcoal)
						.scaledToFit()
						.frame(height: 32)
						.transition(
							.scale(scale: 0, anchor: .center)
							.combined(with: .opacity)
						)
						.animation(
							.spring(response: 0.5, dampingFraction: 0.65)
							.delay(0),
							value: isDevelopedByExpanded
						)
					
					// Visit Website button — ZoomIn with 200ms delay
					AppButton(.visitWebsite) {
						if let url = URL(string: NetworkConst.WebUrl.wvelabs) {
							UIApplication.shared.open(url)
						}
					}
					.frame(width: 150, height: 40)
					.transition(
						.scale(scale: 0, anchor: .center)
						.combined(with: .opacity)
					)
					.animation(
						.spring(response: 0.5, dampingFraction: 0.65)
						.delay(0.25),
						value: isDevelopedByExpanded
					)
				}
				.padding(.leading, 20)
				.padding(.bottom, 26)
				.padding(.top, 10)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
		.cardBackground()
		.clipped()
		.animation(.easeInOut(duration: 0.1), value: isDevelopedByExpanded)
	}
}
