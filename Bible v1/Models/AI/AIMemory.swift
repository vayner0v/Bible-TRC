//
//  AIMemory.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Memory Model
//

import Foundation
import SwiftUI

/// Types of memories that can be stored
enum MemoryType: String, Codable, CaseIterable, Identifiable {
    case prayerRequest = "prayerRequest"
    case favoriteVerse = "favoriteVerse"
    case recurringStruggle = "recurringStruggle"
    case helpfulInsight = "helpfulInsight"
    case personalContext = "personalContext"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .prayerRequest: return "Prayer Request"
        case .favoriteVerse: return "Favorite Verse"
        case .recurringStruggle: return "Recurring Struggle"
        case .helpfulInsight: return "Helpful Insight"
        case .personalContext: return "Personal Context"
        }
    }
    
    var icon: String {
        switch self {
        case .prayerRequest: return "hands.sparkles"
        case .favoriteVerse: return "heart.fill"
        case .recurringStruggle: return "arrow.triangle.2.circlepath"
        case .helpfulInsight: return "lightbulb.fill"
        case .personalContext: return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .prayerRequest: return .purple
        case .favoriteVerse: return .red
        case .recurringStruggle: return .orange
        case .helpfulInsight: return .yellow
        case .personalContext: return .blue
        }
    }
    
    var description: String {
        switch self {
        case .prayerRequest:
            return "Prayer intentions and requests you've shared"
        case .favoriteVerse:
            return "Verses that resonate with you"
        case .recurringStruggle:
            return "Challenges you're working through"
        case .helpfulInsight:
            return "Responses that were particularly helpful"
        case .personalContext:
            return "Personal details you've shared"
        }
    }
}

/// Represents a single memory item
struct AIMemory: Identifiable, Codable, Hashable {
    let id: UUID
    let type: MemoryType
    var content: String
    let sourceMessageId: UUID?
    let sourceConversationId: UUID?
    let dateCreated: Date
    var dateModified: Date
    var isActive: Bool
    var relatedVerses: [String]  // e.g., ["John 3:16", "Romans 8:28"]
    var tags: [String]
    
    // MARK: - Embedding & Importance Scoring
    
    /// Vector embedding for semantic search (generated via EmbeddingService)
    var embedding: [Float]?
    
    /// Number of times this memory has been accessed/referenced
    var accessCount: Int
    
    /// Last time this memory was accessed in context
    var lastAccessedDate: Date?
    
    init(
        id: UUID = UUID(),
        type: MemoryType,
        content: String,
        sourceMessageId: UUID? = nil,
        sourceConversationId: UUID? = nil,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        isActive: Bool = true,
        relatedVerses: [String] = [],
        tags: [String] = [],
        embedding: [Float]? = nil,
        accessCount: Int = 0,
        lastAccessedDate: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.sourceMessageId = sourceMessageId
        self.sourceConversationId = sourceConversationId
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isActive = isActive
        self.relatedVerses = relatedVerses
        self.tags = tags
        self.embedding = embedding
        self.accessCount = accessCount
        self.lastAccessedDate = lastAccessedDate
    }
    
    // MARK: - Importance Scoring
    
    /// Calculate importance score based on recency, frequency, and type
    var importanceScore: Double {
        var score: Double = 0.0
        
        // Recency factor (0-40 points) - more recent = higher score
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: dateCreated, to: Date()).day ?? 0
        let recencyScore = max(0, 40 - Double(daysSinceCreation) * 0.5)
        score += recencyScore
        
        // Access frequency factor (0-30 points)
        let frequencyScore = min(30, Double(accessCount) * 3)
        score += frequencyScore
        
        // Last accessed recency (0-20 points)
        if let lastAccessed = lastAccessedDate {
            let daysSinceAccess = Calendar.current.dateComponents([.day], from: lastAccessed, to: Date()).day ?? 0
            let accessRecencyScore = max(0, 20 - Double(daysSinceAccess) * 2)
            score += accessRecencyScore
        }
        
        // Type weight (0-10 points)
        let typeWeight: Double
        switch type {
        case .prayerRequest:
            typeWeight = 10.0 // Prayer requests are high priority
        case .recurringStruggle:
            typeWeight = 8.0
        case .personalContext:
            typeWeight = 7.0
        case .favoriteVerse:
            typeWeight = 5.0
        case .helpfulInsight:
            typeWeight = 4.0
        }
        score += typeWeight
        
