//
//  AIMode.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Mode Definitions
//

import Foundation
import SwiftUI
import Combine

/// The three interaction modes for the AI Bible Assistant
enum AIMode: String, Codable, CaseIterable, Identifiable {
    case study = "study"
    case devotional = "devotional"
    case prayer = "prayer"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .study: return "Study"
        case .devotional: return "Devotional"
        case .prayer: return "Prayer"
        }
    }
    
    var icon: String {
        switch self {
        case .study: return "book.fill"
        case .devotional: return "heart.fill"
        case .prayer: return "hands.sparkles.fill"
        }
    }
    
    var description: String {
        switch self {
        case .study:
            return "Deep theological analysis with cross-references and historical context"
        case .devotional:
            return "Personal application and spiritual encouragement"
        case .prayer:
            return "Scripture-based prayer guidance and prompts"
        }
    }
    
    var systemPromptAddition: String {
        switch self {
        case .study:
            return """
            You are in STUDY mode. Provide:
            - Deep theological analysis and exegesis
            - Historical and cultural context
            - Cross-references to related passages
            - Word studies when relevant
            - Multiple scholarly viewpoints on disputed interpretations
            Keep answers thorough but accessible.
            """
        case .devotional:
            return """
            You are in DEVOTIONAL mode. Provide:
            - Personal, warm encouragement
            - Practical life application
            - Reflection questions
            - How the passage speaks to daily life
            Keep answers heartfelt and relatable.
            """
        case .prayer:
            return """
            You are in PRAYER mode. Provide:
            - Scripture-based prayer prompts
            - Prayer structure guidance (ACTS, etc.)
            - Verses to pray back to God
            - Contemplative reflection points
            Keep answers spiritually nurturing and prayer-focused.
            """
        }
    }
    
    var accentColor: Color {
        switch self {
        case .study: return .blue
        case .devotional: return .pink
        case .prayer: return .purple
        }
    }
}

