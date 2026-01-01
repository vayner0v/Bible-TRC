//
//  WidgetDataProvider.swift
//  Bible v1 Widgets
//
//  Shared data provider for widget timelines
//

import Foundation
import WidgetKit

/// Provides data from App Group for widget timelines
struct WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private let userDefaults: UserDefaults?
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: "group.vaynerov.Bible-v1")
    }
    
    /// Fetch widget data from App Group
    func fetchWidgetData() -> WidgetDisplayData {
        guard let data = userDefaults?.data(forKey: "widget_data"),
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
            gratitudeStreak: widgetData.gratitudeStreak ?? 0,
            todayGratitudeCompleted: widgetData.todayGratitudeCompleted ?? false,
            favoriteVerses: widgetData.favoriteVerses ?? [],
            lastUpdated: widgetData.lastUpdated ?? Date()
        )
    }
}

/// Storage model matching the app's WidgetData
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
    var lastMoodDate: Date?
    var gratitudeStreak: Int?
    var todayGratitudeCompleted: Bool?
    var countdownTargetDate: Date?
    var countdownTitle: String?
    var lastUpdated: Date?
    var appTheme: String?
}

struct FavoriteVerseStorage: Codable {
    let reference: String
    let text: String
    let bookName: String
    let chapter: Int
    let verse: Int
}

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
    let gratitudeStreak: Int
    let todayGratitudeCompleted: Bool
    let favoriteVerses: [FavoriteVerseStorage]
    let lastUpdated: Date
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: countdownDate)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
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
            gratitudeStreak: 5,
            todayGratitudeCompleted: false,
            favoriteVerses: [
                FavoriteVerseStorage(reference: "John 3:16", text: "For God so loved...", bookName: "John", chapter: 3, verse: 16),
                FavoriteVerseStorage(reference: "Psalm 23:1", text: "The Lord is my shepherd...", bookName: "Psalms", chapter: 23, verse: 1)
            ],
            lastUpdated: Date()
        )
    }
}

/// Common timeline entry for all widgets
struct BibleWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
    let configuration: ConfigurationAppIntent?
    
    static var placeholder: BibleWidgetEntry {
        BibleWidgetEntry(date: Date(), data: .placeholder, configuration: nil)
    }
}

/// Placeholder configuration intent
struct ConfigurationAppIntent {
    // For future configuration options
}

