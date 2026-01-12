//
//  WidgetDataService.swift
//  Bible v1
//
//  Manages widget data synchronization via App Group
//

import Foundation
import WidgetKit
import Combine

/// Service for managing widget data and configurations via App Group
@MainActor
final class WidgetDataService: ObservableObject {
    static let shared = WidgetDataService()
    
    // MARK: - Published Properties
    
    @Published private(set) var widgetConfigs: [WidgetConfig] = []
    @Published private(set) var widgetData: WidgetData = .empty
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
        loadConfigs()
        loadData()
    }
    
    // MARK: - Configuration Management
    
    /// Load saved widget configurations
    func loadConfigs() {
        guard let data = userDefaults?.data(forKey: AppGroupConstants.widgetConfigsKey),
              let configs = try? JSONDecoder().decode([WidgetConfig].self, from: data) else {
            widgetConfigs = []
            return
        }
        widgetConfigs = configs
    }
    
    /// Save widget configurations
    func saveConfigs() {
        // Save in original format for main app
        guard let data = try? JSONEncoder().encode(widgetConfigs) else { return }
        userDefaults?.set(data, forKey: AppGroupConstants.widgetConfigsKey)
        
        // Also save in simplified format for widget extension
        let widgetExtConfigs = widgetConfigs.map { config -> [String: Any] in
            var dict: [String: Any] = [
                "id": config.id.uuidString,
                "name": config.name,
                "widgetType": config.widgetType.rawValue,
                "size": config.size.rawValue
            ]
            if let presetId = config.presetId {
                dict["presetId"] = presetId
            }
            return dict
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: widgetExtConfigs) {
            userDefaults?.set(jsonData, forKey: "widget_configs_simplified")
        }
        
        userDefaults?.synchronize()
        refreshWidgets()
    }
    
    /// Add a new widget configuration
    func addConfig(_ config: WidgetConfig) {
        widgetConfigs.append(config)
        saveConfigs()
    }
    
    /// Update an existing widget configuration
    func updateConfig(_ config: WidgetConfig) {
        if let index = widgetConfigs.firstIndex(where: { $0.id == config.id }) {
            var updated = config
            updated = WidgetConfig(
                id: config.id,
                widgetType: config.widgetType,
                size: config.size,
                name: config.name,
                background: config.background,
                titleStyle: config.titleStyle,
                bodyStyle: config.bodyStyle,
                textAlignment: config.textAlignment,
                cornerStyle: config.cornerStyle,
                padding: config.padding,
                showShadow: config.showShadow,
                contentConfig: config.contentConfig,
                isPreset: config.isPreset,
                presetId: config.presetId
            )
            widgetConfigs[index] = updated
            saveConfigs()
        }
    }
    
    /// Delete a widget configuration
    func deleteConfig(_ config: WidgetConfig) {
        widgetConfigs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    /// Delete configuration by ID
    func deleteConfig(withId id: UUID) {
        widgetConfigs.removeAll { $0.id == id }
        saveConfigs()
    }
    
    /// Get configurations for a specific widget type
    func configs(for type: BibleWidgetType) -> [WidgetConfig] {
        widgetConfigs.filter { $0.widgetType == type }
    }
    
    /// Create a new config from a preset
    func createFromPreset(_ preset: WidgetPreset, type: BibleWidgetType, size: WidgetSize) -> WidgetConfig {
        let config = preset.config
        return WidgetConfig(
            id: UUID(),
            widgetType: type,
            size: size,
            name: "\(preset.name) - \(type.displayName)",
            background: config.background,
            titleStyle: config.titleStyle,
            bodyStyle: config.bodyStyle,
            textAlignment: config.textAlignment,
            cornerStyle: config.cornerStyle,
            padding: config.padding,
            showShadow: config.showShadow,
            contentConfig: .default,
            isPreset: true,
            presetId: preset.id
        )
    }
    
    // MARK: - Widget Data Management
    
    /// Load widget data from App Group
    func loadData() {
        guard let data = userDefaults?.data(forKey: AppGroupConstants.widgetDataKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            self.widgetData = .empty
            return
        }
        self.widgetData = widgetData
    }
    
    /// Save widget data to App Group
    func saveData(_ data: WidgetData) {
        var updatedData = data
        updatedData.lastUpdated = Date()
        
        guard let encoded = try? JSONEncoder().encode(updatedData) else { return }
        userDefaults?.set(encoded, forKey: AppGroupConstants.widgetDataKey)
        userDefaults?.synchronize()
        
        self.widgetData = updatedData
        refreshWidgets()
    }
    
    /// Update widget data from app state
    func syncFromApp(
        verseOfDay: (text: String, reference: String)? = nil,
        readingPlan: (name: String, progress: Double, streak: Int, currentDay: Int, totalDays: Int)? = nil,
        prayer: (active: Int, answered: Int, lastTime: Date?)? = nil,
        habits: (progress: Double, completed: Int, total: Int, streak: Int)? = nil,
        favorites: [FavoriteVerseData]? = nil,
        mood: (last: String, history: [String], date: Date?, gratitudeStreak: Int, todayCompleted: Bool)? = nil,
        countdown: (date: Date, title: String)? = nil,
        theme: String? = nil
    ) {
        var data = widgetData
        
        if let verse = verseOfDay {
            data.verseOfDayText = verse.text
            data.verseOfDayReference = verse.reference
        }
        
        if let plan = readingPlan {
            data.readingPlanName = plan.name
            data.readingProgress = plan.progress
            data.readingStreak = plan.streak
            data.currentDay = plan.currentDay
            data.totalDays = plan.totalDays
        }
        
        if let p = prayer {
            data.activePrayerCount = p.active
            data.answeredPrayerCount = p.answered
            data.lastPrayerTime = p.lastTime
        }
        
        if let h = habits {
            data.todayHabitProgress = h.progress
            data.completedHabits = h.completed
            data.totalHabits = h.total
            data.habitStreak = h.streak
        }
        
        if let favs = favorites {
            data.favoriteVerses = favs
        }
        
        if let m = mood {
            data.lastMood = m.last
            data.moodHistory = m.history
            data.lastMoodDate = m.date
            data.gratitudeStreak = m.gratitudeStreak
            data.todayGratitudeCompleted = m.todayCompleted
        }
        
        if let c = countdown {
            data.countdownTargetDate = c.date
            data.countdownTitle = c.title
        }
        
        if let t = theme {
            data.appTheme = t
        }
        
        saveData(data)
    }
    
    /// Update verse of the day
    func updateVerseOfDay(text: String, reference: String) {
        var data = widgetData
        data.verseOfDayText = text
        data.verseOfDayReference = reference
        saveData(data)
    }
    
    /// Update reading progress
    func updateReadingProgress(planName: String, progress: Double, streak: Int, currentDay: Int, totalDays: Int) {
        var data = widgetData
        data.readingPlanName = planName
        data.readingProgress = progress
        data.readingStreak = streak
        data.currentDay = currentDay
        data.totalDays = totalDays
        saveData(data)
    }
    
    /// Update prayer data
    func updatePrayerData(activeCount: Int, answeredCount: Int, lastTime: Date?) {
        var data = widgetData
        data.activePrayerCount = activeCount
        data.answeredPrayerCount = answeredCount
        data.lastPrayerTime = lastTime
        saveData(data)
    }
    
    /// Update habit data
    func updateHabitData(progress: Double, completed: Int, total: Int, streak: Int) {
        var data = widgetData
        data.todayHabitProgress = progress
        data.completedHabits = completed
        data.totalHabits = total
        data.habitStreak = streak
        saveData(data)
    }
    
    /// Update favorites
    func updateFavorites(_ favorites: [FavoriteVerseData]) {
        var data = widgetData
        data.favoriteVerses = favorites
        saveData(data)
    }
    
    /// Update mood/gratitude data
    func updateMoodGratitude(lastMood: String?, moodHistory: [String], lastDate: Date?, gratitudeStreak: Int, todayCompleted: Bool) {
        var data = widgetData
        data.lastMood = lastMood
        data.moodHistory = moodHistory
        data.lastMoodDate = lastDate
        data.gratitudeStreak = gratitudeStreak
        data.todayGratitudeCompleted = todayCompleted
        saveData(data)
    }
    
    /// Update countdown
    func updateCountdown(date: Date?, title: String?) {
        var data = widgetData
        data.countdownTargetDate = date
        data.countdownTitle = title
        saveData(data)
    }
    
    /// Update app theme
    func updateTheme(_ theme: String) {
        var data = widgetData
        data.appTheme = theme
        saveData(data)
    }
    
    // MARK: - Widget Refresh
    
    /// Request all widgets to refresh their timelines
    func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Request specific widget type to refresh
    func refreshWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
    
    /// Get current widget info
    func getCurrentWidgets() async -> [WidgetInfo] {
        await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let infos):
                    continuation.resume(returning: infos)
                case .failure:
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

// MARK: - Preview Helpers

extension WidgetDataService {
    static var preview: WidgetDataService {
        let service = WidgetDataService.shared
        // Add some sample data for previews
        return service
    }
}
