//
//  MemoryExtractor.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Automatic Memory Extraction
//  Analyzes conversations to extract meaningful memories automatically
//

import Foundation

/// Service for automatically extracting memories from AI conversations
@MainActor
class MemoryExtractor {
    static let shared = MemoryExtractor()
    
    // MARK: - Dependencies
    
    private let memoryService = AIMemoryService.shared
    private let embeddingService = EmbeddingService.shared
    
    // MARK: - Extraction Patterns
    
    /// Patterns for detecting prayer requests
    private let prayerPatterns: [String] = [
        "pray for", "please pray", "need prayer", "prayers for",
        "praying for", "prayer request", "in prayer",
        "struggling with", "going through", "dealing with",
        "asking god", "asking the lord", "lift up"
    ]
    
    /// Patterns for detecting personal context
    private let personalContextPatterns: [String: String] = [
        "my wife": "family_spouse",
        "my husband": "family_spouse",
        "my spouse": "family_spouse",
        "my child": "family_child",
        "my children": "family_child",
        "my son": "family_child",
        "my daughter": "family_child",
        "my mom": "family_parent",
        "my mother": "family_parent",
        "my dad": "family_parent",
        "my father": "family_parent",
        "my church": "church",
        "my pastor": "church",
        "my job": "work",
        "my work": "work",
        "my career": "work",
        "i work as": "occupation",
        "i'm a": "occupation",
        "i am a": "occupation"
    ]
    
    /// Patterns for detecting recurring struggles
    private let strugglePatterns: [String] = [
        "i've been struggling", "i struggle with", "i always have trouble",
        "it's hard for me", "i can't seem to", "i keep",
        "my weakness is", "i find it difficult", "i battle with",
        "ongoing issue", "constant challenge", "recurring problem"
    ]
    
    /// Patterns for detecting when a response was helpful
    private let insightPatterns: [String] = [
        "that's helpful", "thank you", "this helps", "that makes sense",
        "i never thought of it that way", "great insight", "really appreciate",
        "wow", "that's exactly", "this is what i needed"
    ]
    
    // MARK: - Public API
    
    /// Extract memories from a user message and optionally the AI response
    func extractMemories(
        from userMessage: String,
        aiResponse: String? = nil,
        messageId: UUID,
        conversationId: UUID
    ) async -> [AIMemory] {
        var extractedMemories: [AIMemory] = []
        
        let userMessageLower = userMessage.lowercased()
        
        // 1. Check for prayer requests
        if let prayerRequest = detectPrayerRequest(userMessageLower, originalText: userMessage) {
            let memory = AIMemory(
                type: .prayerRequest,
                content: prayerRequest,
                sourceMessageId: messageId,
                sourceConversationId: conversationId
            )
            extractedMemories.append(memory)
        }
        
        // 2. Check for personal context
        let personalContextItems = detectPersonalContext(userMessageLower, originalText: userMessage)
        for (type, content) in personalContextItems {
            let memory = AIMemory(
                type: type,
                content: content,
                sourceMessageId: messageId,
                sourceConversationId: conversationId,
                tags: []
            )
            extractedMemories.append(memory)
        }
        
        // 3. Check for recurring struggles
        if let struggle = detectStruggle(userMessageLower, originalText: userMessage) {
            let memory = AIMemory(
                type: .recurringStruggle,
                content: struggle,
                sourceMessageId: messageId,
                sourceConversationId: conversationId
            )
            extractedMemories.append(memory)
        }
        
        // 4. Extract favorite verses mentioned
        let verses = extractVerseReferences(from: userMessage)
        for verse in verses {
            // Check if this verse is already a favorite to avoid duplicates
            let existingFavorites = memoryService.memories(ofType: .favoriteVerse)
            if !existingFavorites.contains(where: { $0.relatedVerses.contains(verse) }) {
                let memory = AIMemory(
                    type: .favoriteVerse,
                    content: "User mentioned this verse",
                    sourceMessageId: messageId,
                    sourceConversationId: conversationId,
                    relatedVerses: [verse]
                )
                extractedMemories.append(memory)
            }
        }
        
        // 5. Check if user indicated the response was helpful
        if let response = aiResponse,
           let insight = detectHelpfulInsight(userMessageLower, responseContent: response) {
            let memory = AIMemory(
                type: .helpfulInsight,
                content: insight,
                sourceMessageId: messageId,
                sourceConversationId: conversationId
            )
            extractedMemories.append(memory)
        }
        
        // Generate embeddings for new memories
        for i in 0..<extractedMemories.count {
            do {
                let embedding = try await embeddingService.generateEmbedding(for: extractedMemories[i].content)
                extractedMemories[i] = extractedMemories[i].withEmbedding(embedding)
            } catch {
                print("MemoryExtractor: Failed to generate embedding: \(error)")
            }
        }
        
        return extractedMemories
    }
    
    /// Process a completed conversation turn and save any extracted memories
    func processConversationTurn(
        userMessage: String,
        aiResponse: String,
        messageId: UUID,
        conversationId: UUID,
        autoSave: Bool = true
    ) async {
        let memories = await extractMemories(
            from: userMessage,
            aiResponse: aiResponse,
            messageId: messageId,
            conversationId: conversationId
        )
        
        if autoSave {
            for memory in memories {
                // Check for duplicates before adding
                if !isDuplicate(memory) {
                    memoryService.addMemory(memory)
                }
            }
            
            if !memories.isEmpty {
                print("MemoryExtractor: Auto-saved \(memories.count) memories from conversation")
            }
        }
    }
    
