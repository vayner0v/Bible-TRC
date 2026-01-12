//
//  OfflineCacheService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Offline Response Cache
//  Caches common questions and responses for offline access
//

import Foundation
import Combine

/// A cached question-answer pair
struct CachedResponse: Codable, Identifiable {
    let id: UUID
    let question: String
    let questionEmbedding: [Float]?
    let response: CachedAIResponse
    let mode: String
    let dateCreated: Date
    var dateLastAccessed: Date
    var accessCount: Int
    
    /// Relevance score based on access patterns
    var relevanceScore: Double {
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: dateCreated, to: Date()).day ?? 0
        let recencyScore = max(0, 100 - Double(daysSinceCreation) * 2)
        let frequencyScore = min(50, Double(accessCount) * 5)
        return recencyScore + frequencyScore
    }
}

/// Simplified AI response for caching
struct CachedAIResponse: Codable {
    let mode: String
    let title: String
    let answerMarkdown: String
    let citations: [CachedCitation]
    let followUps: [String]
    
    init(from response: AIResponse) {
        self.mode = response.mode
        self.title = response.title
        self.answerMarkdown = response.answerMarkdown
        self.citations = response.citations.map { CachedCitation(reference: $0.reference, translationId: $0.translationId) }
        self.followUps = response.followUps
    }
    
    func toAIResponse() -> AIResponse {
        AIResponse(
            mode: mode,
            title: title,
            answerMarkdown: answerMarkdown,
            citations: citations.map { RawCitation(reference: $0.reference, translation: $0.translationId) },
            followUps: followUps,
            actions: []
        )
    }
}

/// Simplified citation for caching
struct CachedCitation: Codable {
    let reference: String
    let translationId: String
}

/// Service for caching AI responses for offline access
@MainActor
class OfflineCacheService: ObservableObject {
    static let shared = OfflineCacheService()
    
    // MARK: - Storage
    
    private let cacheKey = "trc_ai_offline_cache"
    private let maxCacheSize = 50
    private let similarityThreshold: Float = 0.85
    
    // MARK: - State
    
    @Published private(set) var cachedResponses: [CachedResponse] = []
    @Published private(set) var isLoading = false
    
    // MARK: - Dependencies
    
    private let embeddingService = EmbeddingService.shared
    
    init() {
        loadCache()
    }
    
    // MARK: - Public API
    
    /// Cache a response for future offline access
    func cacheResponse(
        question: String,
        response: AIResponse,
        mode: AIMode
    ) async {
        // Generate embedding for semantic matching
        let embedding: [Float]?
        do {
            embedding = try await embeddingService.generateEmbedding(for: question)
        } catch {
            embedding = nil
            print("OfflineCacheService: Failed to generate embedding: \(error)")
        }
        
        let cached = CachedResponse(
            id: UUID(),
            question: question,
            questionEmbedding: embedding,
            response: CachedAIResponse(from: response),
            mode: mode.rawValue,
            dateCreated: Date(),
            dateLastAccessed: Date(),
            accessCount: 1
        )
        
        // Check if similar question already cached
        if let existingIndex = await findSimilarCachedIndex(for: question, embedding: embedding) {
            // Update existing cache entry
            cachedResponses[existingIndex].dateLastAccessed = Date()
            cachedResponses[existingIndex].accessCount += 1
        } else {
            // Add new entry
            cachedResponses.insert(cached, at: 0)
            
            // Prune cache if over limit
            pruneCache()
        }
        
        saveCache()
    }
    
    /// Find a cached response for a question (for offline use)
    func findCachedResponse(for question: String) async -> AIResponse? {
        // First try exact match
        if let cached = findExactMatch(for: question) {
            updateAccessStats(for: cached.id)
            return cached.response.toAIResponse()
        }
        
        // Try semantic similarity if embeddings are available
        if let embedding = try? await embeddingService.generateEmbedding(for: question),
           let cached = findSemanticMatch(for: embedding) {
            updateAccessStats(for: cached.id)
            return cached.response.toAIResponse()
        }
        
        // Try fuzzy text matching as fallback
        if let cached = findFuzzyMatch(for: question) {
            updateAccessStats(for: cached.id)
            return cached.response.toAIResponse()
        }
        
        return nil
    }
    
    /// Check if a cached response is available (synchronous check for UI)
    func hasCachedResponse(for question: String) -> Bool {
        findExactMatch(for: question) != nil || findFuzzyMatch(for: question) != nil
    }
    
