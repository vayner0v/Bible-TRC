//
//  FavoritesIntent.swift
//  Bible v1 Widgets
//
//  AppIntent for Favorites widget configuration
//

import AppIntents
import WidgetKit

/// Configuration intent for the Favorites widget
struct FavoritesIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Favorites"
    static var description: IntentDescription = IntentDescription("Customize your favorites widget")
    
    @Parameter(title: "Style")
    var stylePreset: StylePresetEntity?
    
    @Parameter(title: "Max Verses to Show", default: 3, controlStyle: .stepper, inclusiveRange: (1, 5))
    var maxVersesToShow: Int
    
    var resolvedStylePreset: StylePresetEntity {
        stylePreset ?? .system
    }
    
    init() {
        self.maxVersesToShow = 3
    }
    
    init(stylePreset: StylePresetEntity, maxVersesToShow: Int = 3) {
        self.stylePreset = stylePreset
        self.maxVersesToShow = maxVersesToShow
    }
}

/// Timeline provider for Favorites widget
struct FavoritesIntentProvider: AppIntentTimelineProvider {
    typealias Entry = FavoritesEntry
    typealias Intent = FavoritesIntent
    
    func placeholder(in context: Context) -> FavoritesEntry {
        FavoritesEntry(
            date: Date(),
            data: .placeholder,
            configuration: FavoritesIntent()
        )
    }
    
    func snapshot(for configuration: FavoritesIntent, in context: Context) async -> FavoritesEntry {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        return FavoritesEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
    }
    
    func timeline(for configuration: FavoritesIntent, in context: Context) async -> Timeline<FavoritesEntry> {
        let data = WidgetDataProvider.shared.fetchWidgetData()
        let entry = FavoritesEntry(
            date: Date(),
            data: data,
            configuration: configuration
        )
        
        // Update every hour
        let nextUpdate = Date().addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

/// Timeline entry for Favorites widget
struct FavoritesEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: FavoritesIntent
}
