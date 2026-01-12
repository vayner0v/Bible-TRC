//
//  CountdownIntent.swift
//  Bible v1 Widgets
//
//  AppIntent for Countdown widget configuration
//

import AppIntents
import WidgetKit

/// Configuration intent for the Countdown widget
struct CountdownIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Countdown"
    static var description: IntentDescription = IntentDescription("Customize your countdown widget")
    
    @Parameter(title: "Style")
    var stylePreset: StylePresetEntity?
    
    var resolvedStylePreset: StylePresetEntity {
        stylePreset ?? .system
    }
    
    init() {}
    
    init(stylePreset: StylePresetEntity) {
        self.stylePreset = stylePreset
    }
}

/// Timeline provider for Countdown widget
struct CountdownIntentProvider: AppIntentTimelineProvider {
    typealias Entry = CountdownEntry
    typealias Intent = CountdownIntent
    
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            data: .placeholder,
            configuration: CountdownIntent()
        )
    }
    
    func snapshot(for configuration: CountdownIntent, in context: Context) async -> CountdownEntry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return CountdownEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: CountdownIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = CountdownEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
        
        // Update at midnight
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
}

/// Timeline entry for Countdown widget
struct CountdownEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: CountdownIntent
}
