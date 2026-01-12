//
//  VerseOfDayIntent.swift
//  Bible v1 Widgets
//
//  AppIntent for Verse of the Day widget configuration
//

import AppIntents
import WidgetKit

/// Configuration intent for the Verse of the Day widget
struct VerseOfDayIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Verse Widget"
    static var description: IntentDescription = IntentDescription("Customize your verse of the day widget")
    
    @Parameter(title: "My Design")
    var savedWidget: SavedWidgetEntity?
    
    @Parameter(title: "Style Preset")
    var stylePreset: StylePresetEntity?
    
    var resolvedStylePreset: StylePresetEntity {
        stylePreset ?? .system
    }
    
    var resolvedSavedWidget: SavedWidgetEntity? {
        savedWidget
    }
    
    init() {}
    
    init(stylePreset: StylePresetEntity) {
        self.stylePreset = stylePreset
    }
    
    init(savedWidget: SavedWidgetEntity) {
        self.savedWidget = savedWidget
    }
}

/// Timeline provider for Verse of Day widget with intent support
struct VerseOfDayIntentProvider: AppIntentTimelineProvider {
    typealias Entry = VerseOfDayEntry
    typealias Intent = VerseOfDayIntent
    
    func placeholder(in context: Context) -> VerseOfDayEntry {
        VerseOfDayEntry(
            date: Date(),
            data: .placeholder,
            stylePreset: .system,
            savedWidget: nil
        )
    }
    
    func snapshot(for configuration: VerseOfDayIntent, in context: Context) async -> VerseOfDayEntry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return VerseOfDayEntry(
            date: Date(),
            data: data,
            stylePreset: configuration.resolvedStylePreset,
            savedWidget: configuration.resolvedSavedWidget
        )
    }
    
    func timeline(for configuration: VerseOfDayIntent, in context: Context) async -> Timeline<VerseOfDayEntry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = VerseOfDayEntry(
            date: Date(),
            data: data,
            stylePreset: configuration.resolvedStylePreset,
            savedWidget: configuration.resolvedSavedWidget
        )
        
        // Update at midnight for new verse
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: Date().addingTimeInterval(86400))
        
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
}

/// Timeline entry for Verse of Day widget
struct VerseOfDayEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let stylePreset: StylePresetEntity
    let savedWidget: SavedWidgetEntity?
}
