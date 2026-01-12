//
//  SafetyClassifier.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Safety Classification System
//

import Foundation

/// Classifies user messages for safety concerns and provides appropriate responses
class SafetyClassifier {
    static let shared = SafetyClassifier()
    
    // MARK: - Safety Categories
    
    enum SafetyCategory: String, CaseIterable {
        case selfHarm = "self_harm"
        case violence = "violence"
        case abuse = "abuse"
        case medicalEmergency = "medical_emergency"
        case griefLoss = "grief_loss"
        case none = "none"
        
        var requiresIntervention: Bool {
            self != .none && self != .griefLoss
        }
        
        var requiresCompassionateResponse: Bool {
            self == .griefLoss
        }
    }
    
    // MARK: - Keyword Patterns
    
    /// Keywords indicating potential self-harm or suicidal ideation
    private let selfHarmKeywords: Set<String> = [
        "kill myself", "end my life", "want to die", "suicide", "suicidal",
        "don't want to live", "don't want to be alive", "better off dead",
        "end it all", "no reason to live", "give up on life", "take my life",
        "hurt myself", "self harm", "cut myself", "cutting myself",
        "overdose", "hang myself", "jump off", "can't go on", "nothing left",
        "final goodbye", "last message", "before i go", "planning to end",
        "no way out", "wish i was dead", "wish i were dead"
    ]
    
    /// Keywords indicating potential violence to others
    private let violenceKeywords: Set<String> = [
        "kill someone", "hurt someone", "harm someone", "attack someone",
        "murder", "shoot up", "bomb", "weapon", "mass shooting",
        "want to hurt", "going to hurt", "make them pay", "revenge violence",
        "kill them", "hurt them all"
    ]
    
    /// Keywords indicating potential abuse situations
    private let abuseKeywords: Set<String> = [
        "being abused", "abusing me", "hits me", "beats me", "hurts me",
        "molested", "raped", "sexual abuse", "sexually abused", "trafficking",
        "domestic violence", "domestic abuse", "partner hits", "spouse hits",
        "forced to", "held against", "can't leave", "won't let me leave",
        "threatened to kill", "afraid for my life", "child abuse"
    ]
    
    /// Keywords indicating medical emergency
    private let medicalEmergencyKeywords: Set<String> = [
        "having a heart attack", "can't breathe", "chest pain emergency",
        "overdosed", "took too many pills", "poisoned", "bleeding heavily",
        "severe allergic", "anaphylaxis", "stroke symptoms"
    ]
    
    /// Keywords indicating grief or loss
    private let griefLossKeywords: Set<String> = [
        "my mom died", "my dad died", "my father died", "my mother died",
        "my spouse died", "my husband died", "my wife died", "my child died",
        "my son died", "my daughter died", "my baby died", "lost my baby",
        "lost my child", "lost my spouse", "lost my husband", "lost my wife",
        "funeral", "passed away", "just died", "recently died", "death of my",
        "grieving", "grief", "mourning", "bereaved", "lost someone",
        "miscarriage", "stillborn", "lost the baby", "baby passed",
        "terminal diagnosis", "dying of cancer", "hospice", "last days"
    ]
    
    /// Metaphorical/figurative expressions that should NOT trigger safety (context-aware)
    private let metaphoricalPatterns: Set<String> = [
        "kill it", "killing it", "killed it", "gonna kill it", "going to kill it",
        "slay", "slaying", "slayed",
        "crush it", "crushing it", "crushed it",
        "nail it", "nailed it", "nailing it",
        "dead tired", "dead serious", "dead wrong", "dead on",
        "dying to", "dying for", "i'm dying", "literally dying",
        "you're killing me", "killing me",
        "murder this exam", "murder that presentation",
        "destroy it", "destroyed it", "destroying it",
        "bomb it", "bombed it"
    ]
    
    /// Context indicators that suggest non-literal usage
    private let nonLiteralContextIndicators: Set<String> = [
        "presentation", "exam", "test", "interview", "meeting", "performance",
        "audition", "competition", "game", "match", "workout", "marathon",
        "project", "deadline", "work", "job", "career", "business",
        "speech", "talk", "pitch", "demo", "show", "concert", "gig",
        "lol", "lmao", "haha", "😂", "🔥", "💪", "excited", "nervous"
    ]
    
    // MARK: - Classification
    
