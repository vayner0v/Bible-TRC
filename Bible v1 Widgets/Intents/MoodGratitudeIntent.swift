//
//  MoodGratitudeIntent.swift
//  Bible v1 Widgets
//
//  AppIntent for Mood & Gratitude widget configuration
//

import AppIntents
import WidgetKit

/// Configuration intent for the Mood & Gratitude widget
struct MoodGratitudeIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Mood & Gratitude"
    static var description: IntentDescription = IntentDescription("Customize your mood and gratitude widget")
    
    @Parameter(title: "Style")
    var stylePreset: StylePresetEntity?
    
    @Parameter(title: "Show Mood History", default: true)
    var showMoodHistory: Bool
    
    @Parameter(title: "Show Gratitude Prompt", default: true)
    var showGratitudePrompt: Bool
    
    var resolvedStylePreset: StylePresetEntity {
        stylePreset ?? .system
    }
    
    init() {
        self.showMoodHistory = true
        self.showGratitudePrompt = true
    }
    
    init(stylePreset: StylePresetEntity, showMoodHistory: Bool = true, showGratitudePrompt: Bool = true) {
        self.stylePreset = stylePreset
        self.showMoodHistory = showMoodHistory
        self.showGratitudePrompt = showGratitudePrompt
    }
}

/// Timeline provider for Mood & Gratitude widget
struct MoodGratitudeIntentProvider: AppIntentTimelineProvider {
    typealias Entry = MoodGratitudeEntry
    typealias Intent = MoodGratitudeIntent
    
    func placeholder(in context: Context) -> MoodGratitudeEntry {
        MoodGratitudeEntry(
            date: Date(),
            data: .placeholder,
            configuration: MoodGratitudeIntent()
        )
    }
    
    func snapshot(for configuration: MoodGratitudeIntent, in context: Context) async -> MoodGratitudeEntry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return MoodGratitudeEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: MoodGratitudeIntent, in context: Context) async -> Timeline<MoodGratitudeEntry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = MoodGratitudeEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
        
        // Update every hour
        let nextUpdate = Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

/// Timeline entry for Mood & Gratitude widget
struct MoodGratitudeEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: MoodGratitudeIntent
}
