//
//  PostType.swift
//  Bible v1
//
//  Community Tab - Post Type Enum
//

import Foundation
import SwiftUI

/// Types of posts in the community
enum PostType: String, Codable, CaseIterable, Identifiable {
    case reflection = "reflection"
    case question = "question"
    case prayer = "prayer"
    case testimony = "testimony"
    case image = "image"
    case verseCard = "verse_card"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .reflection: return "Reflection"
        case .question: return "Question"
        case .prayer: return "Prayer Request"
        case .testimony: return "Testimony"
        case .image: return "Photo"
        case .verseCard: return "Verse Card"
        }
    }
    
    var icon: String {
        switch self {
        case .reflection: return "text.quote"
        case .question: return "questionmark.circle"
        case .prayer: return "hands.sparkles"
        case .testimony: return "heart.text.square"
        case .image: return "photo"
        case .verseCard: return "rectangle.on.rectangle"
        }
    }
    
    var description: String {
        switch self {
        case .reflection: return "Share your thoughts on scripture"
        case .question: return "Ask the community a question"
        case .prayer: return "Request prayer from the community"
        case .testimony: return "Share what God has done"
        case .image: return "Share an image with reflection"
        case .verseCard: return "Create a shareable verse card"
        }
    }
    
    var color: Color {
        switch self {
        case .reflection: return .blue
        case .question: return .orange
        case .prayer: return .purple
        case .testimony: return .pink
        case .image: return .green
        case .verseCard: return .cyan
        }
    }
    
    /// Whether this post type requires a verse attachment
    var requiresVerse: Bool {
        switch self {
        case .verseCard: return true
        default: return false
        }
    }
    
    /// Whether this post type supports anonymous posting
    var supportsAnonymous: Bool {
        switch self {
        case .prayer, .question, .reflection: return true
        default: return false
        }
    }
    
    /// Suggested feed mode for this post type
    var suggestedMode: FeedMode {
        switch self {
        case .testimony, .verseCard, .image: return .inspire
        case .question, .reflection: return .discuss
        case .prayer: return .pray
        }
    }
}

/// Visibility levels for posts
enum PostVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case followers = "followers"
    case group = "group"
    
    var displayName: String {
        switch self {
        case .public: return "Public"
        case .followers: return "Followers Only"
        case .group: return "Group Only"
        }
    }
    
    var icon: String {
        switch self {
        case .public: return "globe"
        case .followers: return "person.2"
        case .group: return "person.3"
        }
    }
    
    var description: String {
        switch self {
        case .public: return "Anyone can see this post"
        case .followers: return "Only your followers can see this"
        case .group: return "Only group members can see this"
        }
    }
}

/// Feed modes in the Community tab
enum FeedMode: String, CaseIterable, Identifiable {
    case inspire = "inspire"
    case discuss = "discuss"
    case pray = "pray"
    case study = "study"
    case live = "live"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .inspire: return "Inspire"
        case .discuss: return "Discuss"
        case .pray: return "Pray"
        case .study: return "Study"
        case .live: return "Live"
        }
    }
    
    var icon: String {
        switch self {
        case .inspire: return "sparkles"
        case .discuss: return "bubble.left.and.bubble.right"
        case .pray: return "hands.sparkles"
        case .study: return "book.closed"
        case .live: return "dot.radiowaves.left.and.right"
        }
    }
    
    var description: String {
        switch self {
        case .inspire: return "Testimonies, verse cards, encouragement"
        case .discuss: return "Questions, threads, conversations"
        case .pray: return "Prayer requests and prayer circles"
        case .study: return "Groups, reading plans, studies"
        case .live: return "Live audio and video rooms"
        }
    }
    
    /// Post types shown in this mode
    var postTypes: [PostType] {
        switch self {
        case .inspire: return [.testimony, .verseCard, .image]
        case .discuss: return [.reflection, .question]
        case .pray: return [.prayer]
        case .study: return [.reflection, .question]
        case .live: return []
        }
    }
}