    // MARK: - Detection Methods
    
    /// Detect prayer requests in text
    func detectPrayerRequest(_ lowercasedText: String, originalText: String) -> String? {
        for pattern in prayerPatterns {
            if lowercasedText.contains(pattern) {
                // Extract a meaningful phrase around the pattern
                return extractContext(around: pattern, in: originalText, maxLength: 150)
            }
        }
        return nil
    }
    
    /// Detect personal context (family, church, work, etc.)
    func detectPersonalContext(_ lowercasedText: String, originalText: String) -> [(type: MemoryType, content: String)] {
        var results: [(type: MemoryType, content: String)] = []
        
        for (pattern, _) in personalContextPatterns {
            if lowercasedText.contains(pattern) {
                let context = extractContext(around: pattern, in: originalText, maxLength: 100)
                results.append((.personalContext, context))
            }
        }
        
        return results
    }
    
    /// Detect recurring struggles
    func detectStruggle(_ lowercasedText: String, originalText: String) -> String? {
        for pattern in strugglePatterns {
            if lowercasedText.contains(pattern) {
                return extractContext(around: pattern, in: originalText, maxLength: 150)
            }
        }
        return nil
    }
    
    /// Detect when user found a response helpful
    func detectHelpfulInsight(_ lowercasedUserMessage: String, responseContent: String) -> String? {
        for pattern in insightPatterns {
            if lowercasedUserMessage.contains(pattern) {
                // Return a summary of what was helpful
                let responseSummary = responseContent.prefix(200)
                return "User found helpful: \(responseSummary)..."
            }
        }
        return nil
    }
    
    /// Extract verse references from text
    func extractVerseReferences(from text: String) -> [String] {
        var verses: [String] = []
        
        let pattern = #"([1-3]?\s?[A-Za-z]+(?:\s+[A-Za-z]+)?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return verses
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            if let matchRange = Range(match.range, in: text) {
                let verse = String(text[matchRange]).trimmingCharacters(in: .whitespaces)
                // Validate it looks like a real verse reference
                if ReferenceParser.shared.parse(verse) != nil {
                    verses.append(verse)
                }
            }
        }
        
        return verses
    }
    
    // MARK: - Helpers
    
    /// Extract context around a pattern match
    private func extractContext(around pattern: String, in text: String, maxLength: Int) -> String {
        guard let range = text.lowercased().range(of: pattern) else {
            return text.prefix(maxLength).description
        }
        
        let lowercased = text.lowercased()
        let patternStart = lowercased.distance(from: lowercased.startIndex, to: range.lowerBound)
        
        // Find sentence boundaries
        let startIndex = max(0, patternStart - 30)
        let endIndex = min(text.count, patternStart + pattern.count + 100)
        
        let start = text.index(text.startIndex, offsetBy: startIndex)
        let end = text.index(text.startIndex, offsetBy: endIndex)
        
        var extracted = String(text[start..<end])
        
        // Clean up: try to start at sentence beginning
        if let periodIndex = extracted.firstIndex(of: "."), periodIndex != extracted.startIndex {
            extracted = String(extracted[extracted.index(after: periodIndex)...]).trimmingCharacters(in: .whitespaces)
        }
        
        // Truncate if too long
        if extracted.count > maxLength {
            extracted = String(extracted.prefix(maxLength)) + "..."
        }
        
        return extracted
    }
    
    /// Check if a memory is a duplicate of an existing one
    private func isDuplicate(_ memory: AIMemory) -> Bool {
        let existingMemories = memoryService.activeMemories
        
        // Check for exact content match
        if existingMemories.contains(where: { $0.content == memory.content }) {
            return true
        }
        
        // For favorite verses, check if the verse is already saved
        if memory.type == .favoriteVerse {
            let existingVerses = existingMemories
                .filter { $0.type == .favoriteVerse }
                .flatMap { $0.relatedVerses }
            
            for verse in memory.relatedVerses {
                if existingVerses.contains(verse) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Get extraction statistics
    var extractionStats: (patternsCount: Int, typesCount: Int) {
        let totalPatterns = prayerPatterns.count + personalContextPatterns.count + 
                           strugglePatterns.count + insightPatterns.count
        return (totalPatterns, MemoryType.allCases.count)
    }
}

// MARK: - Memory Extraction Result

/// Result of memory extraction for UI display
struct MemoryExtractionResult {
    let memories: [AIMemory]
    let suggestions: [MemorySuggestion]
    
    var isEmpty: Bool {
        memories.isEmpty && suggestions.isEmpty
    }
}

/// A suggestion for a memory that could be saved
struct MemorySuggestion: Identifiable {
    let id = UUID()
    let type: MemoryType
    let content: String
    let confidence: Double // 0-1
    
    var confidenceLevel: String {
        if confidence > 0.8 { return "High" }
        if confidence > 0.5 { return "Medium" }
        return "Low"
    }
}



