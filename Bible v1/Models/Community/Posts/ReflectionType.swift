//
//  ReflectionType.swift
//  Bible v1
//
//  Community Tab - Reflection Type Enum
//

import Foundation
import SwiftUI

/// Types of reflections on scripture
enum ReflectionType: String, Codable, CaseIterable, Identifiable {
    case insight = "insight"
    case question = "question"
    case prayer = "prayer"
    case testimony = "testimony"
    case teaching = "teaching"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .insight: return "Insight"
        case .question: return "Question"
        case .prayer: return "Prayer"
        case .testimony: return "Testimony"
        case .teaching: return "Teaching"
        }
    }
    
    var icon: String {
        switch self {
        case .insight: return "lightbulb"
        case .question: return "questionmark.circle"
        case .prayer: return "hands.sparkles"
        case .testimony: return "heart.text.square"
        case .teaching: return "book.closed"
        }
    }
    
    var description: String {
        switch self {
        case .insight: return "A personal revelation or understanding"
        case .question: return "Something you're wondering about"
        case .prayer: return "A prayer inspired by this passage"
        case .testimony: return "How this scripture impacted your life"
        case .teaching: return "An explanation or exposition"
        }
    }
    
    var color: Color {
        switch self {
        case .insight: return .yellow
        case .question: return .orange
        case .prayer: return .purple
        case .testimony: return .pink
        case .teaching: return .blue
        }
    }
}

