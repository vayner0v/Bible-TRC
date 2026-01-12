//
//  ScriptureQuoteIntent.swift
//  Bible v1 Widgets
//
//  AppIntent for Scripture Quote widget configuration
//

import AppIntents
import WidgetKit

/// Configuration intent for the Scripture Quote widget
struct ScriptureQuoteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Scripture Quote"
    static var description: IntentDescription = IntentDescription("Customize your scripture quote widget")
    
    @Parameter(title: "Style")
    var stylePreset: StylePresetEntity?
    
    @Parameter(title: "Use Verse of the Day", default: true)
    var useVerseOfDay: Bool
    
    var resolvedStylePreset: StylePresetEntity {
        stylePreset ?? .system
    }
    
    init() {
        self.useVerseOfDay = true
    }
    
    init(stylePreset: StylePresetEntity, useVerseOfDay: Bool = true) {
        self.stylePreset = stylePreset
        self.useVerseOfDay = useVerseOfDay
    }
}

/// Timeline provider for Scripture Quote widget
struct ScriptureQuoteIntentProvider: AppIntentTimelineProvider {
    typealias Entry = ScriptureQuoteEntry
    typealias Intent = ScriptureQuoteIntent
    
    func placeholder(in context: Context) -> ScriptureQuoteEntry {
        ScriptureQuoteEntry(
            date: Date(),
            data: .placeholder,
            configuration: ScriptureQuoteIntent()
        )
    }
    
    func snapshot(for configuration: ScriptureQuoteIntent, in context: Context) async -> ScriptureQuoteEntry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return ScriptureQuoteEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: ScriptureQuoteIntent, in context: Context) async -> Timeline<ScriptureQuoteEntry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = ScriptureQuoteEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
        
        // Update daily
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
}

/// Timeline entry for Scripture Quote widget
struct ScriptureQuoteEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: ScriptureQuoteIntent
}
