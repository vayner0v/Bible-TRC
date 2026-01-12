//
//  AIResponse.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Response Models
//

import Foundation

/// The structured JSON response from the LLM
struct AIResponse: Codable {
    let mode: String
    let title: String
    let answerMarkdown: String
    let citations: [RawCitation]
    let followUps: [String]
    let actions: [AIAction]
    
    enum CodingKeys: String, CodingKey {
        case mode
        case title
        case answerMarkdown = "answer_markdown"
        case citations
        case followUps = "follow_ups"
        case actions
    }
    
    /// Parse the mode string to AIMode enum
    var parsedMode: AIMode {
        AIMode(rawValue: mode.lowercased()) ?? .study
    }
    
    /// Validate and filter follow-ups for quality
    /// Returns follow-ups that are not generic or too short
    var validatedFollowUps: [String] {
        let genericPhrases = [
            "tell me more",
            "what else",
            "anything else",
            "more information",
            "learn more",
            "continue",
            "go on"
        ]
        
        return followUps.filter { followUp in
            // Must be at least 15 characters
            guard followUp.count >= 15 else { return false }
            
            // Must not be a generic phrase
            let lowercased = followUp.lowercased()
            for generic in genericPhrases {
                if lowercased.contains(generic) && followUp.count < 30 {
                    return false
                }
            }
            
            // Must contain a question mark or be phrased as a request
            let hasQuestionIndicator = followUp.contains("?") ||
                                       lowercased.hasPrefix("how") ||
                                       lowercased.hasPrefix("what") ||
                                       lowercased.hasPrefix("why") ||
                                       lowercased.hasPrefix("when") ||
                                       lowercased.hasPrefix("where") ||
                                       lowercased.hasPrefix("who") ||
                                       lowercased.hasPrefix("can you") ||
                                       lowercased.hasPrefix("could you") ||
                                       lowercased.hasPrefix("help me")
            
            return hasQuestionIndicator
        }
    }
    
    /// Check if the response has high-quality follow-ups
    var hasQualityFollowUps: Bool {
        validatedFollowUps.count >= 2
    }
}

/// An action the user can take from an AI response
struct AIAction: Codable, Identifiable, Hashable, Equatable {
    let type: String
    let reference: String?
    let label: String?
    
    var id: String {
        "\(type)_\(reference ?? "")_\(label ?? "")"
    }
    
    var actionType: AIActionType {
        AIActionType(rawValue: type) ?? .openVerse
    }
    
    // MARK: - Hashable & Equatable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(reference)
        hasher.combine(label)
    }
    
    static func == (lhs: AIAction, rhs: AIAction) -> Bool {
        lhs.type == rhs.type && lhs.reference == rhs.reference && lhs.label == rhs.label
    }
}

/// Types of actions available in AI responses
enum AIActionType: String, Codable {
    case openVerse = "openVerse"
    case openChapter = "openChapter"
    case saveToJournal = "saveToJournal"
    case shareResponse = "shareResponse"
    case goDeeper = "goDeeper"
    case makeShorter = "makeShorter"
    
    var icon: String {
        switch self {
        case .openVerse: return "book.fill"
        case .openChapter: return "doc.text.fill"
        case .saveToJournal: return "square.and.pencil"
        case .shareResponse: return "square.and.arrow.up"
        case .goDeeper: return "arrow.down.circle.fill"
        case .makeShorter: return "arrow.up.circle.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .openVerse: return "Open Verse"
        case .openChapter: return "Open Chapter"
        case .saveToJournal: return "Save to Journal"
        case .shareResponse: return "Share"
        case .goDeeper: return "Go Deeper"
        case .makeShorter: return "Make Shorter"
        }
    }
}

/// Safety response when crisis is detected
struct SafetyResponse {
    let message: String
    let calmingVerses: [AICitation]
    let resourceLinks: [SafetyResource]
    
    static let selfHarmResponse = SafetyResponse(
        message: """
        I can see you're going through something really difficult right now, and I'm genuinely concerned about you. Your life matters, and there is hope even when it doesn't feel that way.
        
        Please reach out to someone who can help:
        
        **National Suicide Prevention Lifeline**: 988 (call or text)
        **Crisis Text Line**: Text HOME to 741741
        
        You don't have to face this alone. God loves you deeply, and there are people ready to listen and help right now.
        """,
        calmingVerses: [
            AICitation(reference: "Psalm 34:18", translationId: "engKJV"),
            AICitation(reference: "Isaiah 41:10", translationId: "engKJV")
        ],
        resourceLinks: [
            SafetyResource(name: "988 Suicide & Crisis Lifeline", url: "https://988lifeline.org"),
            SafetyResource(name: "Crisis Text Line", url: "https://www.crisistextline.org")
        ]
    )
    
    static let abuseResponse = SafetyResponse(
        message: """
        I hear you, and what you're describing is serious. You deserve to be safe, and what's happening to you is not okay.
        
        Please consider reaching out for help:
        
        **National Domestic Violence Hotline**: 1-800-799-7233
        **RAINN (Sexual Assault)**: 1-800-656-4673
        
        These services are confidential and available 24/7. You are not alone.
        """,
        calmingVerses: [
            AICitation(reference: "Psalm 46:1", translationId: "engKJV"),
            AICitation(reference: "Psalm 27:1", translationId: "engKJV")
        ],
        resourceLinks: [
            SafetyResource(name: "National Domestic Violence Hotline", url: "https://www.thehotline.org"),
            SafetyResource(name: "RAINN", url: "https://www.rainn.org")
        ]
    )
    
    static let griefLossResponse = SafetyResponse(
        message: """
        I'm so deeply sorry for your loss. Grief is one of the most profound experiences we face, and it's okay to feel whatever you're feeling right now.
        
        God sees your pain and draws near to you in this moment:
        
        *"The Lord is close to the brokenhearted and saves those who are crushed in spirit."* — Psalm 34:18
        
        *"Blessed are those who mourn, for they will be comforted."* — Matthew 5:4
        
        You don't have to walk this journey alone. When you're ready, these resources may help:
        
        **GriefShare**: Faith-based grief recovery groups in your area
        **Your local church**: Many offer grief support ministries
        
        I'm here to listen, pray with you, or explore Scripture together—whatever would bring you comfort.
        """,
        calmingVerses: [
            AICitation(reference: "Psalm 34:18", translationId: "engKJV"),
            AICitation(reference: "Matthew 5:4", translationId: "engKJV"),
            AICitation(reference: "Revelation 21:4", translationId: "engKJV"),
            AICitation(reference: "Psalm 23:4", translationId: "engKJV")
        ],
        resourceLinks: [
            SafetyResource(name: "GriefShare", url: "https://www.griefshare.org"),
            SafetyResource(name: "Focus on the Family - Grief Resources", url: "https://www.focusonthefamily.com/get-help/grief-resources")
        ]
    )
}

/// A safety resource link
struct SafetyResource: Identifiable {
    let id = UUID()
    let name: String
    let url: String
}

/// Error types for AI response parsing
enum AIResponseError: LocalizedError {
    case invalidJSON
    case missingRequiredField(String)
    case networkError(Error)
    case rateLimited
    case usageLimitExceeded
    case safetyTriggered(SafetyResponse)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Failed to parse AI response"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .usageLimitExceeded:
            return "You've reached your message limit. Upgrade to Premium for unlimited access."
        case .safetyTriggered:
            return "Safety response triggered"
        }
    }
}

