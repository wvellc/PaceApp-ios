//
//  HistoryNoData.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/15/26.
//

import SwiftUI

struct HistoryNoData: View {
	
	@State private var animateContent = false
	
	var body: some View {
		//No Data
		NoDataView(
			icon: .icEmptyHistory,
			title: .readyForYourFirstRun,
			description: .greatThingsStartHereTrackYourFirstEventToUnlockSplitsPaceAnalysisAndPersonalBests
		)
	}
}

