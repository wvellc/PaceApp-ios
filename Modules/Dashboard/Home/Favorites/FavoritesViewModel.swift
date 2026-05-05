//
//  FavoritesViewModel.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/5/26.
//

import Observation

@Observable
final class FavoritesViewModel {
	
	// MARK: - Activities Data
	final var favRuns: [RecentActivity] = [
		RecentActivity(
			title: "Thursday Run",
			date: makeDate(day: 29, month: 1),
			distance: "5.00 mi",
			duration: "0:45",
			avgPace: "9:00 /mi",
			delta: "+01:10",
			deltaColor: .redBoho,
			location: "New York City"
		),
		RecentActivity(
			title: "Saturday Long Run",
			date: makeDate(day: 31, month: 1),
			distance: "12.00 mi",
			duration: "1:48",
			avgPace: "9:00 /mi",
			delta: "-00:15",
			deltaColor: .fluorescentMint,
			location: "Central Park"
		),
		RecentActivity(
			title: "Monday Recovery",
			date: makeDate(day: 2, month: 2),
			distance: "3.50 mi",
			duration: "0:33",
			avgPace: "9:30 /mi",
			delta: "+00:45",
			deltaColor: .redBoho,
			location: "Brooklyn"
		),
		RecentActivity(
			title: "Wednesday Tempo",
			date: makeDate(day: 4, month: 2),
			distance: "6.20 mi",
			duration: "0:49",
			avgPace: "7:55 /mi",
			delta: "-01:20",
			deltaColor: .fluorescentMint,
			location: "Queens"
		)
	]
	
	
	//MARK: Methods
	// Handle the swipe-to-unfavorite action
	func unFavorite(run: RecentActivity) {
		if let index = favRuns.firstIndex(where: { $0.id == run.id }) {
			favRuns.remove(at: index)
		}
	}

}
