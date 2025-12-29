//
//  HabitEntry.swift
//  Bible v1
//
//  Spiritual Hub - Habits Tracker Model
//

import Foundation
import SwiftUI

/// Types of spiritual habits to track
enum SpiritualHabit: String, Codable, CaseIterable, Identifiable {
    case prayer = "Prayer"
    case bibleReading = "Bible Reading"
    case gratitude = "Gratitude"
    case service = "Service"
    case fasting = "Fasting"
    case meditation = "Meditation"
    case worship = "Worship"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .prayer: return "hands.sparkles"
        case .bibleReading: return "book.fill"
        case .gratitude: return "heart.fill"
        case .service: return "hand.raised.fill"
        case .fasting: return "leaf.fill"
        case .meditation: return "brain.head.profile"
        case .worship: return "music.note"
        }
    }
    
    var description: String {
        switch self {
        case .prayer: return "Time spent in conversation with God"
        case .bibleReading: return "Reading and studying Scripture"
        case .gratitude: return "Acknowledging God's blessings"
        case .service: return "Helping and serving others"
        case .fasting: return "Spiritual discipline of abstaining"
        case .meditation: return "Quiet reflection on God's Word"
        case .worship: return "Praising and honoring God"
        }
    }
    
    var defaultGoal: String {
        switch self {
        case .prayer: return "Pray for 10 minutes"
        case .bibleReading: return "Read 1 chapter"
        case .gratitude: return "Write 3 things"
        case .service: return "Help someone"
        case .fasting: return "Skip a meal"
        case .meditation: return "Meditate 5 minutes"
        case .worship: return "Worship in song"
        }
    }
    
    var color: Color {
        switch self {
        case .prayer: return .teal
        case .bibleReading: return .blue
        case .gratitude: return .pink
        case .service: return .orange
        case .fasting: return .green
        case .meditation: return .teal
        case .worship: return .indigo
        }
    }
}

/// Represents a single habit check-in for a specific day
struct HabitEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let habit: SpiritualHabit
    let date: Date
    var isCompleted: Bool
    var notes: String?
    var duration: Int? // in minutes, optional
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        habit: SpiritualHabit,
        date: Date = Date(),
        isCompleted: Bool = true,
        notes: String? = nil,
        duration: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.habit = habit
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = isCompleted
        self.notes = notes
        self.duration = duration
        self.createdAt = createdAt
    }
    
    /// Check if this entry is for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Tracks habit streaks and statistics
struct HabitStreak: Identifiable, Codable {
    let id: UUID
    let habit: SpiritualHabit
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var lastCompletedDate: Date?
    
    init(
        id: UUID = UUID(),
        habit: SpiritualHabit,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalCompletions: Int = 0,
        lastCompletedDate: Date? = nil
    ) {
        self.id = id
        self.habit = habit
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalCompletions = totalCompletions
        self.lastCompletedDate = lastCompletedDate
    }
    
    /// Update streak when habit is completed
    mutating func recordCompletion(for date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        if let lastDate = lastCompletedDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDifference == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysDifference > 1 {
                // Streak broken - reset
                currentStreak = 1
            }
            // Same day - no change to streak
        } else {
            // First completion
            currentStreak = 1
        }
        
        // Update longest streak if needed
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        totalCompletions += 1
        lastCompletedDate = today
    }
    
    /// Check if streak is still active (completed yesterday or today)
    var isStreakActive: Bool {
        guard let lastDate = lastCompletedDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        return daysDifference <= 1
    }
}

/// Daily habit summary for a specific date
struct DailyHabitSummary: Identifiable {
    let id: UUID
    let date: Date
    var completedHabits: [SpiritualHabit]
    var totalHabitsTracked: Int
    
    init(
        id: UUID = UUID(),
        date: Date,
        completedHabits: [SpiritualHabit] = [],
        totalHabitsTracked: Int = 5
    ) {
        self.id = id
        self.date = date
        self.completedHabits = completedHabits
        self.totalHabitsTracked = totalHabitsTracked
    }
    
    var completionRate: Double {
        guard totalHabitsTracked > 0 else { return 0 }
        return Double(completedHabits.count) / Double(totalHabitsTracked)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}



