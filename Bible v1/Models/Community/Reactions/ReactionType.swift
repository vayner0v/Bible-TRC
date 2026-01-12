//
//  ReactionType.swift
//  Bible v1
//
//  Community Tab - Reaction Type Enum
//

import Foundation
import SwiftUI

/// Types of reactions available
enum ReactionType: String, Codable, CaseIterable, Identifiable {
    case amen = "amen"
    case prayed = "prayed"
    case love = "love"
    case helpful = "helpful"
    case curious = "curious"
    case hug = "hug"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .amen: return "Amen"
        case .prayed: return "Prayed"
        case .love: return "Love"
        case .helpful: return "Helpful"
        case .curious: return "Curious"
        case .hug: return "Hug"
        }
    }
    
    var emoji: String {
        switch self {
        case .amen: return "🙌"
        case .prayed: return "🙏"
        case .love: return "❤️"
        case .helpful: return "💡"
        case .curious: return "❓"
        case .hug: return "🤗"
        }
    }
    
    var icon: String {
        switch self {
        case .amen: return "hands.clap.fill"
        case .prayed: return "hands.sparkles.fill"
        case .love: return "heart.fill"
        case .helpful: return "lightbulb.fill"
        case .curious: return "questionmark.circle.fill"
        case .hug: return "figure.2.arms.open"
        }
    }
    
    var color: Color {
        switch self {
        case .amen: return .orange
        case .prayed: return .purple
        case .love: return .pink
        case .helpful: return .yellow
        case .curious: return .blue
        case .hug: return .green
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .amen: return "React with Amen"
        case .prayed: return "I prayed for this"
        case .love: return "React with Love"
        case .helpful: return "Mark as Helpful"
        case .curious: return "I'm curious about this"
        case .hug: return "Send a hug"
        }
    }
    
    /// Haptic feedback type for this reaction
    var hapticType: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .amen: return .medium
        case .prayed: return .soft
        case .love: return .light
        case .helpful: return .light
        case .curious: return .light
        case .hug: return .soft
        }
    }
    
    /// Animation duration for this reaction
    var animationDuration: Double {
        switch self {
        case .prayed: return 0.8
        case .amen: return 0.6
        default: return 0.4
        }
    }
    
    /// Whether this reaction is special for prayer requests
    var isPrayerReaction: Bool {
        self == .prayed
    }
    
    /// Suggested reactions for different post types
    static func suggested(for postType: PostType) -> [ReactionType] {
        switch postType {
        case .prayer:
            return [.prayed, .hug, .love, .amen]
        case .question:
            return [.helpful, .curious, .amen, .love]
        case .testimony:
            return [.amen, .love, .hug, .prayed]
        case .reflection, .verseCard, .image:
            return [.amen, .love, .helpful, .curious]
        }
    }
}

