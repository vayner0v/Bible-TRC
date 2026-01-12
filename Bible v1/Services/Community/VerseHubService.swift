//
//  VerseHubService.swift
//  Bible v1
//
//  Community Tab - Verse Hub Service
//

import Foundation
import Supabase

/// Service for Verse Hub - community reflections on specific verses
@MainActor
final class VerseHubService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Verse Index
    
    /// Get community activity for a specific verse
    func getVerseHub(
        book: String,
        chapter: Int,
        verse: Int,
        translationId: String = "KJV"
    ) async throws -> VerseHubData {
        // Get verse index entry
        let indexEntries: [VerseIndexEntry] = try await supabase
            .from("verse_index")
            .select()
            .eq("book", value: book)
            .eq("chapter", value: chapter)
            .eq("verse", value: verse)
            .eq("translation_id", value: translationId)
            .execute()
            .value
        
        let indexEntry = indexEntries.first
        
        // Get posts for this verse
        let posts = try await getPostsForVerse(
            book: book,
            chapter: chapter,
            verse: verse,
            translationId: translationId,
            limit: 20
        )
        
        // Categorize posts
        let reflections = posts.filter { $0.type == .reflection }
        let questions = posts.filter { $0.type == .question }
        let prayers = posts.filter { $0.type == .prayer }
        let testimonies = posts.filter { $0.type == .testimony }
        
        return VerseHubData(
            book: book,
            chapter: chapter,
            verse: verse,
            translationId: translationId,
            postCount: indexEntry?.postCount ?? 0,
            lastActivityAt: indexEntry?.lastActivityAt,
            reflections: reflections,
            questions: questions,
            prayers: prayers,
            testimonies: testimonies
        )
    }
    
    /// Get posts for a specific verse
    func getPostsForVerse(
        book: String,
        chapter: Int,
        verse: Int,
        translationId: String? = nil,
        type: PostType? = nil,
        offset: Int = 0,
        limit: Int = 20
    ) async throws -> [Post] {
        // Load posts with verse references and filter client-side
        // This is simpler than complex JSONB filtering for MVP
        var posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .eq("visibility", value: "public")
            .is("deleted_at", value: nil)
            .not("verse_ref", operator: .is, value: "null")
            .order("created_at", ascending: false)
            .range(from: 0, to: 200) // Load a larger batch for client-side filtering
            .execute()
            .value
        
        // Filter by verse reference client-side
        posts = posts.filter { post in
            guard let verseRef = post.verseRef else { return false }
            guard verseRef.book == book && verseRef.chapter == chapter else { return false }
            
            // Check if verse is in range
            let startVerse = verseRef.startVerse
            let endVerse = verseRef.endVerse ?? startVerse
            guard verse >= startVerse && verse <= endVerse else { return false }
            
            // Check translation if specified
            if let translationId = translationId, verseRef.translationId != translationId {
                return false
            }
            
            return true
        }
        
        // Filter by type if specified
        if let type = type {
            posts = posts.filter { $0.type == type }
        }
        
        // Apply pagination
        let endIndex = min(offset + limit, posts.count)
        guard offset < posts.count else { return [] }
        
        return Array(posts[offset..<endIndex])
    }
    
    /// Get top reflections for a verse (by engagement)
    func getTopReflections(
        book: String,
        chapter: Int,
        verse: Int,
        limit: Int = 5
    ) async throws -> [Post] {
        // Get posts for this verse
        let posts = try await getPostsForVerse(
            book: book,
            chapter: chapter,
            verse: verse,
            limit: 50
        )
        
        // Sort by engagement and return top results
        return posts
            .sorted { $0.engagement.totalReactions > $1.engagement.totalReactions }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get questions for a verse
    func getQuestionsForVerse(
        book: String,
        chapter: Int,
        verse: Int,
        offset: Int = 0,
        limit: Int = 10
    ) async throws -> [Post] {
        return try await getPostsForVerse(
            book: book,
            chapter: chapter,
            verse: verse,
            type: .question,
            offset: offset,
            limit: limit
        )
    }
    
    // MARK: - Activity Indicators
    
    /// Get verse activity for a chapter (for showing indicators in reader)
    func getChapterActivity(book: String, chapter: Int) async throws -> [Int: Int] {
        let entries: [VerseIndexEntry] = try await supabase
            .from("verse_index")
            .select("verse, post_count")
            .eq("book", value: book)
            .eq("chapter", value: chapter)
            .gt("post_count", value: 0)
            .execute()
            .value
        
        var activity: [Int: Int] = [:]
        for entry in entries {
            activity[entry.verse] = entry.postCount
        }
        
        return activity
    }
    
    /// Check if a verse has community content
    func hasContent(book: String, chapter: Int, verse: Int) async throws -> Bool {
        let entries: [VerseIndexEntry] = try await supabase
            .from("verse_index")
            .select("post_count")
            .eq("book", value: book)
            .eq("chapter", value: chapter)
            .eq("verse", value: verse)
            .execute()
            .value
        
        return (entries.first?.postCount ?? 0) > 0
    }
    
    // MARK: - Trending Verses
    
    /// Get trending verses
    func getTrendingVerses(limit: Int = 10) async throws -> [TrendingVerseData] {
        let entries: [VerseIndexEntry] = try await supabase
            .from("verse_index")
            .select()
            .gt("post_count", value: 0)
            .order("last_activity_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return entries.map { entry in
            TrendingVerseData(
                book: entry.book,
                chapter: entry.chapter,
                verse: entry.verse,
                translationId: entry.translationId,
                postCount: entry.postCount,
                lastActivityAt: entry.lastActivityAt
            )
        }
    }
    
    /// Get most discussed verses
    func getMostDiscussedVerses(limit: Int = 10) async throws -> [TrendingVerseData] {
        let entries: [VerseIndexEntry] = try await supabase
            .from("verse_index")
            .select()
            .order("post_count", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return entries.map { entry in
            TrendingVerseData(
                book: entry.book,
                chapter: entry.chapter,
                verse: entry.verse,
                translationId: entry.translationId,
                postCount: entry.postCount,
                lastActivityAt: entry.lastActivityAt
            )
        }
    }
}

// MARK: - Supporting Types

/// Verse index entry from database
struct VerseIndexEntry: Codable {
    let book: String
    let chapter: Int
    let verse: Int
    let translationId: String
    let postIds: [UUID]?
    let postCount: Int
    let lastActivityAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, verse
        case translationId = "translation_id"
        case postIds = "post_ids"
        case postCount = "post_count"
        case lastActivityAt = "last_activity_at"
    }
}

/// Data for a verse hub view
struct VerseHubData {
    let book: String
    let chapter: Int
    let verse: Int
    let translationId: String
    let postCount: Int
    let lastActivityAt: Date?
    let reflections: [Post]
    let questions: [Post]
    let prayers: [Post]
    let testimonies: [Post]
    
    var reference: String {
        "\(book) \(chapter):\(verse)"
    }
    
    var hasContent: Bool {
        postCount > 0
    }
    
    var allPosts: [Post] {
        reflections + questions + prayers + testimonies
    }
}

/// Trending verse data
struct TrendingVerseData: Identifiable {
    let book: String
    let chapter: Int
    let verse: Int
    let translationId: String
    let postCount: Int
    let lastActivityAt: Date?
    
    var id: String {
        "\(book)_\(chapter)_\(verse)_\(translationId)"
    }
    
    var reference: String {
        "\(book) \(chapter):\(verse)"
    }
}