    /// Get statistics about the cache
    var cacheStats: (count: Int, maxSize: Int, oldestDate: Date?, newestDate: Date?) {
        (
            cachedResponses.count,
            maxCacheSize,
            cachedResponses.map { $0.dateCreated }.min(),
            cachedResponses.map { $0.dateCreated }.max()
        )
    }
    
    /// Clear the entire cache
    func clearCache() {
        cachedResponses.removeAll()
        saveCache()
    }
    
    /// Remove a specific cached response
    func removeCachedResponse(_ id: UUID) {
        cachedResponses.removeAll { $0.id == id }
        saveCache()
    }
    
    // MARK: - Private Matching Methods
    
    /// Find exact text match
    private func findExactMatch(for question: String) -> CachedResponse? {
        let normalizedQuestion = normalizeQuestion(question)
        return cachedResponses.first { normalizeQuestion($0.question) == normalizedQuestion }
    }
    
    /// Find semantic match using embeddings
    private func findSemanticMatch(for embedding: [Float]) -> CachedResponse? {
        var bestMatch: CachedResponse?
        var bestSimilarity: Float = 0
        
        for cached in cachedResponses {
            guard let cachedEmbedding = cached.questionEmbedding else { continue }
            
            let similarity = embeddingService.cosineSimilarity(embedding, cachedEmbedding)
            if similarity > similarityThreshold && similarity > bestSimilarity {
                bestSimilarity = similarity
                bestMatch = cached
            }
        }
        
        return bestMatch
    }
    
    /// Find fuzzy text match
    private func findFuzzyMatch(for question: String) -> CachedResponse? {
        let normalizedQuestion = normalizeQuestion(question)
        let questionWords = Set(normalizedQuestion.split(separator: " ").map { String($0) })
        
        var bestMatch: CachedResponse?
        var bestScore: Double = 0
        
        for cached in cachedResponses {
            let cachedNormalized = normalizeQuestion(cached.question)
            let cachedWords = Set(cachedNormalized.split(separator: " ").map { String($0) })
            
            // Jaccard similarity
            let intersection = questionWords.intersection(cachedWords).count
            let union = questionWords.union(cachedWords).count
            let similarity = union > 0 ? Double(intersection) / Double(union) : 0
            
            if similarity > 0.7 && similarity > bestScore {
                bestScore = similarity
                bestMatch = cached
            }
        }
        
        return bestMatch
    }
    
    /// Find similar cached item index for updates
    private func findSimilarCachedIndex(for question: String, embedding: [Float]?) async -> Int? {
        let normalizedQuestion = normalizeQuestion(question)
        
        // Check exact match first
        if let index = cachedResponses.firstIndex(where: { normalizeQuestion($0.question) == normalizedQuestion }) {
            return index
        }
        
        // Check semantic similarity if embedding available
        if let embedding = embedding {
            for (index, cached) in cachedResponses.enumerated() {
                guard let cachedEmbedding = cached.questionEmbedding else { continue }
                let similarity = embeddingService.cosineSimilarity(embedding, cachedEmbedding)
                if similarity > 0.95 { // High threshold for considering it the "same" question
                    return index
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Helpers
    
    /// Normalize question for comparison
    private func normalizeQuestion(_ question: String) -> String {
        question.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
    
    /// Update access statistics
    private func updateAccessStats(for id: UUID) {
        if let index = cachedResponses.firstIndex(where: { $0.id == id }) {
            cachedResponses[index].dateLastAccessed = Date()
            cachedResponses[index].accessCount += 1
            saveCache()
        }
    }
    
    /// Prune cache to stay under size limit
    private func pruneCache() {
        guard cachedResponses.count > maxCacheSize else { return }
        
        // Sort by relevance score and keep top entries
        cachedResponses.sort { $0.relevanceScore > $1.relevanceScore }
        cachedResponses = Array(cachedResponses.prefix(maxCacheSize))
    }
    
    // MARK: - Persistence
    
    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            cachedResponses = []
            return
        }
        
        do {
            cachedResponses = try JSONDecoder().decode([CachedResponse].self, from: data)
        } catch {
            print("OfflineCacheService: Failed to load cache: \(error)")
            cachedResponses = []
        }
    }
    
    private func saveCache() {
        do {
            let data = try JSONEncoder().encode(cachedResponses)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            print("OfflineCacheService: Failed to save cache: \(error)")
        }
    }
}

