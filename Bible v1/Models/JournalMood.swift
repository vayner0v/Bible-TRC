//
//  JournalMood.swift
//  Bible v1
//
//  Spiritual Journal - Mood Tracking Model
//

import Foundation
import SwiftUI

/// Mood options for journal entries
enum JournalMood: String, Codable, CaseIterable, Identifiable {
    case joyful
    case peaceful
    case grateful
    case hopeful
    case reflective
    case anxious
    case struggling
    
    var id: String { rawValue }
    
    /// Display name
    var displayName: String {
        switch self {
        case .joyful: return "Joyful"
        case .peaceful: return "Peaceful"
        case .grateful: return "Grateful"
        case .hopeful: return "Hopeful"
        case .reflective: return "Reflective"
        case .anxious: return "Anxious"
        case .struggling: return "Struggling"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .joyful: return "sun.max.fill"
        case .peaceful: return "leaf.fill"
        case .grateful: return "heart.fill"
        case .hopeful: return "sparkles"
        case .reflective: return "moon.stars.fill"
        case .anxious: return "cloud.rain.fill"
        case .struggling: return "cloud.heavyrain.fill"
        }
    }
    
    /// Emoji representation
    var emoji: String {
        switch self {
        case .joyful: return "😊"
        case .peaceful: return "😌"
        case .grateful: return "🙏"
        case .hopeful: return "✨"
        case .reflective: return "🤔"
        case .anxious: return "😰"
        case .struggling: return "😔"
        }
    }
    
    /// Theme-aware color
    var color: Color {
        switch self {
        case .joyful: return .yellow
        case .peaceful: return .mint
        case .grateful: return .pink
        case .hopeful: return .purple
        case .reflective: return .indigo
        case .anxious: return .orange
        case .struggling: return .gray
        }
    }
    
    /// Lighter shade for backgrounds
    var lightColor: Color {
        color.opacity(0.2)
    }
    
    /// Description for accessibility
    var description: String {
        switch self {
        case .joyful: return "Feeling joyful and happy"
        case .peaceful: return "Feeling calm and at peace"
        case .grateful: return "Feeling thankful and blessed"
        case .hopeful: return "Feeling hopeful about the future"
        case .reflective: return "In a thoughtful, contemplative mood"
        case .anxious: return "Feeling worried or uneasy"
        case .struggling: return "Going through a difficult time"
        }
    }
    
    /// Suggested scripture for each mood
    var suggestedVerse: String {
        switch self {
        case .joyful:
            return "Rejoice in the Lord always. I will say it again: Rejoice! - Philippians 4:4"
        case .peaceful:
            return "Peace I leave with you; my peace I give you. - John 14:27"
        case .grateful:
            return "Give thanks in all circumstances; for this is God's will for you. - 1 Thessalonians 5:18"
        case .hopeful:
            return "For I know the plans I have for you, declares the Lord. - Jeremiah 29:11"
        case .reflective:
            return "Be still, and know that I am God. - Psalm 46:10"
        case .anxious:
            return "Cast all your anxiety on him because he cares for you. - 1 Peter 5:7"
        case .struggling:
            return "The Lord is close to the brokenhearted. - Psalm 34:18"
        }
    }
    
    /// Prompt suggestion based on mood
    var promptSuggestion: String {
        switch self {
        case .joyful:
            return "What blessing brought you joy today?"
        case .peaceful:
            return "What helped you find peace in God's presence?"
        case .grateful:
            return "List three things you're thankful for right now."
        case .hopeful:
            return "What promise of God are you holding onto?"
        case .reflective:
            return "What has God been teaching you lately?"
        case .anxious:
            return "What worries can you surrender to God today?"
        case .struggling:
            return "How can you invite God into your struggle?"
        }
    }
}

// MARK: - Mood Statistics

/// Statistics about mood entries over time
struct MoodStatistics {
    let entries: [JournalEntry]
    
    init(entries: [JournalEntry]) {
        self.entries = entries
    }
    
    /// Count of each mood
    var moodCounts: [JournalMood: Int] {
        var counts: [JournalMood: Int] = [:]
        for entry in entries {
            if let mood = entry.mood {
                counts[mood, default: 0] += 1
            }
        }
        return counts
    }
    
    /// Most common mood
    var dominantMood: JournalMood? {
        moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Percentage of positive moods
    var positivityRate: Double {
        let positiveMoods: Set<JournalMood> = [.joyful, .peaceful, .grateful, .hopeful]
        let positiveCount = entries.filter { entry in
            guard let mood = entry.mood else { return false }
            return positiveMoods.contains(mood)
        }.count
        
        guard !entries.isEmpty else { return 0 }
        return Double(positiveCount) / Double(entries.count)
    }
    
    /// Mood trend (positive, negative, or neutral)
    var trend: MoodTrend {
        guard entries.count >= 3 else { return .neutral }
        
        let recent = Array(entries.prefix(3))
        let positiveMoods: Set<JournalMood> = [.joyful, .peaceful, .grateful, .hopeful]
        
        let recentPositive = recent.filter { entry in
            guard let mood = entry.mood else { return false }
            return positiveMoods.contains(mood)
        }.count
        
        if recentPositive >= 2 {
            return .improving
        } else if recentPositive == 0 {
            return .declining
        }
        return .neutral
    }
}

/// Mood trend indicator
enum MoodTrend: String {
    case improving
    case declining
    case neutral
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .orange
        case .neutral: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .improving: return "Trending positive"
        case .declining: return "Needs attention"
        case .neutral: return "Stable"
        }
    }
}

