//
//  PrayerSchedule.swift
//  Bible v1
//
//  Spiritual Hub - Prayer Schedule Model
//

import Foundation
import SwiftUI

/// Days of the week for scheduling
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    /// Get current weekday
    static var today: Weekday {
        let weekdayNumber = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekdayNumber) ?? .sunday
    }
}

/// Type of scheduled prayer
enum ScheduledPrayerType: String, Codable, CaseIterable, Identifiable {
    case guided = "Guided Prayer"
    case free = "Free Prayer"
    case scriptureBased = "Scripture Prayer"
    case gratitude = "Gratitude"
    case intercession = "Intercession"
    case meditation = "Meditation"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .guided: return "hands.sparkles"
        case .free: return "text.bubble"
        case .scriptureBased: return "book.fill"
        case .gratitude: return "heart.fill"
        case .intercession: return "person.2.fill"
        case .meditation: return "leaf.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .guided: return .teal
        case .free: return .blue
        case .scriptureBased: return .orange
        case .gratitude: return .pink
        case .intercession: return .teal
        case .meditation: return .green
        }
    }
    
    var description: String {
        switch self {
        case .guided: return "Follow prompts through your prayer"
        case .free: return "Open time for personal prayer"
        case .scriptureBased: return "Pray through Scripture"
        case .gratitude: return "Focus on thankfulness"
        case .intercession: return "Pray for others"
        case .meditation: return "Quiet reflection and listening"
        }
    }
    
    var suggestedDuration: Int {
        switch self {
        case .guided: return 5
        case .free: return 10
        case .scriptureBased: return 7
        case .gratitude: return 3
        case .intercession: return 5
        case .meditation: return 10
        }
    }
}

/// Reminder offset options
enum ReminderOffset: Int, Codable, CaseIterable, Identifiable {
    case none = 0
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "At time"
        case .fiveMinutes: return "5 min before"
        case .tenMinutes: return "10 min before"
        case .fifteenMinutes: return "15 min before"
        case .thirtyMinutes: return "30 min before"
        }
    }
}

