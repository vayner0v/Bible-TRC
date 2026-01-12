//
//  WidgetDataProvider.swift
//  Bible v1 Widgets
//
//  Shared data provider for widget timelines
//

import Foundation
import WidgetKit

// MARK: - App Group Constants

enum WidgetAppGroup {
    static let suiteName = "group.vaynerov.Bible-v1"
    static let widgetDataKey = "widget_data"
    static let widgetConfigsKey = "widget_configs"
}

// MARK: - Widget Data Provider

/// Provides data from App Group for widget timelines
struct WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private let userDefaults: UserDefaults?
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: WidgetAppGroup.suiteName)
    }
    
    /// Fetch widget data from App Group
    func fetchWidgetData() -> WidgetDisplayData {
        guard let data = userDefaults?.data(forKey: WidgetAppGroup.widgetDataKey),
              let widgetData = try? JSONDecoder().decode(WidgetDataStorage.self, from: data) else {
            return .placeholder
        }
        
        return WidgetDisplayData(
            verseOfDayText: widgetData.verseOfDayText ?? "\"For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.\"",
            verseOfDayReference: widgetData.verseOfDayReference ?? "John 3:16",
            readingPlanName: widgetData.readingPlanName ?? "Getting Started",
            readingProgress: widgetData.readingProgress ?? 0.0,
            readingStreak: widgetData.readingStreak ?? 0,
            currentDay: widgetData.currentDay ?? 1,
            totalDays: widgetData.totalDays ?? 7,
            activePrayerCount: widgetData.activePrayerCount ?? 0,
            answeredPrayerCount: widgetData.answeredPrayerCount ?? 0,
            todayHabitProgress: widgetData.todayHabitProgress ?? 0.0,
            completedHabits: widgetData.completedHabits ?? 0,
            totalHabits: widgetData.totalHabits ?? 0,
            habitStreak: widgetData.habitStreak ?? 0,
            countdownTitle: widgetData.countdownTitle ?? "Countdown",
            countdownDate: widgetData.countdownTargetDate ?? Date().addingTimeInterval(86400 * 14),
            lastMood: widgetData.lastMood ?? "😊",
            moodHistory: widgetData.moodHistory ?? [],
            gratitudeStreak: widgetData.gratitudeStreak ?? 0,
            todayGratitudeCompleted: widgetData.todayGratitudeCompleted ?? false,
            favoriteVerses: widgetData.favoriteVerses ?? [],
            appTheme: widgetData.appTheme ?? "light",
            lastUpdated: widgetData.lastUpdated ?? Date()
        )
    }
    
    /// Fetch saved widget configurations
    func fetchWidgetConfigs() -> [WidgetConfigStorage] {
        // Try simplified format first (from widget extension)
        if let data = userDefaults?.data(forKey: "widget_configs_simplified"),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return jsonArray.compactMap { dict -> WidgetConfigStorage? in
                guard let id = dict["id"] as? String,
                      let name = dict["name"] as? String,
                      let widgetType = dict["widgetType"] as? String,
                      let size = dict["size"] as? String else {
                    return nil
                }
                return WidgetConfigStorage(
                    id: id,
                    widgetType: widgetType,
                    size: size,
                    name: name,
                    presetId: dict["presetId"] as? String,
                    backgroundType: "solid",
                    backgroundColor: nil,
                    gradientColors: nil,
                    gradientStartPoint: nil,
                    gradientEndPoint: nil,
                    patternName: nil,
                    titleFontFamily: nil,
                    titleFontSize: nil,
                    titleFontWeight: nil,
                    titleColor: nil,
                    bodyFontFamily: nil,
                    bodyFontSize: nil,
                    bodyFontWeight: nil,
                    bodyColor: nil,
                    textAlignment: nil,
                    cornerStyle: nil,
                    padding: nil,
                    showShadow: nil,
                    selectedVerseReference: nil,
                    translationId: nil,
                    showPercentage: nil,
                    showStreak: nil,
                    countdownTitle: nil,
                    countdownDate: nil,
                    maxFavoritesToShow: nil
                )
            }
        }
        
        // Fall back to trying to decode full format
        guard let data = userDefaults?.data(forKey: WidgetAppGroup.widgetConfigsKey),
              let configs = try? JSONDecoder().decode([WidgetConfigStorage].self, from: data) else {
            return []
        }
        return configs
    }
    
    /// Get a specific widget configuration by ID
    func getConfig(id: String) -> WidgetConfigStorage? {
        fetchWidgetConfigs().first { $0.id == id }
    }
}

// MARK: - Storage Models (Matching main app's WidgetData)

/// Storage model for widget data - matches the app's WidgetData structure
struct WidgetDataStorage: Codable {
    var verseOfDayText: String?
    var verseOfDayReference: String?
    var readingPlanName: String?
    var readingProgress: Double?
    var readingStreak: Int?
    var currentDay: Int?
    var totalDays: Int?
    var activePrayerCount: Int?
    var answeredPrayerCount: Int?
    var lastPrayerTime: Date?
    var todayHabitProgress: Double?
    var completedHabits: Int?
    var totalHabits: Int?
    var habitStreak: Int?
    var favoriteVerses: [FavoriteVerseStorage]?
    var lastMood: String?
    var moodHistory: [String]?
    var lastMoodDate: Date?
    var gratitudeStreak: Int?
    var todayGratitudeCompleted: Bool?
    var countdownTargetDate: Date?
    var countdownTitle: String?
    var lastUpdated: Date?
    var appTheme: String?
}

