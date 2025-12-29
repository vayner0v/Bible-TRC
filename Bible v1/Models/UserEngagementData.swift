//
//  UserEngagementData.swift
//  Bible v1
//
//  Spiritual Hub - User Engagement & Adaptive Notifications
//

import Foundation

/// Type of notification sent
enum NotificationType: String, Codable, CaseIterable {
    case prayerReminder = "prayer_reminder"
    case readingPlan = "reading_plan"
    case verseOfDay = "verse_of_day"
    case habitReminder = "habit_reminder"
    case missionReminder = "mission_reminder"
    case encouragement = "encouragement"
    case weeklyRecap = "weekly_recap"
    case journalReminder = "journal_reminder"
}

/// A single notification response record
struct NotificationResponse: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let notificationType: NotificationType
    let scheduledHour: Int // 0-23
    let scheduledDay: Int // 1-7 (Weekday)
    var wasOpened: Bool
    var responseDelay: TimeInterval? // Seconds until opened
    var wasActedOn: Bool // Did user complete the related action
    var wasSnoozed: Bool
    var wasDismissed: Bool
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        notificationType: NotificationType,
        scheduledHour: Int,
        scheduledDay: Int,
        wasOpened: Bool = false,
        responseDelay: TimeInterval? = nil,
        wasActedOn: Bool = false,
        wasSnoozed: Bool = false,
        wasDismissed: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.notificationType = notificationType
        self.scheduledHour = scheduledHour
        self.scheduledDay = scheduledDay
        self.wasOpened = wasOpened
        self.responseDelay = responseDelay
        self.wasActedOn = wasActedOn
        self.wasSnoozed = wasSnoozed
        self.wasDismissed = wasDismissed
    }
}

/// Aggregated engagement data for analysis
struct UserEngagementData: Codable {
    var notificationResponses: [NotificationResponse]
    var hourlyEngagement: [Int: HourEngagement] // Hour -> engagement stats
    var dailyEngagement: [Int: DayEngagement] // Weekday -> engagement stats
    var typeEngagement: [String: TypeEngagement] // NotificationType -> engagement stats
    var lastAnalyzed: Date?
    var recommendedMorningHour: Int?
    var recommendedEveningHour: Int?
    
    init(
        notificationResponses: [NotificationResponse] = [],
        hourlyEngagement: [Int: HourEngagement] = [:],
        dailyEngagement: [Int: DayEngagement] = [:],
        typeEngagement: [String: TypeEngagement] = [:],
        lastAnalyzed: Date? = nil,
        recommendedMorningHour: Int? = nil,
        recommendedEveningHour: Int? = nil
    ) {
        self.notificationResponses = notificationResponses
        self.hourlyEngagement = hourlyEngagement
        self.dailyEngagement = dailyEngagement
        self.typeEngagement = typeEngagement
        self.lastAnalyzed = lastAnalyzed
        self.recommendedMorningHour = recommendedMorningHour
        self.recommendedEveningHour = recommendedEveningHour
    }
    
    /// Record a notification response
    mutating func recordResponse(_ response: NotificationResponse) {
        notificationResponses.append(response)
        
        // Keep only last 90 days of data
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        notificationResponses = notificationResponses.filter { $0.timestamp > cutoff }
    }
    
    /// Analyze engagement patterns
    mutating func analyzePatterns() {
        guard notificationResponses.count >= 7 else { return } // Need minimum data
        
        // Reset aggregations
        hourlyEngagement = [:]
        dailyEngagement = [:]
        typeEngagement = [:]
        
        // Aggregate by hour
        for hour in 0..<24 {
            let hourResponses = notificationResponses.filter { $0.scheduledHour == hour }
            if !hourResponses.isEmpty {
                hourlyEngagement[hour] = HourEngagement(from: hourResponses)
            }
        }
        
        // Aggregate by weekday
        for day in 1...7 {
            let dayResponses = notificationResponses.filter { $0.scheduledDay == day }
            if !dayResponses.isEmpty {
                dailyEngagement[day] = DayEngagement(from: dayResponses)
            }
        }
        
        // Aggregate by type
        for type in NotificationType.allCases {
            let typeResponses = notificationResponses.filter { $0.notificationType == type }
            if !typeResponses.isEmpty {
                typeEngagement[type.rawValue] = TypeEngagement(from: typeResponses)
            }
        }
        
        // Calculate recommended times
        calculateRecommendedTimes()
        
        lastAnalyzed = Date()
    }
    
