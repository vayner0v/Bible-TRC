//
//  HabitTrackerIntent.swift
//  Bible v1 Widgets
//
//  AppIntent for Habit Tracker widget configuration
//

import AppIntents
import WidgetKit

/// Configuration intent for the Habit Tracker widget
struct HabitTrackerIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Habit Tracker"
    static var description: IntentDescription = IntentDescription("Customize your habit tracker widget")
    
    @Parameter(title: "Style")
    var stylePreset: StylePresetEntity?
    
    @Parameter(title: "Show Completion Ring", default: true)
    var showCompletionRing: Bool
    
    @Parameter(title: "Show Streak", default: true)
    var showStreak: Bool
    
    var resolvedStylePreset: StylePresetEntity {
        stylePreset ?? .system
    }
    
    init() {
        self.showCompletionRing = true
        self.showStreak = true
    }
    
    init(stylePreset: StylePresetEntity, showCompletionRing: Bool = true, showStreak: Bool = true) {
        self.stylePreset = stylePreset
        self.showCompletionRing = showCompletionRing
        self.showStreak = showStreak
    }
}

/// Timeline provider for Habit Tracker widget
struct HabitTrackerIntentProvider: AppIntentTimelineProvider {
    typealias Entry = HabitTrackerEntry
    typealias Intent = HabitTrackerIntent
    
    func placeholder(in context: Context) -> HabitTrackerEntry {
        HabitTrackerEntry(
            date: Date(),
            data: .placeholder,
            configuration: HabitTrackerIntent()
        )
    }
    
    func snapshot(for configuration: HabitTrackerIntent, in context: Context) async -> HabitTrackerEntry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return HabitTrackerEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: HabitTrackerIntent, in context: Context) async -> Timeline<HabitTrackerEntry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = HabitTrackerEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
        
        // Update every hour
        let nextUpdate = Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

/// Timeline entry for Habit Tracker widget
struct HabitTrackerEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: HabitTrackerIntent
}
