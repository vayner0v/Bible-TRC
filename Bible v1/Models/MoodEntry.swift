//
//  MoodEntry.swift
//  Bible v1
//
//  Spiritual Hub - Mood/Peace Check-in Model
//

import Foundation
import SwiftUI

/// Mood levels for daily check-in
enum MoodLevel: Int, Codable, CaseIterable, Identifiable {
    case struggling = 1
    case low = 2
    case okay = 3
    case good = 4
    case great = 5
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .struggling: return "Struggling"
        case .low: return "Low"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }
    
    var emoji: String {
        switch self {
        case .struggling: return "😔"
        case .low: return "😕"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😊"
        }
    }
    
    var color: Color {
        switch self {
        case .struggling: return .red
        case .low: return .orange
        case .okay: return .yellow
        case .good: return .green
        case .great: return .blue
        }
    }
    
    var encouragement: String {
        switch self {
        case .struggling:
            return "God is close to the brokenhearted. You're not alone in this."
        case .low:
            return "Even in difficult seasons, God's love never fails. Take it one moment at a time."
        case .okay:
            return "Keep pressing forward. God is working in ways you may not see yet."
        case .good:
            return "What a blessing! May your joy continue to grow in the Lord."
        case .great:
            return "Praise God for this wonderful day! Share your joy with someone today."
        }
    }
    
    /// Suggested verse based on mood
    var suggestedVerse: (reference: String, text: String) {
        switch self {
        case .struggling:
            return ("Psalm 34:18", "The Lord is close to the brokenhearted and saves those who are crushed in spirit.")
        case .low:
            return ("Isaiah 41:10", "So do not fear, for I am with you; do not be dismayed, for I am your God.")
        case .okay:
            return ("Philippians 4:13", "I can do all things through Christ who strengthens me.")
        case .good:
            return ("Psalm 118:24", "This is the day the Lord has made; let us rejoice and be glad in it.")
        case .great:
            return ("Psalm 100:4", "Enter his gates with thanksgiving and his courts with praise.")
        }
    }
    
    /// Suggested prayer theme based on mood
    var suggestedPrayerTheme: GuidedPrayerTheme {
        switch self {
        case .struggling, .low: return .peace
        case .okay: return .guidance
        case .good, .great: return .gratitude
        }
    }
}

/// Represents a daily mood/peace check-in
struct MoodEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    var mood: MoodLevel
    var note: String?
    var factors: [MoodFactor]
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: MoodLevel,
        note: String? = nil,
        factors: [MoodFactor] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.mood = mood
        self.note = note
        self.factors = factors
        self.createdAt = createdAt
    }
    
    /// Check if entry is for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Time of check-in
    var timeOfDay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

/// Factors that may influence mood
enum MoodFactor: String, Codable, CaseIterable, Identifiable {
    case sleep = "Sleep"
    case health = "Health"
    case relationships = "Relationships"
    case work = "Work/School"
    case finances = "Finances"
    case spiritual = "Spiritual"
    case weather = "Weather"
    case exercise = "Exercise"
    case stress = "Stress"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .health: return "heart.fill"
        case .relationships: return "person.2.fill"
        case .work: return "briefcase.fill"
        case .finances: return "dollarsign.circle"
        case .spiritual: return "sparkles"
        case .weather: return "cloud.sun.fill"
        case .exercise: return "figure.run"
        case .stress: return "brain.head.profile"
        case .other: return "ellipsis.circle"
        }
    }
}

/// Weekly mood summary
struct WeeklyMoodSummary: Identifiable {
    let id: UUID
    let weekStartDate: Date
    let entries: [MoodEntry]
    
    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        entries: [MoodEntry]
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.entries = entries
    }
    
    /// Average mood for the week
    var averageMood: Double {
        guard !entries.isEmpty else { return 0 }
        let total = entries.reduce(0) { $0 + $1.mood.rawValue }
        return Double(total) / Double(entries.count)
    }
    
    /// Average mood level (rounded)
    var averageMoodLevel: MoodLevel {
        MoodLevel(rawValue: Int(averageMood.rounded())) ?? .okay
    }
    
    /// Number of days with check-ins
    var daysCheckedIn: Int {
        entries.count
    }
    
    /// Most common factors
    var topFactors: [MoodFactor] {
        let allFactors = entries.flatMap { $0.factors }
        let counts = Dictionary(grouping: allFactors, by: { $0 }).mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    /// Week date range for display
    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: endDate))"
    }
}