    /// Calculate best times for notifications
    private mutating func calculateRecommendedTimes() {
        // Find best morning hour (5-11 AM)
        let morningHours = (5...11).compactMap { hour -> (Int, Double)? in
            guard let engagement = hourlyEngagement[hour] else { return nil }
            return (hour, engagement.engagementScore)
        }
        recommendedMorningHour = morningHours.max(by: { $0.1 < $1.1 })?.0
        
        // Find best evening hour (6-10 PM)
        let eveningHours = (18...22).compactMap { hour -> (Int, Double)? in
            guard let engagement = hourlyEngagement[hour] else { return nil }
            return (hour, engagement.engagementScore)
        }
        recommendedEveningHour = eveningHours.max(by: { $0.1 < $1.1 })?.0
    }
    
    /// Get engagement score for a specific hour
    func engagementScoreForHour(_ hour: Int) -> Double {
        hourlyEngagement[hour]?.engagementScore ?? 0.5
    }
    
    /// Get engagement score for a specific day
    func engagementScoreForDay(_ day: Int) -> Double {
        dailyEngagement[day]?.engagementScore ?? 0.5
    }
    
    /// Check if user typically ignores notifications at this hour
    func isLowEngagementHour(_ hour: Int) -> Bool {
        guard let engagement = hourlyEngagement[hour] else { return false }
        return engagement.engagementScore < 0.3
    }
    
    /// Suggest alternative time if current time has low engagement
    func suggestBetterTime(for hour: Int, isMorning: Bool) -> Int? {
        guard isLowEngagementHour(hour) else { return nil }
        
        if isMorning {
            return recommendedMorningHour
        } else {
            return recommendedEveningHour
        }
    }
}

/// Engagement statistics for a specific hour
struct HourEngagement: Codable {
    var totalSent: Int
    var totalOpened: Int
    var totalActedOn: Int
    var totalSnoozed: Int
    var averageResponseDelay: TimeInterval?
    
    init(from responses: [NotificationResponse]) {
        self.totalSent = responses.count
        self.totalOpened = responses.filter { $0.wasOpened }.count
        self.totalActedOn = responses.filter { $0.wasActedOn }.count
        self.totalSnoozed = responses.filter { $0.wasSnoozed }.count
        
        let delays = responses.compactMap { $0.responseDelay }
        if !delays.isEmpty {
            self.averageResponseDelay = delays.reduce(0, +) / Double(delays.count)
        }
    }
    
    /// Overall engagement score (0.0 - 1.0)
    var engagementScore: Double {
        guard totalSent > 0 else { return 0.5 }
        
        let openRate = Double(totalOpened) / Double(totalSent)
        let actionRate = Double(totalActedOn) / Double(totalSent)
        let snoozeRate = Double(totalSnoozed) / Double(totalSent)
        
        // Weight: 40% open, 40% action, -20% snooze
        return min(1.0, max(0.0, openRate * 0.4 + actionRate * 0.4 - snoozeRate * 0.2 + 0.2))
    }
}

/// Engagement statistics for a specific day
struct DayEngagement: Codable {
    var totalSent: Int
    var totalOpened: Int
    var totalActedOn: Int
    var totalSnoozed: Int
    
    init(from responses: [NotificationResponse]) {
        self.totalSent = responses.count
        self.totalOpened = responses.filter { $0.wasOpened }.count
        self.totalActedOn = responses.filter { $0.wasActedOn }.count
        self.totalSnoozed = responses.filter { $0.wasSnoozed }.count
    }
    
    var engagementScore: Double {
        guard totalSent > 0 else { return 0.5 }
        
        let openRate = Double(totalOpened) / Double(totalSent)
        let actionRate = Double(totalActedOn) / Double(totalSent)
        
        return min(1.0, max(0.0, openRate * 0.5 + actionRate * 0.5))
    }
}

