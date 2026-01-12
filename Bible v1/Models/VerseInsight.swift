//
//  VerseInsight.swift
//  Bible v1
//
//  Model for saved AI-powered verse insights
//

import Foundation
import SwiftUI

// MARK: - Analysis Type

/// Types of AI analysis available for verses
enum InsightAnalysisType: String, CaseIterable, Codable, Identifiable {
    case contextMeaning = "context_meaning"
    case crossReferences = "cross_references"
    case comprehensiveStudy = "comprehensive_study"
    case devotional = "devotional"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .contextMeaning: return "Context & Meaning"
        case .crossReferences: return "Cross References"
        case .comprehensiveStudy: return "Deep Study"
        case .devotional: return "Devotional"
        }
    }
    
    var shortName: String {
        switch self {
        case .contextMeaning: return "Context"
        case .crossReferences: return "Cross-Refs"
        case .comprehensiveStudy: return "Deep Study"
        case .devotional: return "Devotional"
        }
    }
    
    var icon: String {
        switch self {
        case .contextMeaning: return "text.book.closed"
        case .crossReferences: return "link"
        case .comprehensiveStudy: return "book.fill"
        case .devotional: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .contextMeaning: return .blue
        case .crossReferences: return .purple
        case .comprehensiveStudy: return .orange
        case .devotional: return .pink
        }
    }
    
    var description: String {
        switch self {
        case .contextMeaning: return "Historical context and verse meaning"
        case .crossReferences: return "Related verses and connections"
        case .comprehensiveStudy: return "In-depth theological analysis"
        case .devotional: return "Personal reflection and application"
        }
    }
    
    /// System prompt addition for each analysis type
    var systemPromptAddition: String {
        switch self {
        case .contextMeaning:
            return """
            Focus on:
            1. Historical and cultural context of when this was written
            2. The original audience and their situation
            3. Key words and their meanings in the original language
            4. How this verse fits within its chapter and book
            5. The main theological point being communicated
            
            Keep your response focused and insightful, around 200-300 words.
            """
            
        case .crossReferences:
            return """
            Focus on:
            1. Direct cross-references to other verses that quote or reference this passage
            2. Thematic connections to related passages throughout Scripture
            3. How Old Testament references connect to New Testament fulfillment (if applicable)
            4. Key theological themes that appear in multiple places
            5. Provide at least 4-6 relevant cross-references with brief explanations
            
            Format cross-references clearly with the verse reference and a brief explanation of the connection.
            """
            
        case .comprehensiveStudy:
            return """
            Provide a comprehensive study covering:
            1. **Historical Context** - When was this written and to whom?
            2. **Literary Context** - How does this fit in the surrounding passage?
            3. **Word Study** - Key Greek/Hebrew words and their significance
            4. **Theological Themes** - Major doctrines or themes present
            5. **Cross-References** - 3-4 related passages
            6. **Practical Application** - How does this apply to life today?
            
            Be thorough but organized. Use clear section headers.
            """
            
        case .devotional:
            return """
            Provide a warm, personal devotional reflection:
            1. What is God saying through this verse?
            2. How might this encourage someone today?
            3. A brief prayer inspired by this passage
            4. One practical way to apply this truth
            
            Write in a warm, pastoral tone. Be encouraging and personal.
            Keep it around 150-200 words - enough to inspire without overwhelming.
            """
        }
    }
}

// MARK: - Verse Insight Model

/// A saved AI-generated insight for a verse
struct VerseInsight: Identifiable, Codable, Equatable {
    let id: UUID
    let reference: String
    let verseText: String
    let translationId: String
    let analysisType: InsightAnalysisType
    let content: String
    let citations: [String]
    let createdAt: Date
    
    // Optional metadata
    var bookId: String?
    var bookName: String?
    var chapter: Int?
    var verse: Int?
    
    init(
        id: UUID = UUID(),
        reference: String,
        verseText: String,
        translationId: String,
        analysisType: InsightAnalysisType,
        content: String,
        citations: [String] = [],
        createdAt: Date = Date(),
        bookId: String? = nil,
        bookName: String? = nil,
        chapter: Int? = nil,
        verse: Int? = nil
    ) {
        self.id = id
        self.reference = reference
        self.verseText = verseText
        self.translationId = translationId
        self.analysisType = analysisType
        self.content = content
        self.citations = citations
        self.createdAt = createdAt
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
    }
    
    /// Create from a VerseReference
    static func from(
        reference: VerseReference,
        analysisType: InsightAnalysisType,
        content: String,
        citations: [String] = []
    ) -> VerseInsight {
        VerseInsight(
            reference: reference.fullReference,
            verseText: reference.text,
            translationId: reference.translationId,
            analysisType: analysisType,
            content: content,
            citations: citations,
            bookId: reference.bookId,
            bookName: reference.bookName,
            chapter: reference.chapter,
            verse: reference.verse
        )
    }
}

// MARK: - Insight State

/// State for the insight overlay in the reader
enum InsightState: Equatable {
    case idle
    case thinking(InsightAnalysisType)
    case streaming(InsightAnalysisType, String)
    case complete(VerseInsight)
    case error(String)
    
    var isActive: Bool {
        switch self {
        case .idle: return false
        default: return true
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .thinking, .streaming: return true
        default: return false
        }
    }
    
    var analysisType: InsightAnalysisType? {
        switch self {
        case .thinking(let type), .streaming(let type, _): return type
        case .complete(let insight): return insight.analysisType
        default: return nil
        }
    }
}



