//
//  TabNavigationState.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 7/3/26.
//
//  Lifts tab navigation state out of lazy TabViews so destinations sit safely on TabBarScreen.
//

import SwiftUI
import Observation

@Observable
final class TabNavigationState {

    // MARK: - Home / History

    /// Activity selected for EventDetailsScreen, consumed by TabBarScreen's destination.
    var selectedActivity: ActivityData?

    /// Activity to duplicate — pushes CreateRunEventScreen in the `.duplicate` flow.
    var duplicateActivity: ActivityData?

    // MARK: - Analytics

    /// Metric selected for AnalyticsDetailScreen, consumed by TabBarScreen's destination.
    var selectedMetric: AnalyticsMetricType?

    /// AnalyticsViewModel captured for AnalyticsDetailScreen.
    var analyticsViewModel: AnalyticsViewModel?
}
