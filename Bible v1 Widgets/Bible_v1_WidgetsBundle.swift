//
//  Bible_v1_WidgetsBundle.swift
//  Bible v1 Widgets
//
//  Widget bundle containing all Bible widgets
//

import WidgetKit
import SwiftUI

@main
struct Bible_v1_WidgetsBundle: WidgetBundle {
    var body: some Widget {
        VerseOfDayWidget()
        ReadingProgressWidget()
        PrayerReminderWidget()
        HabitTrackerWidget()
        ScriptureQuoteWidget()
        CountdownWidget()
        MoodGratitudeWidget()
        FavoritesWidget()
    }
}

