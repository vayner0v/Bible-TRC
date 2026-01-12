//
//  PrayerReminderIntent.swift
//  Bible v1 Widgets
//
//  AppIntent for Prayer Reminder widget configuration
//

import AppIntents
import WidgetKit

/// Configuration intent for the Prayer Reminder widget
struct PrayerReminderIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Prayer Widget"
    static var description: IntentDescription = IntentDescription("Customize your prayer reminder widget")
    
    @Parameter(title: "Style")
    var stylePreset: StylePresetEntity?
    
    @Parameter(title: "Show Prayer Count", default: true)
    var showPrayerCount: Bool
    
    var resolvedStylePreset: StylePresetEntity {
        stylePreset ?? .system
    }
    
    init() {
        self.showPrayerCount = true
    }
    
    init(stylePreset: StylePresetEntity, showPrayerCount: Bool = true) {
        self.stylePreset = stylePreset
        self.showPrayerCount = showPrayerCount
    }
}

/// Timeline provider for Prayer Reminder widget
struct PrayerReminderIntentProvider: AppIntentTimelineProvider {
    typealias Entry = PrayerReminderEntry
    typealias Intent = PrayerReminderIntent
    
    func placeholder(in context: Context) -> PrayerReminderEntry {
        PrayerReminderEntry(
            date: Date(),
            data: .placeholder,
            configuration: PrayerReminderIntent()
        )
    }
    
    func snapshot(for configuration: PrayerReminderIntent, in context: Context) async -> PrayerReminderEntry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return PrayerReminderEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: PrayerReminderIntent, in context: Context) async -> Timeline<PrayerReminderEntry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = PrayerReminderEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
        
        // Update every 30 minutes
        let nextUpdate = Date().addingTimeInterval(1800)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

/// Timeline entry for Prayer Reminder widget
struct PrayerReminderEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: PrayerReminderIntent
}
