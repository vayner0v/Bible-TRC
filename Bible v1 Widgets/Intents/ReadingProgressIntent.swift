//
//  ReadingProgressIntent.swift
//  Bible v1 Widgets
//
//  AppIntent for Reading Progress widget configuration
//

import AppIntents
import WidgetKit

/// Configuration intent for the Reading Progress widget
struct ReadingProgressIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Reading Progress"
    static var description: IntentDescription = IntentDescription("Customize your reading progress widget")
    
    @Parameter(title: "Style")
    var stylePreset: StylePresetEntity?
    
    @Parameter(title: "Show Percentage", default: true)
    var showPercentage: Bool
    
    @Parameter(title: "Show Streak", default: true)
    var showStreak: Bool
    
    var resolvedStylePreset: StylePresetEntity {
        stylePreset ?? .system
    }
    
    init() {
        self.showPercentage = true
        self.showStreak = true
    }
    
    init(stylePreset: StylePresetEntity, showPercentage: Bool = true, showStreak: Bool = true) {
        self.stylePreset = stylePreset
        self.showPercentage = showPercentage
        self.showStreak = showStreak
    }
}

/// Timeline provider for Reading Progress widget
struct ReadingProgressIntentProvider: AppIntentTimelineProvider {
    typealias Entry = ReadingProgressEntry
    typealias Intent = ReadingProgressIntent
    
    func placeholder(in context: Context) -> ReadingProgressEntry {
        ReadingProgressEntry(
            date: Date(),
            data: .placeholder,
            configuration: ReadingProgressIntent()
        )
    }
    
    func snapshot(for configuration: ReadingProgressIntent, in context: Context) async -> ReadingProgressEntry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return ReadingProgressEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: ReadingProgressIntent, in context: Context) async -> Timeline<ReadingProgressEntry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = ReadingProgressEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
        
        // Update every hour
        let nextUpdate = Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

/// Timeline entry for Reading Progress widget
struct ReadingProgressEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: ReadingProgressIntent
}
