//
//  AIUserPreferences.swift
//  Bible v1
//
//  TRC AI Bible Assistant - User Preferences Model
//

import Foundation
import SwiftUI

/// User preferences for AI response customization
struct AIUserPreferences: Codable, Equatable {
    var defaultTranslation: String
    var responseTone: ResponseTone
    var readingLevel: ReadingLevel
    var denominationLens: DenominationLens
    var avoidControversialTopics: Bool
    var preferredResponseLength: ResponseLength
    var selectedPersona: AIPersona
    var customInstructions: String
    
    init(
        defaultTranslation: String = "engKJV",
        responseTone: ResponseTone = .balanced,
        readingLevel: ReadingLevel = .standard,
        denominationLens: DenominationLens = .neutral,
        avoidControversialTopics: Bool = false,
        preferredResponseLength: ResponseLength = .medium,
        selectedPersona: AIPersona = .friend,
        customInstructions: String = ""
    ) {
        self.defaultTranslation = defaultTranslation
        self.responseTone = responseTone
        self.readingLevel = readingLevel
        self.denominationLens = denominationLens
        self.avoidControversialTopics = avoidControversialTopics
        self.preferredResponseLength = preferredResponseLength
        self.selectedPersona = selectedPersona
        self.customInstructions = customInstructions
    }
    
    static let `default` = AIUserPreferences()
    
    /// Check if user has custom instructions set
    var hasCustomInstructions: Bool {
        !customInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Response Tone

/// The emotional tone of AI responses
enum ResponseTone: String, Codable, CaseIterable, Identifiable {
    case gentle = "Gentle"
    case balanced = "Balanced"
    case direct = "Direct"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .gentle:
            return "Warm, encouraging, and nurturing"
        case .balanced:
            return "Clear and supportive"
        case .direct:
            return "Straightforward and concise"
        }
    }
    
    var icon: String {
        switch self {
        case .gentle: return "heart"
        case .balanced: return "scale.3d"
        case .direct: return "bolt"
        }
    }
    
    var systemPromptInstruction: String {
        switch self {
        case .gentle:
            return "Be especially warm, gentle, and encouraging. Use soft language and affirmations. Treat the user with pastoral care."
        case .balanced:
            return "Be clear and supportive. Balance warmth with directness."
        case .direct:
            return "Be straightforward and concise. Get to the point quickly while remaining respectful."
        }
    }
}

// MARK: - Reading Level

/// The complexity level of AI responses
enum ReadingLevel: String, Codable, CaseIterable, Identifiable {
    case simple = "Simple"
    case standard = "Standard"
    case scholarly = "Scholarly"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .simple:
            return "Easy to understand, everyday language"
        case .standard:
            return "Clear explanations with some depth"
        case .scholarly:
            return "Academic depth with technical terms"
        }
    }
    
    var icon: String {
        switch self {
        case .simple: return "book.closed"
        case .standard: return "book"
        case .scholarly: return "books.vertical"
        }
    }
    
    var systemPromptInstruction: String {
        switch self {
        case .simple:
            return "Use simple, everyday language. Avoid theological jargon. Explain concepts as if to someone new to faith."
        case .standard:
            return "Use clear language with appropriate theological vocabulary. Explain technical terms when first used."
        case .scholarly:
            return "You may use academic theological language, Greek/Hebrew terms, and assume familiarity with biblical scholarship."
        }
    }
}

// MARK: - Denomination Lens

/// The theological perspective for AI responses
enum DenominationLens: String, Codable, CaseIterable, Identifiable {
    case neutral = "Neutral"
    case reformed = "Reformed"
    case catholic = "Catholic"
    case orthodox = "Orthodox"
    case evangelical = "Evangelical"
    case mainlineProtestant = "Mainline Protestant"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .neutral:
            return "Balanced perspective from multiple traditions"
        case .reformed:
            return "Calvinist/Reformed theology emphasis"
        case .catholic:
            return "Roman Catholic tradition and Magisterium"
        case .orthodox:
            return "Eastern Orthodox tradition and Fathers"
        case .evangelical:
            return "Evangelical Protestant perspective"
        case .mainlineProtestant:
            return "Mainline Protestant traditions"
        }
    }
    
    var icon: String {
        switch self {
        case .neutral: return "circle.hexagongrid"
        case .reformed: return "building.columns"
        case .catholic: return "cross"
        case .orthodox: return "sparkles"
        case .evangelical: return "flame"
        case .mainlineProtestant: return "building.2"
        }
    }
    
    var systemPromptInstruction: String {
        switch self {
        case .neutral:
            return "Present balanced perspectives from multiple Christian traditions. When denominations differ, acknowledge the different viewpoints fairly."
        case .reformed:
            return "Emphasize Reformed/Calvinist theological perspectives, including the doctrines of grace, covenant theology, and the sovereignty of God."
        case .catholic:
            return "Draw from Catholic tradition, the Church Fathers, and Magisterial teaching. Reference the Catechism when appropriate."
        case .orthodox:
            return "Emphasize Eastern Orthodox tradition, the Church Fathers, theosis, and liturgical theology."
        case .evangelical:
            return "Emphasize evangelical Protestant perspectives, personal relationship with Christ, Scripture's authority, and salvation by grace through faith."
        case .mainlineProtestant:
            return "Draw from mainline Protestant traditions including Methodist, Lutheran, Presbyterian, Episcopal, and UCC perspectives."
        }
    }
}

// MARK: - Response Length

/// Preferred length of AI responses
enum ResponseLength: String, Codable, CaseIterable, Identifiable {
    case brief = "Brief"
    case medium = "Medium"
    case detailed = "Detailed"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .brief:
            return "Short and to the point"
        case .medium:
            return "Balanced depth and brevity"
        case .detailed:
            return "Comprehensive and thorough"
        }
    }
    
    var icon: String {
        switch self {
        case .brief: return "text.alignleft"
        case .medium: return "text.justify"
        case .detailed: return "doc.text"
        }
    }
    
    var tokenLimit: Int {
        switch self {
        case .brief: return 800
        case .medium: return 1500
        case .detailed: return 2500
        }
    }
    
    var systemPromptInstruction: String {
        switch self {
        case .brief:
            return "Keep responses concise - 2-3 paragraphs maximum. Focus on the essential points."
        case .medium:
            return "Provide balanced responses with appropriate depth. Aim for 3-5 paragraphs."
        case .detailed:
            return "Provide thorough, comprehensive responses. Include context, examples, and cross-references."
        }
    }
}

