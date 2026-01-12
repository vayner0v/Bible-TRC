//
//  VerseRepository.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Enhanced Verse Repository
//

import Foundation
import Combine

/// Repository for fetching and caching Bible verses for AI grounding
@MainActor
class VerseRepository: ObservableObject {
    static let shared = VerseRepository()
    
    // MARK: - Dependencies
    
    private let apiService = BibleAPIService.shared
    private let cacheService = CacheService.shared
    private let referenceParser = ReferenceParser.shared
    
    // MARK: - Enhanced Cache
    
    /// In-memory cache for quick verse lookups (keyed by "translationId_bookId_chapter_verse")
    private var verseCache: [String: CachedVerse] = [:]
    
    /// Cache expiry duration (24 hours)
    private let cacheExpiry: TimeInterval = 86400
    
    // MARK: - Public API
    
    /// Get a single verse by reference string
    func getVerse(reference: String, translationId: String) async -> ResolvedVerse? {
        guard let parsed = referenceParser.parse(reference) else {
            return nil
        }
        
        return await getVerse(parsed: parsed, translationId: translationId)
    }
    
    /// Get a verse from parsed reference
    func getVerse(parsed: EnhancedParsedReference, translationId: String) async -> ResolvedVerse? {
        let verseNum = parsed.verseStart ?? 1
        let cacheKey = "\(translationId)_\(parsed.osisBookId)_\(parsed.chapter)_\(verseNum)"
        
        // Check cache first
        if let cached = verseCache[cacheKey], !cached.isExpired {
            return cached.verse
        }
        
        // Fetch from API
        do {
            let chapter = try await fetchChapter(
                translationId: translationId,
                bookId: parsed.osisBookId,
                chapterNum: parsed.chapter
            )
            
            // Cache all verses from this chapter
            cacheChapterVerses(chapter: chapter, translationId: translationId, bookId: parsed.osisBookId)
            
            // Find the specific verse
            if let verse = chapter.verses.first(where: { $0.verse == verseNum }) {
                return ResolvedVerse(
                    translationId: translationId,
                    bookId: parsed.osisBookId,
                    bookName: parsed.bookDisplayName,
                    chapter: parsed.chapter,
                    verse: verse.verse,
                    text: verse.text
                )
            }
        } catch {
            print("Failed to fetch verse: \(error)")
        }
        
        return nil
    }
    
    /// Get a passage (range of verses)
    func getPassage(
        bookId: String,
        chapter: Int,
        verseStart: Int,
        verseEnd: Int,
        translationId: String
    ) async -> [ResolvedVerse] {
        var results: [ResolvedVerse] = []
        
        do {
            let chapterData = try await fetchChapter(
                translationId: translationId,
                bookId: bookId,
                chapterNum: chapter
            )
            
            // Cache all verses
            cacheChapterVerses(chapter: chapterData, translationId: translationId, bookId: bookId)
            
            // Get book name
            let bookName = referenceParser.getDisplayName(for: bookId) ?? bookId
            
            // Extract requested verses
            for verse in chapterData.verses where verse.verse >= verseStart && verse.verse <= verseEnd {
                results.append(ResolvedVerse(
                    translationId: translationId,
                    bookId: bookId,
                    bookName: bookName,
                    chapter: chapter,
                    verse: verse.verse,
                    text: verse.text
                ))
            }
        } catch {
            print("Failed to fetch passage: \(error)")
        }
        
        return results
    }
    
    /// Resolve an AICitation by fetching its verse text and verifying it
    func resolveCitation(_ citation: AICitation, translationId: String) async -> AICitation {
        // If already resolved and verified, return as-is
        if citation.isResolved && citation.verificationStatus == .verified { 
            return citation 
        }
        
        // Try to parse and fetch
        guard let parsed = referenceParser.parse(citation.reference) else {
            // Could not parse reference - mark as failed
            return citation.withVerificationStatus(.failed)
        }
        
        if let start = parsed.verseStart {
            let end = parsed.verseEnd ?? start
            let verses = await getPassage(
                bookId: parsed.osisBookId,
                chapter: parsed.chapter,
                verseStart: start,
                verseEnd: end,
                translationId: translationId
            )
            
            // Combine verse texts
            let combinedText = verses.map { $0.text }.joined(separator: " ")
            
            // Determine verification status based on whether we got text
            let status: VerificationStatus = combinedText.isEmpty ? .paraphrased : .verified
            
            return AICitation(
                id: citation.id,
                reference: parsed.canonicalReference,
                translationId: translationId,
                bookId: parsed.osisBookId,
                bookName: parsed.bookDisplayName,
                chapter: parsed.chapter,
                verseStart: start,
                verseEnd: parsed.verseEnd,
                text: combinedText.isEmpty ? nil : combinedText,
                verificationStatus: status
            )
        }
        
        // No verse specified - mark as paraphrased (chapter-only reference)
        return citation.withVerificationStatus(.paraphrased)
    }
    