    /// Classify a message and return the appropriate category
    func classify(_ message: String) -> SafetyCategory {
        let lowercased = message.lowercased()
        
        // First check for metaphorical/figurative usage to avoid false positives
        if isLikelyMetaphorical(lowercased) {
            // Even if keywords match, context suggests non-literal usage
            // Still check for grief/loss which doesn't have metaphorical usage
            if containsKeywords(lowercased, from: griefLossKeywords) {
                return .griefLoss
            }
            return .none
        }
        
        // Check each category in order of severity
        if containsKeywords(lowercased, from: selfHarmKeywords) {
            return .selfHarm
        }
        
        if containsKeywords(lowercased, from: violenceKeywords) {
            return .violence
        }
        
        if containsKeywords(lowercased, from: abuseKeywords) {
            return .abuse
        }
        
        if containsKeywords(lowercased, from: medicalEmergencyKeywords) {
            return .medicalEmergency
        }
        
        // Check for grief/loss (requires compassionate but not crisis response)
        if containsKeywords(lowercased, from: griefLossKeywords) {
            return .griefLoss
        }
        
        return .none
    }
    
    /// Classify with conversation history context for better accuracy
    func classifyWithContext(_ message: String, history: [ChatMessage]) -> SafetyCategory {
        let lowercased = message.lowercased()
        
        // Build context from recent conversation
        let recentContext = history.suffix(3)
            .map { $0.content.lowercased() }
            .joined(separator: " ")
        
        // Check if recent context suggests casual/positive conversation
        let casualContextIndicators = ["excited", "happy", "looking forward", "can't wait", 
                                        "nervous about", "preparing for", "working on"]
        let hasPositiveContext = casualContextIndicators.contains { recentContext.contains($0) }
        
        // If positive context and metaphorical patterns match, likely not a crisis
        if hasPositiveContext && isLikelyMetaphorical(lowercased) {
            return .none
        }
        
        // Fall back to standard classification
        return classify(message)
    }
    
    /// Check if message needs safety intervention
    func needsIntervention(_ message: String) -> Bool {
        classify(message).requiresIntervention
    }
    
    /// Check if message indicates grief/loss needing compassionate response
    func needsCompassionateResponse(_ message: String) -> Bool {
        classify(message).requiresCompassionateResponse
    }
    
    // MARK: - Context-Aware Analysis
    
