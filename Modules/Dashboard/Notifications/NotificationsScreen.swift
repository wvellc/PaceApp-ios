//
//  NotificationsScreen.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/23/26.
//

import SwiftUI

struct NotificationsScreen: View {
	
	//MARK: States
	@State private var viewModel = NotificationsViewModel()
	
	
	//MARK: View Builder
	var body: some View {
		// Notifications List
		VStack {
			if !viewModel.notifications.isEmpty {
				List {
					ForEach(viewModel.notifications) { notification in
						NotificationCard(notification: notification)
						// Remove default list padding and backgrounds to make it look like a floating card
							.listRowInsets(EdgeInsets(top: 8, leading: Constant.UI.defaultPadding, bottom: 8, trailing: Constant.UI.defaultPadding))
							.listRowBackground(Color.clear)
							.listRowSeparator(.hidden)
						
						
						//Swipe to Delete (Matches the second image)
							.swipeActions(edge: .trailing, allowsFullSwipe: true) {
								Button(role: .destructive) {
									withAnimation {
										viewModel.delete(notification: notification)
									}
								} label: {
									Image(.icDelete)
								}
								.tint(.redBoho)
							}
					}
				}
				.listStyle(.plain)
				.padding(.top, Constant.UI.defaultPadding / 2)
				
			} else {

				Rectangle()
					.foregroundStyle(.clear)
					.safeAreaPadding()
					.overlay {
						NoDataView(
							icon: .icEmptyNotification,
							title: .noNotificationsYet,
							description: .youDontHaveAnyNotificationsRightNow
						)
					}
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(.hidden, for: .navigationBar)
		.toolbarBackground(.clear, for: .navigationBar)
		.toolbar {
			ToolbarItem(placement: .principal) {
				Text(.notifications)
					.font(.medium16)
					.foregroundStyle(.whiteApp)
			}

			ToolbarItem(placement: .topBarTrailing) {
				Button(action: { viewModel.clearAllNotification() }) {
					Image(.icClearAll)
						.resizable()
						.scaledToFit()
						.foregroundStyle(.whiteApp)
						.frame(width: 19.20, height: 19.20)
				}
				.opacity(viewModel.notifications.isEmpty ? 0 : 1)
				.disabled(viewModel.notifications.isEmpty)
			}
		}
		.appBackground()
	}
	
	
}

#Preview {
	NavigationStack {
		NotificationsScreen()
	}
}
