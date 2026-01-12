//
//  TrendingItem.swift
//  Bible v1
//
//  Community Tab - Trending Item Model
//

import Foundation
import SwiftUI

/// A trending item (verse, topic, or tag)
struct TrendingItem: Identifiable, Codable {
    let id: UUID
    let type: TrendingType
    let identifier: String
    var score: Double
    var postCount24h: Int
    var engagement24h: Int
    let computedAt: Date
    
    // Additional data based on type
    var verseRef: PostVerseRef?
    var verseText: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, identifier, score
        case postCount24h = "post_count_24h"
        case engagement24h = "engagement_24h"
        case computedAt = "computed_at"
        case verseRef = "verse_ref"
        case verseText = "verse_text"
    }
    
    init(
        id: UUID = UUID(),
        type: TrendingType,
        identifier: String,
        score: Double = 0,
        postCount24h: Int = 0,
        engagement24h: Int = 0,
        computedAt: Date = Date(),
        verseRef: PostVerseRef? = nil,
        verseText: String? = nil
    ) {
        self.id = id
        self.type = type
        self.identifier = identifier
        self.score = score
        self.postCount24h = postCount24h
        self.engagement24h = engagement24h
        self.computedAt = computedAt
        self.verseRef = verseRef
        self.verseText = verseText
    }
    
    /// Display name for the item
    var displayName: String {
        switch type {
        case .verse:
            return verseRef?.shortReference ?? identifier
        case .topic, .tag:
            return identifier
        }
    }
    
    /// Formatted post count
    var formattedPostCount: String {
        if postCount24h >= 1000 {
            return String(format: "%.1fK", Double(postCount24h) / 1000.0)
        }
        return "\(postCount24h)"
    }
}

/// Types of trending items
enum TrendingType: String, Codable, CaseIterable {
    case verse = "verse"
    case topic = "topic"
    case tag = "tag"
    
    var displayName: String {
        switch self {
        case .verse: return "Verses"
        case .topic: return "Topics"
        case .tag: return "Tags"
        }
    }
    
    var icon: String {
        switch self {
        case .verse: return "book.fill"
        case .topic: return "bubble.left.and.bubble.right.fill"
        case .tag: return "tag.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .verse: return .blue
        case .topic: return .orange
        case .tag: return .purple
        }
    }
}

/// Time range for trending
enum TrendingTimeRange: String, CaseIterable {
    case day = "24h"
    case week = "7d"
    case month = "30d"
    
    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        }
    }
    
    var hours: Int {
        switch self {
        case .day: return 24
        case .week: return 168
        case .month: return 720
        }
    }
}