/// A scheduled prayer time
struct PrayerSchedule: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var time: Date
    var repeatDays: Set<Int> // Using Int for Codable compatibility
    var reminderOffset: ReminderOffset
    var prayerType: ScheduledPrayerType
    var linkedPrayerId: UUID?
    var linkedGuidedTheme: String?
    var duration: Int // minutes
    var isEnabled: Bool
    var snoozeCount: Int
    var lastCompleted: Date?
    var completionHistory: [Date]
    let dateCreated: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        time: Date,
        repeatDays: Set<Weekday> = Set(Weekday.allCases),
        reminderOffset: ReminderOffset = .fiveMinutes,
        prayerType: ScheduledPrayerType = .free,
        linkedPrayerId: UUID? = nil,
        linkedGuidedTheme: String? = nil,
        duration: Int = 5,
        isEnabled: Bool = true,
        snoozeCount: Int = 0,
        lastCompleted: Date? = nil,
        completionHistory: [Date] = [],
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.time = time
        self.repeatDays = Set(repeatDays.map { $0.rawValue })
        self.reminderOffset = reminderOffset
        self.prayerType = prayerType
        self.linkedPrayerId = linkedPrayerId
        self.linkedGuidedTheme = linkedGuidedTheme
        self.duration = duration
        self.isEnabled = isEnabled
        self.snoozeCount = snoozeCount
        self.lastCompleted = lastCompleted
        self.completionHistory = completionHistory
        self.dateCreated = dateCreated
    }
    
    /// Get repeat days as Weekday enum
    var repeatWeekdays: Set<Weekday> {
        get {
            Set(repeatDays.compactMap { Weekday(rawValue: $0) })
        }
        set {
            repeatDays = Set(newValue.map { $0.rawValue })
        }
    }
    
    /// Format time for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    /// Format repeat days for display
    var formattedRepeatDays: String {
        let weekdays = repeatWeekdays.sorted { $0.rawValue < $1.rawValue }
        
        if weekdays.count == 7 {
            return "Every day"
        } else if weekdays.count == 5 && 
                  !weekdays.contains(.saturday) && 
                  !weekdays.contains(.sunday) {
            return "Weekdays"
        } else if weekdays.count == 2 && 
                  weekdays.contains(.saturday) && 
                  weekdays.contains(.sunday) {
            return "Weekends"
        } else if weekdays.count == 1 {
            return weekdays.first?.fullName ?? ""
        } else {
            return weekdays.map { $0.shortName }.joined(separator: ", ")
        }
    }
    
    /// Check if schedule applies today
    var isScheduledToday: Bool {
        repeatWeekdays.contains(Weekday.today)
    }
    
    /// Check if prayer is due now (within 5 minutes)
    var isDueNow: Bool {
        guard isEnabled && isScheduledToday else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        let scheduledComponents = calendar.dateComponents([.hour, .minute], from: time)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        guard let scheduledHour = scheduledComponents.hour,
              let scheduledMinute = scheduledComponents.minute,
              let nowHour = nowComponents.hour,
              let nowMinute = nowComponents.minute else { return false }
        
        let scheduledTotalMinutes = scheduledHour * 60 + scheduledMinute
        let nowTotalMinutes = nowHour * 60 + nowMinute
        
        let diff = abs(scheduledTotalMinutes - nowTotalMinutes)
        return diff <= 5
    }
    
    /// Check if already completed today
    var isCompletedToday: Bool {
        guard let lastCompleted = lastCompleted else { return false }
        return Calendar.current.isDateInToday(lastCompleted)
    }
    
    /// Get next scheduled time
    var nextScheduledTime: Date? {
        guard isEnabled, !repeatWeekdays.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        // Check today and next 7 days
        for dayOffset in 0..<8 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: checkDate)
            
            guard let weekdayEnum = Weekday(rawValue: weekday),
                  repeatWeekdays.contains(weekdayEnum) else { continue }
            
            var components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            guard let scheduledDate = calendar.date(from: components) else { continue }
            
            if scheduledDate > now {
                return scheduledDate
            }
        }
        
        return nil
    }
    
    /// Current streak
    var currentStreak: Int {
        guard !completionHistory.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedHistory = completionHistory.sorted().reversed()
        var streak = 0
        var checkDate = Date()
        
        for completion in sortedHistory {
            if calendar.isDate(completion, inSameDayAs: checkDate) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else if completion < calendar.startOfDay(for: checkDate) {
                break
            }
        }
        
        return streak
    }
    
    /// Mark as completed
    mutating func markCompleted() {
        lastCompleted = Date()
        completionHistory.append(Date())
        snoozeCount = 0
    }
    
    /// Snooze the reminder
    mutating func snooze() {
        snoozeCount += 1
    }
}

// MARK: - Preset Schedules

extension PrayerSchedule {
    
    static func morningPrayer() -> PrayerSchedule {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        let time = Calendar.current.date(from: components) ?? Date()
        
        return PrayerSchedule(
            name: "Morning Prayer",
            time: time,
            repeatDays: Set(Weekday.allCases),
            prayerType: .gratitude,
            duration: 5
        )
    }
    
    static func eveningPrayer() -> PrayerSchedule {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 21
        components.minute = 0
        let time = Calendar.current.date(from: components) ?? Date()
        
        return PrayerSchedule(
            name: "Evening Reflection",
            time: time,
            repeatDays: Set(Weekday.allCases),
            prayerType: .meditation,
            duration: 10
        )
    }
    
    static func lunchPrayer() -> PrayerSchedule {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 12
        components.minute = 0
        let time = Calendar.current.date(from: components) ?? Date()
        
        return PrayerSchedule(
            name: "Midday Pause",
            time: time,
            repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday].reduce(into: Set<Weekday>()) { $0.insert($1) },
            prayerType: .free,
            duration: 3
        )
    }
    
    static let presets: [PrayerSchedule] = [
        morningPrayer(),
        eveningPrayer(),
        lunchPrayer()
    ]
}