        return score
    }
    
    /// Check if this memory has an embedding
    var hasEmbedding: Bool {
        embedding != nil && !(embedding?.isEmpty ?? true)
    }
    
    // MARK: - Formatted Properties
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateCreated)
    }
    
    var previewContent: String {
        if content.count > 100 {
            return String(content.prefix(100)) + "..."
        }
        return content
    }
    
    var ageDescription: String {
        let components = Calendar.current.dateComponents(
            [.day, .month, .year],
            from: dateCreated,
            to: Date()
        )
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else if let days = components.day, days > 0 {
            if days == 1 { return "Yesterday" }
            if days < 7 { return "\(days) days ago" }
            return "\(days / 7) weeks ago"
        }
        return "Today"
    }
    
    // MARK: - Update Methods
    
    func deactivated() -> AIMemory {
        var copy = self
        copy.isActive = false
        copy.dateModified = Date()
        return copy
    }
    
    func reactivated() -> AIMemory {
        var copy = self
        copy.isActive = true
        copy.dateModified = Date()
        return copy
    }
    
    func withUpdatedContent(_ newContent: String) -> AIMemory {
        var copy = self
        copy.content = newContent
        copy.dateModified = Date()
        return copy
    }
    
    func withEmbedding(_ embedding: [Float]) -> AIMemory {
        var copy = self
        copy.embedding = embedding
        return copy
    }
    
    func accessed() -> AIMemory {
        var copy = self
        copy.accessCount += 1
        copy.lastAccessedDate = Date()
        return copy
    }
}

// MARK: - Memory Prompt Context

/// Context from memories to include in AI prompts
struct MemoryContext {
    let prayerRequests: [AIMemory]
    let favoriteVerses: [AIMemory]
    let struggles: [AIMemory]
    let insights: [AIMemory]
    let personalContext: [AIMemory]
    
    var isEmpty: Bool {
        prayerRequests.isEmpty &&
        favoriteVerses.isEmpty &&
        struggles.isEmpty &&
        insights.isEmpty &&
        personalContext.isEmpty
    }
    
    /// Format memories for system prompt inclusion
    func formatForPrompt() -> String {
        guard !isEmpty else { return "" }
        
        var parts: [String] = []
        
        if !prayerRequests.isEmpty {
            let requests = prayerRequests.prefix(3).map { "• \($0.content)" }.joined(separator: "\n")
            parts.append("ONGOING PRAYER REQUESTS:\n\(requests)")
        }
        
        if !favoriteVerses.isEmpty {
            let verses = favoriteVerses.prefix(5).compactMap { $0.relatedVerses.first }.joined(separator: ", ")
            parts.append("MEANINGFUL VERSES: \(verses)")
        }
        
        if !struggles.isEmpty {
            let struggles = struggles.prefix(2).map { "• \($0.content)" }.joined(separator: "\n")
            parts.append("ONGOING CHALLENGES:\n\(struggles)")
        }
        
        if !insights.isEmpty {
            let insights = insights.prefix(2).map { "• \($0.content)" }.joined(separator: "\n")
            parts.append("PREVIOUS HELPFUL INSIGHTS:\n\(insights)")
        }
        
        if !personalContext.isEmpty {
            let context = personalContext.prefix(3).map { "• \($0.content)" }.joined(separator: "\n")
            parts.append("USER CONTEXT:\n\(context)")
        }
        
        return """
        
        REMEMBERED ABOUT THIS USER:
        \(parts.joined(separator: "\n\n"))
        
        Use this knowledge to provide more personalized and relevant responses.
        
        """
    }
}

// MARK: - Memory Summary

/// Summary statistics for memory management UI
struct MemorySummary {
    let totalCount: Int
    let activeCount: Int
    let prayerRequestCount: Int
    let favoriteVerseCount: Int
    let insightCount: Int
    let oldestDate: Date?
    let newestDate: Date?
    
    init(memories: [AIMemory]) {
        totalCount = memories.count
        activeCount = memories.filter { $0.isActive }.count
        prayerRequestCount = memories.filter { $0.type == .prayerRequest }.count
        favoriteVerseCount = memories.filter { $0.type == .favoriteVerse }.count
        insightCount = memories.filter { $0.type == .helpfulInsight }.count
        oldestDate = memories.map { $0.dateCreated }.min()
        newestDate = memories.map { $0.dateCreated }.max()
    }
}