/// Favorite verse storage for widgets
struct FavoriteVerseStorage: Codable, Equatable {
    let reference: String
    let text: String
    let bookName: String
    let chapter: Int
    let verse: Int
}

/// Widget configuration storage - mirrors main app's WidgetConfig
struct WidgetConfigStorage: Codable, Identifiable {
    let id: String
    var widgetType: String
    var size: String
    var name: String
    var presetId: String?
    
    // Styling
    var backgroundType: String // "solid", "gradient", "pattern"
    var backgroundColor: CodableColorStorage?
    var gradientColors: [CodableColorStorage]?
    var gradientStartPoint: String?
    var gradientEndPoint: String?
    var patternName: String?
    
    var titleFontFamily: String?
    var titleFontSize: String?
    var titleFontWeight: String?
    var titleColor: CodableColorStorage?
    
    var bodyFontFamily: String?
    var bodyFontSize: String?
    var bodyFontWeight: String?
    var bodyColor: CodableColorStorage?
    
    var textAlignment: String?
    var cornerStyle: String?
    var padding: String?
    var showShadow: Bool?
    
    // Content config
    var selectedVerseReference: String?
    var translationId: String?
    var showPercentage: Bool?
    var showStreak: Bool?
    var countdownTitle: String?
    var countdownDate: Date?
    var maxFavoritesToShow: Int?
}

/// Codable color storage
struct CodableColorStorage: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
}

// MARK: - Display Data

/// Display-ready data for widgets
struct WidgetDisplayData {
    let verseOfDayText: String
    let verseOfDayReference: String
    let readingPlanName: String
    let readingProgress: Double
    let readingStreak: Int
    let currentDay: Int
    let totalDays: Int
    let activePrayerCount: Int
    let answeredPrayerCount: Int
    let todayHabitProgress: Double
    let completedHabits: Int
    let totalHabits: Int
    let habitStreak: Int
    let countdownTitle: String
    let countdownDate: Date
    let lastMood: String
    let moodHistory: [String]
    let gratitudeStreak: Int
    let todayGratitudeCompleted: Bool
    let favoriteVerses: [FavoriteVerseStorage]
    let appTheme: String
    let lastUpdated: Date
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: countdownDate)
        return max(0, calendar.dateComponents([.day], from: today, to: target).day ?? 0)
    }
    
    static var placeholder: WidgetDisplayData {
        WidgetDisplayData(
            verseOfDayText: "\"For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.\"",
            verseOfDayReference: "John 3:16",
            readingPlanName: "Getting Started",
            readingProgress: 0.4,
            readingStreak: 7,
            currentDay: 12,
            totalDays: 30,
            activePrayerCount: 5,
            answeredPrayerCount: 12,
            todayHabitProgress: 0.6,
            completedHabits: 3,
            totalHabits: 5,
            habitStreak: 7,
            countdownTitle: "Easter",
            countdownDate: Date().addingTimeInterval(86400 * 14),
            lastMood: "😊",
            moodHistory: ["😊", "😌", "🙏", "😔", "😊"],
            gratitudeStreak: 5,
            todayGratitudeCompleted: false,
            favoriteVerses: [
                FavoriteVerseStorage(reference: "John 3:16", text: "For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life.", bookName: "John", chapter: 3, verse: 16),
                FavoriteVerseStorage(reference: "Psalm 23:1", text: "The Lord is my shepherd; I shall not want.", bookName: "Psalms", chapter: 23, verse: 1),
                FavoriteVerseStorage(reference: "Philippians 4:13", text: "I can do all things through Christ who strengthens me.", bookName: "Philippians", chapter: 4, verse: 13)
            ],
            appTheme: "light",
            lastUpdated: Date()
        )
    }
}

// MARK: - Timeline Entry

/// Common timeline entry for all widgets
struct BibleWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: WidgetIntentConfiguration?
    
    static var placeholder: BibleWidgetEntry {
        BibleWidgetEntry(date: Date(), data: .placeholder, configuration: nil)
    }
}

/// Intent configuration passed from AppIntent to widget view
struct WidgetIntentConfiguration {
    // Style preset
    var presetId: String?
    var savedConfigId: String?
    
    // Style overrides
    var backgroundStyle: BackgroundStyleConfig?
    var titleColor: CodableColorStorage?
    var bodyColor: CodableColorStorage?
    
    // Content options (widget-specific)
    var showPercentage: Bool = true
    var showStreak: Bool = true
    var selectedVerseReference: String?
    var translationId: String?
    var countdownTitle: String?
    var countdownDate: Date?
    var maxFavoritesToShow: Int = 3
}

/// Background style configuration
struct BackgroundStyleConfig {
    enum StyleType {
        case solid(color: CodableColorStorage)
        case gradient(colors: [CodableColorStorage], start: String, end: String)
        case pattern(name: String, baseColor: CodableColorStorage)
    }
    
    var styleType: StyleType
}