/// Engagement statistics for a notification type
struct TypeEngagement: Codable {
    var totalSent: Int
    var totalOpened: Int
    var totalActedOn: Int
    var averageResponseDelay: TimeInterval?
    
    init(from responses: [NotificationResponse]) {
        self.totalSent = responses.count
        self.totalOpened = responses.filter { $0.wasOpened }.count
        self.totalActedOn = responses.filter { $0.wasActedOn }.count
        
        let delays = responses.compactMap { $0.responseDelay }
        if !delays.isEmpty {
            self.averageResponseDelay = delays.reduce(0, +) / Double(delays.count)
        }
    }
    
    var engagementScore: Double {
        guard totalSent > 0 else { return 0.5 }
        return Double(totalActedOn) / Double(totalSent)
    }
}

// MARK: - Notification Preferences

/// User's notification preferences
struct NotificationPreferences: Codable, Equatable {
    var isEnabled: Bool
    var prayerRemindersEnabled: Bool
    var readingPlanRemindersEnabled: Bool
    var verseOfDayEnabled: Bool
    var habitRemindersEnabled: Bool
    var missionRemindersEnabled: Bool
    var encouragementEnabled: Bool
    var weeklyRecapEnabled: Bool
    
    var quietHoursEnabled: Bool
    var quietHoursStart: Int // Hour (0-23)
    var quietHoursEnd: Int // Hour (0-23)
    
    var adaptiveTimingEnabled: Bool
    var maxDailyNotifications: Int
    
    init(
        isEnabled: Bool = true,
        prayerRemindersEnabled: Bool = true,
        readingPlanRemindersEnabled: Bool = true,
        verseOfDayEnabled: Bool = true,
        habitRemindersEnabled: Bool = true,
        missionRemindersEnabled: Bool = true,
        encouragementEnabled: Bool = true,
        weeklyRecapEnabled: Bool = true,
        quietHoursEnabled: Bool = true,
        quietHoursStart: Int = 22,
        quietHoursEnd: Int = 7,
        adaptiveTimingEnabled: Bool = true,
        maxDailyNotifications: Int = 5
    ) {
        self.isEnabled = isEnabled
        self.prayerRemindersEnabled = prayerRemindersEnabled
        self.readingPlanRemindersEnabled = readingPlanRemindersEnabled
        self.verseOfDayEnabled = verseOfDayEnabled
        self.habitRemindersEnabled = habitRemindersEnabled
        self.missionRemindersEnabled = missionRemindersEnabled
        self.encouragementEnabled = encouragementEnabled
        self.weeklyRecapEnabled = weeklyRecapEnabled
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.adaptiveTimingEnabled = adaptiveTimingEnabled
        self.maxDailyNotifications = maxDailyNotifications
    }
    
    /// Check if a notification type is enabled
    func isTypeEnabled(_ type: NotificationType) -> Bool {
        guard isEnabled else { return false }
        
        switch type {
        case .prayerReminder: return prayerRemindersEnabled
        case .readingPlan: return readingPlanRemindersEnabled
        case .verseOfDay: return verseOfDayEnabled
        case .habitReminder: return habitRemindersEnabled
        case .missionReminder: return missionRemindersEnabled
        case .encouragement: return encouragementEnabled
        case .weeklyRecap: return weeklyRecapEnabled
        case .journalReminder: return true // Managed separately
        }
    }
    
    /// Check if current time is within quiet hours
    func isQuietHours(at date: Date = Date()) -> Bool {
        guard quietHoursEnabled else { return false }
        
        let hour = Calendar.current.component(.hour, from: date)
        
        if quietHoursStart < quietHoursEnd {
            // Normal range (e.g., 22-7 doesn't apply, 9-17 does)
            return hour >= quietHoursStart && hour < quietHoursEnd
        } else {
            // Overnight range (e.g., 22-7)
            return hour >= quietHoursStart || hour < quietHoursEnd
        }
    }
}


