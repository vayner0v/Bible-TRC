//
//  EmbeddingService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - OpenAI Embeddings API Integration
//  Enables semantic memory search using vector embeddings
//

import Foundation
import Combine

/// Service for generating and comparing text embeddings using OpenAI's API
@MainActor
class EmbeddingService: ObservableObject {
    static let shared = EmbeddingService()
    
    // MARK: - Configuration
    
    private let baseURL = "https://api.openai.com/v1/embeddings"
    private let model = "text-embedding-3-small"
    private let dimensions = 512 // Reduced dimensions for efficiency
    
    // MARK: - API Key
    
    private var apiKey: String {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path),
           let key = secrets["OPENAI_API_KEY"] as? String {
            return key
        }
        return ""
    }
    
    // MARK: - State
    
    @Published var isGenerating = false
    @Published var lastError: EmbeddingError?
    
    private let session: URLSession
    
    // MARK: - Embedding Cache
    
    private var embeddingCache: [String: [Float]] = [:]
    private let maxCacheSize = 500
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Generate an embedding for the given text
    func generateEmbedding(for text: String) async throws -> [Float] {
        // Check cache first
        let cacheKey = text.prefix(200).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = embeddingCache[cacheKey] {
            return cached
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        guard let url = URL(string: baseURL) else {
            throw EmbeddingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "input": text,
            "dimensions": dimensions
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmbeddingError.invalidResponse
        }
        
        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw EmbeddingError.apiError(message)
            }
            throw EmbeddingError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse the embedding from the response
        let embedding = try parseEmbeddingResponse(data)
        
        // Cache the result
        cacheEmbedding(embedding, for: cacheKey)
        
        return embedding
    }
    
    /// Generate embeddings for multiple texts in a batch
    func generateEmbeddings(for texts: [String]) async throws -> [[Float]] {
        // Filter out texts that are already cached
        var results: [[Float]] = Array(repeating: [], count: texts.count)
        var uncachedTexts: [(index: Int, text: String)] = []
        
        for (index, text) in texts.enumerated() {
            let cacheKey = text.prefix(200).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if let cached = embeddingCache[cacheKey] {
                results[index] = cached
            } else {
                uncachedTexts.append((index, text))
            }
        }
        
        // If all cached, return immediately
        if uncachedTexts.isEmpty {
            return results
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        guard let url = URL(string: baseURL) else {
            throw EmbeddingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "input": uncachedTexts.map { $0.text },
            "dimensions": dimensions
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw EmbeddingError.invalidResponse
        }
        
        let embeddings = try parseBatchEmbeddingResponse(data)
        
        // Map results back and cache
        for (i, (index, text)) in uncachedTexts.enumerated() where i < embeddings.count {
            results[index] = embeddings[i]
            let cacheKey = text.prefix(200).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            cacheEmbedding(embeddings[i], for: cacheKey)
        }
        
        return results
    }
    
    /// Calculate cosine similarity between two embeddings
    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        
        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }
        
        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)
        return magnitude > 0 ? dotProduct / magnitude : 0
    }
    
    /// Find the most similar items from a collection using embeddings
    func findSimilar<T>(
        query: String,
        items: [T],
        getEmbedding: (T) -> [Float]?,
        getText: (T) -> String,
        topK: Int = 5,
        threshold: Float = 0.3
    ) async -> [(item: T, similarity: Float)] {
        do {
            let queryEmbedding = try await generateEmbedding(for: query)
            
            var results: [(item: T, similarity: Float)] = []
            
            for item in items {
                let similarity: Float
                
                if let embedding = getEmbedding(item) {
                    // Use pre-computed embedding
                    similarity = cosineSimilarity(queryEmbedding, embedding)
                } else {
                    // Generate embedding on the fly (fallback)
                    do {
                        let itemEmbedding = try await generateEmbedding(for: getText(item))
                        similarity = cosineSimilarity(queryEmbedding, itemEmbedding)
                    } catch {
                        continue
                    }
                }
                
                if similarity >= threshold {
                    results.append((item, similarity))
                }
            }
            
            // Sort by similarity (descending) and take top K
            return results
                .sorted { $0.similarity > $1.similarity }
                .prefix(topK)
                .map { $0 }
        } catch {
            print("EmbeddingService: Failed to find similar items: \(error)")
            return []
        }
    }
    
    /// Find similar memories from a collection
    func findSimilarMemories(
        query: String,
        memories: [AIMemory],
        topK: Int = 5
    ) async -> [AIMemory] {
        let results = await findSimilar(
            query: query,
            items: memories,
            getEmbedding: { $0.embedding },
            getText: { $0.content },
            topK: topK,
            threshold: 0.35
        )
        
        return results.map { $0.item }
    }
    
    // MARK: - Private Helpers
    
    private func parseEmbeddingResponse(_ data: Data) throws -> [Float] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstData = dataArray.first,
              let embedding = firstData["embedding"] as? [Double] else {
            throw EmbeddingError.invalidResponse
        }
        
        return embedding.map { Float($0) }
    }
    
    private func parseBatchEmbeddingResponse(_ data: Data) throws -> [[Float]] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]] else {
            throw EmbeddingError.invalidResponse
        }
        
        // Sort by index to maintain order
        let sortedData = dataArray.sorted { (a, b) in
            (a["index"] as? Int ?? 0) < (b["index"] as? Int ?? 0)
        }
        
        return sortedData.compactMap { item -> [Float]? in
            guard let embedding = item["embedding"] as? [Double] else { return nil }
            return embedding.map { Float($0) }
        }
    }
    
    private func cacheEmbedding(_ embedding: [Float], for key: String) {
        // Remove old entries if cache is too large
        if embeddingCache.count >= maxCacheSize {
            // Remove 20% of cache (oldest entries would be ideal but we just remove arbitrary)
            let keysToRemove = Array(embeddingCache.keys.prefix(maxCacheSize / 5))
            for key in keysToRemove {
                embeddingCache.removeValue(forKey: key)
            }
        }
        
        embeddingCache[key] = embedding
    }
    
    /// Clear the embedding cache
    func clearCache() {
        embeddingCache.removeAll()
    }
    
    /// Get cache statistics
    var cacheStats: (count: Int, maxSize: Int) {
        (embeddingCache.count, maxCacheSize)
    }
}

// MARK: - Errors

enum EmbeddingError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid embedding API URL"
        case .invalidResponse:
            return "Invalid response from embedding API"
        case .apiError(let message):
            return "Embedding API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

