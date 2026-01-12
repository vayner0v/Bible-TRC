//
//  RoutineCompletion.swift
//  Bible v1
//
//  Tracks routine completion history with linked Hub data
//

import Foundation
import SwiftUI

// MARK: - Routine Completion

/// Tracks each completed routine session with full history and linked data
struct RoutineCompletion: Identifiable, Codable, Equatable {
    let id: UUID
    let configurationId: UUID
    let configurationName: String
    let mode: RoutineMode
    let date: Date
    let startTime: Date
    let endTime: Date
    let stepsCompleted: Int
    let totalSteps: Int
    
    // Linked data from routine steps
    var intentionText: String?
    var gratitudeItems: [String]
    var reflectionNotes: String?
    var moodAtStart: MoodLevel?
    var moodAtEnd: MoodLevel?
    
    // Cross-feature linking
    var linkedGratitudeEntryId: UUID?
    var linkedMoodEntryId: UUID?
    var linkedJournalEntryId: UUID?
    
    // Auto-checked habits
    var autoCheckedHabits: [SpiritualHabit]
    
    init(
        id: UUID = UUID(),
        configurationId: UUID,
        configurationName: String,
        mode: RoutineMode,
        date: Date = Date(),
        startTime: Date,
        endTime: Date = Date(),
        stepsCompleted: Int,
        totalSteps: Int,
        intentionText: String? = nil,
        gratitudeItems: [String] = [],
        reflectionNotes: String? = nil,
        moodAtStart: MoodLevel? = nil,
        moodAtEnd: MoodLevel? = nil,
        linkedGratitudeEntryId: UUID? = nil,
        linkedMoodEntryId: UUID? = nil,
        linkedJournalEntryId: UUID? = nil,
        autoCheckedHabits: [SpiritualHabit] = []
    ) {
        self.id = id
        self.configurationId = configurationId
        self.configurationName = configurationName
        self.mode = mode
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.stepsCompleted = stepsCompleted
        self.totalSteps = totalSteps
        self.intentionText = intentionText
        self.gratitudeItems = gratitudeItems
        self.reflectionNotes = reflectionNotes
        self.moodAtStart = moodAtStart
        self.moodAtEnd = moodAtEnd
        self.linkedGratitudeEntryId = linkedGratitudeEntryId
        self.linkedMoodEntryId = linkedMoodEntryId
        self.linkedJournalEntryId = linkedJournalEntryId
        self.autoCheckedHabits = autoCheckedHabits
    }
    
    /// Duration in seconds
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// Duration formatted as "X min"
    var formattedDuration: String {
        let minutes = Int(duration / 60)
        if minutes < 1 {
            return "< 1 min"
        }
        return "\(minutes) min"
    }
    
    /// Completion percentage
    var completionPercentage: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(stepsCompleted) / Double(totalSteps)
    }
    
    /// Whether this completion was today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Whether mood improved after routine
    var moodImproved: Bool? {
        guard let start = moodAtStart, let end = moodAtEnd else { return nil }
        return end.rawValue > start.rawValue
    }
}

// MARK: - Routine Streak

/// Tracks streak data for routines
struct RoutineStreak: Codable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?
    var totalCompletions: Int
    
    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletedDate: Date? = nil,
        totalCompletions: Int = 0
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletedDate = lastCompletedDate
        self.totalCompletions = totalCompletions
    }
    
    mutating func recordCompletion(on date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        totalCompletions += 1
        
        if let lastDate = lastCompletedDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // If daysDiff == 0, same day completion, don't change streak
        } else {
            // First completion
            currentStreak = 1
        }
        
        longestStreak = max(longestStreak, currentStreak)
        lastCompletedDate = date
    }
    
    /// Check if streak is still active (completed yesterday or today)
    var isActive: Bool {
        guard let lastDate = lastCompletedDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        return daysDiff <= 1
    }
}

// MARK: - Routine Analytics

/// Analytics summary for routine completions
struct RoutineAnalytics {
    let period: AnalyticsPeriod
    let completions: [RoutineCompletion]
    
    enum AnalyticsPeriod {
        case week
        case month
        case allTime
    }
    
    var totalCompletions: Int {
        completions.count
    }
    
    var morningCompletions: Int {
        completions.filter { $0.mode == .morning }.count
    }
    
    var eveningCompletions: Int {
        completions.filter { $0.mode == .evening }.count
    }
    
    var averageDuration: TimeInterval {
        guard !completions.isEmpty else { return 0 }
        let total = completions.reduce(0) { $0 + $1.duration }
        return total / Double(completions.count)
    }
    
    var formattedAverageDuration: String {
        let minutes = Int(averageDuration / 60)
        if minutes < 1 { return "< 1 min" }
        return "\(minutes) min"
    }
    
    var completionRate: Double {
        guard !completions.isEmpty else { return 0 }
        let fullCompletions = completions.filter { $0.completionPercentage >= 1.0 }.count
        return Double(fullCompletions) / Double(completions.count)
    }
    
    var totalGratitudeItems: Int {
        completions.reduce(0) { $0 + $1.gratitudeItems.count }
    }
    
    var totalIntentionsSet: Int {
        completions.filter { $0.intentionText != nil && !$0.intentionText!.isEmpty }.count
    }
    
    /// Mood improvement rate (percentage of completions where mood improved)
    var moodImprovementRate: Double? {
        let withMoodData = completions.compactMap { $0.moodImproved }
        guard !withMoodData.isEmpty else { return nil }
        let improved = withMoodData.filter { $0 }.count
        return Double(improved) / Double(withMoodData.count)
    }
    
    /// Days with at least one completion
    var daysWithCompletion: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(completions.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    /// Completion data for calendar visualization
    func completionsByDate() -> [Date: [RoutineCompletion]] {
        let calendar = Calendar.current
        var result: [Date: [RoutineCompletion]] = [:]
        
        for completion in completions {
            let day = calendar.startOfDay(for: completion.date)
            result[day, default: []].append(completion)
        }
        
        return result
    }
}

// MARK: - Routine Source Attribution

/// Indicates where data originated from
enum RoutineDataSource: String, Codable {
    case morningRoutine = "Morning Routine"
    case eveningRoutine = "Evening Routine"
    case customRoutine = "Custom Routine"
    case manual = "Manual Entry"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .morningRoutine: return "sunrise.fill"
        case .eveningRoutine: return "moon.stars.fill"
        case .customRoutine: return "sparkles"
        case .manual: return "hand.tap.fill"
        }
    }
}