    /// Resolve multiple citations in batch with verification
    func resolveCitations(_ citations: [AICitation], translationId: String) async -> [AICitation] {
        var resolved: [AICitation] = []
        
        // Group by chapter to minimize API calls
        var chapterGroups: [String: [AICitation]] = [:]
        for citation in citations {
            if let parsed = referenceParser.parse(citation.reference) {
                let key = "\(translationId)_\(parsed.osisBookId)_\(parsed.chapter)"
                if chapterGroups[key] == nil {
                    chapterGroups[key] = []
                }
                chapterGroups[key]?.append(citation)
            } else {
                // Keep unresolvable citations but mark as failed
                resolved.append(citation.withVerificationStatus(.failed))
            }
        }
        
        // Fetch each chapter once and resolve all citations from it
        for (_, groupCitations) in chapterGroups {
            for citation in groupCitations {
                let resolvedCitation = await resolveCitation(citation, translationId: translationId)
                resolved.append(resolvedCitation)
            }
        }
        
        return resolved
    }
    
    /// Search verses by keyword (searches cached verses)
    func search(keyword: String, translationId: String, limit: Int = 10) async -> [ResolvedVerse] {
        let lowercasedKeyword = keyword.lowercased()
        var results: [ResolvedVerse] = []
        
        // Search through cached verses first
        for (_, cached) in verseCache {
            if cached.verse.text.lowercased().contains(lowercasedKeyword) {
                results.append(cached.verse)
                if results.count >= limit { break }
            }
        }
        
        return results
    }
    
    /// Build grounding context from references found in text
    func buildGroundingContext(
        from text: String,
        translationId: String,
        maxVerses: Int = 5
    ) async -> GroundingContext {
        var context = GroundingContext()
        
        // Extract references from text
        let parsedRefs = referenceParser.parseAll(from: text)
        
        // Resolve each reference
        for parsed in parsedRefs.prefix(maxVerses) {
            let citation = parsed.toCitation(translationId: translationId)
            let resolved = await resolveCitation(citation, translationId: translationId)
            
            if resolved.isResolved {
                context.citations.append(resolved)
            }
        }
        
        return context
    }
    
    // MARK: - Private Helpers
    
    private func fetchChapter(translationId: String, bookId: String, chapterNum: Int) async throws -> Chapter {
        // Check CacheService first
        if let cached = cacheService.getCachedChapter(
            translationId: translationId,
            bookId: bookId,
            chapter: chapterNum
        ) {
            return cached
        }
        
        // Fetch from API
        let chapter = try await apiService.fetchChapter(
            translationId: translationId,
            bookId: bookId,
            chapter: chapterNum
        )
        
        // Cache in CacheService
        cacheService.cacheChapter(chapter, translationId: translationId, bookId: bookId, chapterNum: chapterNum)
        
        return chapter
    }
    
    private func cacheChapterVerses(chapter: Chapter, translationId: String, bookId: String) {
        let bookName = referenceParser.getDisplayName(for: bookId) ?? chapter.book.displayName
        
        for verse in chapter.verses {
            let cacheKey = "\(translationId)_\(bookId)_\(chapter.chapter)_\(verse.verse)"
            let resolved = ResolvedVerse(
                translationId: translationId,
                bookId: bookId,
                bookName: bookName,
                chapter: chapter.chapter,
                verse: verse.verse,
                text: verse.text
            )
            verseCache[cacheKey] = CachedVerse(verse: resolved, timestamp: Date())
        }
    }
    
    /// Clear expired cache entries
    func cleanupCache() {
        let now = Date()
        verseCache = verseCache.filter { !$0.value.isExpired(at: now) }
    }
}

// MARK: - Supporting Types

/// A fully resolved verse with all metadata
struct ResolvedVerse: Identifiable, Hashable {
    let id = UUID()
    let translationId: String
    let bookId: String
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String
    
    var reference: String {
        "\(bookName) \(chapter):\(verse)"
    }
    
    var fullReference: String {
        "\(reference) (\(translationId.uppercased()))"
    }
    
    /// Convert to AICitation
    func toCitation() -> AICitation {
        AICitation(
            reference: reference,
            translationId: translationId,
            bookId: bookId,
            bookName: bookName,
            chapter: chapter,
            verseStart: verse,
            verseEnd: nil,
            text: text
        )
    }
    
    /// Convert to VerseReference
    func toVerseReference() -> VerseReference {
        VerseReference(
            translationId: translationId,
            bookId: bookId,
            bookName: bookName,
            chapter: chapter,
            verse: verse,
            text: text
        )
    }
}

/// Cached verse with timestamp
private struct CachedVerse {
    let verse: ResolvedVerse
    let timestamp: Date
    
    var isExpired: Bool {
        isExpired(at: Date())
    }
    
    func isExpired(at date: Date) -> Bool {
        date.timeIntervalSince(timestamp) > 86400 // 24 hours
    }
}

/// Context for grounding AI responses
struct GroundingContext {
    var citations: [AICitation] = []
    var searchResults: [ResolvedVerse] = []
    
    var isEmpty: Bool {
        citations.isEmpty && searchResults.isEmpty
    }
    
    /// Format for inclusion in prompt
    func formatForPrompt() -> String {
        var parts: [String] = []
        
        if !citations.isEmpty {
            parts.append("Referenced verses:")
            for citation in citations {
                if let text = citation.text {
                    parts.append("- \(citation.reference): \"\(text)\"")
                }
            }
        }
        
        if !searchResults.isEmpty {
            parts.append("Related verses:")
            for verse in searchResults {
                parts.append("- \(verse.reference): \"\(verse.text)\"")
            }
        }
        
        return parts.joined(separator: "\n")
    }
}