    /// Check if the message is likely using metaphorical/figurative language
    private func isLikelyMetaphorical(_ text: String) -> Bool {
        // Check for metaphorical patterns
        let hasMetaphoricalPattern = metaphoricalPatterns.contains { text.contains($0) }
        
        // Check for context indicators suggesting non-literal usage
        let hasNonLiteralContext = nonLiteralContextIndicators.contains { text.contains($0) }
        
        // If both a metaphorical pattern AND context indicator are present, likely figurative
        if hasMetaphoricalPattern && hasNonLiteralContext {
            return true
        }
        
        // Check for specific safe patterns
        let safePatterns = [
            "kill it at", "killing it at", "gonna kill this", "going to kill this",
            "kill this presentation", "kill this interview", "kill this exam",
            "slay the", "crushing it at", "nail this", "nailed the",
            "dead tired from", "literally dying of", "dying to see", "dying to know"
        ]
        
        for pattern in safePatterns {
            if text.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Get the appropriate safety response for a category
    func getSafetyResponse(for category: SafetyCategory) -> SafetyResponse {
        switch category {
        case .selfHarm:
            return SafetyResponse.selfHarmResponse
        case .violence:
            return SafetyResponse(
                message: """
                I'm concerned about what you've shared. If you're having thoughts of harming others, please reach out for support immediately.
                
                **National Alliance on Mental Illness (NAMI)**: 1-800-950-NAMI (6264)
                **Crisis Text Line**: Text HOME to 741741
                
                If there's an immediate threat, please contact emergency services (911).
                
                You don't have to face these feelings alone. Professional help can make a real difference.
                """,
                calmingVerses: [
                    AICitation(reference: "Proverbs 14:29", translationId: "engKJV"),
                    AICitation(reference: "James 1:19-20", translationId: "engKJV")
                ],
                resourceLinks: [
                    SafetyResource(name: "NAMI Helpline", url: "https://www.nami.org/help"),
                    SafetyResource(name: "SAMHSA National Helpline", url: "https://www.samhsa.gov/find-help/national-helpline")
                ]
            )
        case .abuse:
            return SafetyResponse.abuseResponse
        case .medicalEmergency:
            return SafetyResponse(
                message: """
                This sounds like a medical emergency. Please call emergency services immediately:
                
                **Emergency**: 911 (US) or your local emergency number
                **Poison Control**: 1-800-222-1222
                
                If you're with someone experiencing a medical emergency, stay with them and keep them calm until help arrives.
                
                I'm here to support you spiritually, but right now you need medical professionals.
                """,
                calmingVerses: [
                    AICitation(reference: "Psalm 46:1", translationId: "engKJV")
                ],
                resourceLinks: []
            )
        case .griefLoss:
            return SafetyResponse.griefLossResponse
        case .none:
            // This shouldn't be called for .none, but provide a fallback
            return SafetyResponse(
                message: "I'm here to help you explore Scripture. What would you like to discuss?",
                calmingVerses: [],
                resourceLinks: []
            )
        }
    }
    
    /// Get a compassionate response for grief/loss that doesn't block AI conversation
    func getGriefAcknowledgment() -> String {
        return """
        I'm so deeply sorry for your loss. Grief is a profound and sacred journey, and you don't have to walk it alone.
        
        Know that God sees your pain: *"The Lord is close to the brokenhearted and saves those who are crushed in spirit."* (Psalm 34:18)
        
        I'm here to listen, pray with you, or explore Scripture together—whatever would bring you comfort right now.
        """
    }
    
    /// Create a ChatMessage from a safety response
    func createSafetyMessage(for category: SafetyCategory) -> ChatMessage {
        let response = getSafetyResponse(for: category)
        return ChatMessage.safety(response)
    }
    
    // MARK: - Private Helpers
    
    private func containsKeywords(_ text: String, from keywords: Set<String>) -> Bool {
        for keyword in keywords {
            if text.contains(keyword) {
                return true
            }
        }
        return false
    }
}

// MARK: - Safety Check Result

/// Result of a safety check on user input
struct SafetyCheckResult {
    let category: SafetyClassifier.SafetyCategory
    let isTriggered: Bool
    let isCompassionate: Bool
    let response: SafetyResponse?
    
    /// Check if AI should continue with modified behavior
    var shouldContinueWithCompassion: Bool {
        isCompassionate && !isTriggered
    }
    
    static func safe() -> SafetyCheckResult {
        SafetyCheckResult(category: .none, isTriggered: false, isCompassionate: false, response: nil)
    }
    
    static func triggered(category: SafetyClassifier.SafetyCategory, response: SafetyResponse) -> SafetyCheckResult {
        SafetyCheckResult(category: category, isTriggered: true, isCompassionate: false, response: response)
    }
    
    static func compassionate(category: SafetyClassifier.SafetyCategory, response: SafetyResponse) -> SafetyCheckResult {
        SafetyCheckResult(category: category, isTriggered: false, isCompassionate: true, response: response)
    }
}

// MARK: - Content Moderation

extension SafetyClassifier {
    
    /// Perform a full safety check on user input
    func performSafetyCheck(_ message: String) -> SafetyCheckResult {
        let category = classify(message)
        
        if category.requiresIntervention {
            let response = getSafetyResponse(for: category)
            return .triggered(category: category, response: response)
        }
        
        // For grief/loss, return a compassionate result that doesn't block AI
        if category.requiresCompassionateResponse {
            let response = getSafetyResponse(for: category)
            return .compassionate(category: category, response: response)
        }
        
        return .safe()
    }
    
    /// Perform safety check with conversation context for better accuracy
    func performSafetyCheckWithContext(_ message: String, history: [ChatMessage]) -> SafetyCheckResult {
        let category = classifyWithContext(message, history: history)
        
        if category.requiresIntervention {
            let response = getSafetyResponse(for: category)
            return .triggered(category: category, response: response)
        }
        
        if category.requiresCompassionateResponse {
            let response = getSafetyResponse(for: category)
            return .compassionate(category: category, response: response)
        }
        
        return .safe()
    }
    
    /// Additional content moderation for inappropriate requests
    func isInappropriateRequest(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        
        let inappropriatePatterns = [
            "write me a sermon that",
            "pretend to be god",
            "pretend to be jesus",
            "write blasphemous",
            "sexual content",
            "explicit content",
            "hate speech against",
            "discriminate against"
        ]
        
        for pattern in inappropriatePatterns {
            if lowercased.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Get a polite refusal for inappropriate requests
    func getRefusalMessage() -> String {
        """
        I'm designed to be a helpful Bible study companion, but I'm not able to help with that particular request. 
        
        I'm here to help you:
        • Study Scripture in context
        • Explore theological questions
        • Find encouragement and guidance
        • Develop your prayer life
        
        Is there something else I can help you with?
        """
    }
}


