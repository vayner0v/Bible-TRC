//
//  AIMemoryService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Memory Storage Service
//

import Foundation
import Combine

/// Service for managing AI memories with hybrid local/cloud storage
@MainActor
class AIMemoryService: ObservableObject {
    static let shared = AIMemoryService()
    
    // MARK: - Storage Keys
    
    private let memoriesKey = "trc_ai_memories"
    
    // MARK: - Published State
    
    @Published private(set) var memories: [AIMemory] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Dependencies
    
    private let preferencesService = AIPreferencesService.shared
    
    // MARK: - Initialization
    
    init() {
        loadMemories()
    }
    
    // MARK: - Computed Properties
    
    /// Only active memories
    var activeMemories: [AIMemory] {
        memories.filter { $0.isActive }
    }
    
    /// Memories grouped by type
    var memoriesByType: [MemoryType: [AIMemory]] {
        Dictionary(grouping: activeMemories) { $0.type }
    }
    
    /// Summary statistics
    var summary: MemorySummary {
        MemorySummary(memories: memories)
    }
    
    /// Memory context for AI prompts
    var memoryContext: MemoryContext {
        let active = activeMemories
        return MemoryContext(
            prayerRequests: active.filter { $0.type == .prayerRequest },
            favoriteVerses: active.filter { $0.type == .favoriteVerse },
            struggles: active.filter { $0.type == .recurringStruggle },
            insights: active.filter { $0.type == .helpfulInsight },
            personalContext: active.filter { $0.type == .personalContext }
        )
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new memory
    func addMemory(_ memory: AIMemory) {
        memories.insert(memory, at: 0)
        saveMemories()
        syncToCloudIfNeeded()
    }
    
    /// Add memory from content
    func addMemory(
        type: MemoryType,
        content: String,
        sourceMessageId: UUID? = nil,
        sourceConversationId: UUID? = nil,
        relatedVerses: [String] = []
    ) {
        let memory = AIMemory(
            type: type,
            content: content,
            sourceMessageId: sourceMessageId,
            sourceConversationId: sourceConversationId,
            relatedVerses: relatedVerses
        )
        addMemory(memory)
    }
    
    /// Update a memory
    func updateMemory(_ memory: AIMemory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
            saveMemories()
            syncToCloudIfNeeded()
        }
    }
    
    /// Deactivate a memory (soft delete)
    func deactivateMemory(_ id: UUID) {
        if let index = memories.firstIndex(where: { $0.id == id }) {
            memories[index] = memories[index].deactivated()
            saveMemories()
            syncToCloudIfNeeded()
        }
    }
    
    /// Reactivate a memory
    func reactivateMemory(_ id: UUID) {
        if let index = memories.firstIndex(where: { $0.id == id }) {
            memories[index] = memories[index].reactivated()
            saveMemories()
            syncToCloudIfNeeded()
        }
    }
    
    /// Permanently delete a memory
    func deleteMemory(_ id: UUID) {
        memories.removeAll { $0.id == id }
        saveMemories()
        syncToCloudIfNeeded()
    }
    
    /// Delete all memories
    func deleteAllMemories() {
        memories.removeAll()
        saveMemories()
        syncToCloudIfNeeded()
    }
    
    /// Delete all memories of a specific type
    func deleteMemories(ofType type: MemoryType) {
        memories.removeAll { $0.type == type }
        saveMemories()
        syncToCloudIfNeeded()
    }
    
    // MARK: - Search & Filter
    
    /// Search memories by content (keyword-based)
    func searchMemories(query: String) -> [AIMemory] {
        guard !query.isEmpty else { return activeMemories }
        
        let lowercased = query.lowercased()
        return activeMemories.filter { memory in
            memory.content.lowercased().contains(lowercased) ||
            memory.tags.contains { $0.lowercased().contains(lowercased) } ||
            memory.relatedVerses.contains { $0.lowercased().contains(lowercased) }
        }
    }
    
    /// Semantic search using embeddings (finds conceptually similar memories)
    func semanticSearch(query: String, topK: Int = 5) async -> [AIMemory] {
        let memoriesWithEmbeddings = activeMemories.filter { $0.hasEmbedding }
        
        // If no memories have embeddings, fall back to keyword search + importance scoring
        if memoriesWithEmbeddings.isEmpty {
            return topMemoriesByImportance(limit: topK)
        }
        
        // Use embedding service for semantic similarity
        let results = await EmbeddingService.shared.findSimilarMemories(
            query: query,
            memories: memoriesWithEmbeddings,
            topK: topK
        )
        
        // Mark these memories as accessed
        for memory in results {
            markMemoryAccessed(memory.id)
        }
        
        return results
    }
    
    /// Get memories relevant to a query using hybrid search (semantic + keyword + importance)
    func findRelevantMemories(for query: String, limit: Int = 5) async -> [AIMemory] {
        // 1. Try semantic search first
        let semanticResults = await semanticSearch(query: query, topK: limit)
        
        // 2. Also get keyword matches
        let keywordResults = searchMemories(query: query)
        
        // 3. Merge results, prioritizing semantic matches
        var seen = Set<UUID>()
        var merged: [AIMemory] = []
        
        for memory in semanticResults {
            if !seen.contains(memory.id) {
                seen.insert(memory.id)
                merged.append(memory)
            }
        }
        
        for memory in keywordResults where merged.count < limit {
            if !seen.contains(memory.id) {
                seen.insert(memory.id)
                merged.append(memory)
            }
        }
        
        // 4. If still under limit, add top importance memories
        if merged.count < limit {
            let topImportance = topMemoriesByImportance(limit: limit)
            for memory in topImportance where merged.count < limit {
                if !seen.contains(memory.id) {
                    seen.insert(memory.id)
                    merged.append(memory)
                }
            }
        }
        
        return merged
    }
    
    /// Get top memories ranked by importance score
    func topMemoriesByImportance(limit: Int = 10) -> [AIMemory] {
        activeMemories
            .sorted { $0.importanceScore > $1.importanceScore }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Get memory context using semantic search for a specific query
    func relevantMemoryContext(for query: String) async -> MemoryContext {
        let relevant = await findRelevantMemories(for: query, limit: 10)
        return MemoryContext(
            prayerRequests: relevant.filter { $0.type == .prayerRequest },
            favoriteVerses: relevant.filter { $0.type == .favoriteVerse },
            struggles: relevant.filter { $0.type == .recurringStruggle },
            insights: relevant.filter { $0.type == .helpfulInsight },
            personalContext: relevant.filter { $0.type == .personalContext }
        )
    }
    
    /// Get memories by type
    func memories(ofType type: MemoryType) -> [AIMemory] {
        activeMemories.filter { $0.type == type }
    }
    
    /// Get recent memories
    func recentMemories(limit: Int = 10) -> [AIMemory] {
        Array(activeMemories.prefix(limit))
    }
    
    /// Get memories from a specific conversation
    func memories(forConversation conversationId: UUID) -> [AIMemory] {
        activeMemories.filter { $0.sourceConversationId == conversationId }
    }
    
    /// Mark a memory as accessed (updates access count and last accessed date)
    func markMemoryAccessed(_ id: UUID) {
        if let index = memories.firstIndex(where: { $0.id == id }) {
            memories[index] = memories[index].accessed()
            saveMemories()
        }
    }
    
    // MARK: - Embedding Management
    
    /// Generate embedding for a memory
    func generateEmbedding(for memoryId: UUID) async {
        guard let index = memories.firstIndex(where: { $0.id == memoryId }) else { return }
        
        do {
            let embedding = try await EmbeddingService.shared.generateEmbedding(for: memories[index].content)
            memories[index] = memories[index].withEmbedding(embedding)
            saveMemories()
        } catch {
            print("AIMemoryService: Failed to generate embedding for memory \(memoryId): \(error)")
        }
    }
    
    /// Generate embeddings for all memories that don't have one
    func generateMissingEmbeddings() async {
        let memoriesNeedingEmbeddings = memories.filter { !$0.hasEmbedding }
        
        guard !memoriesNeedingEmbeddings.isEmpty else { return }
        
        print("AIMemoryService: Generating embeddings for \(memoriesNeedingEmbeddings.count) memories")
        
        // Process in batches to avoid overwhelming the API
        let batchSize = 10
        for batch in stride(from: 0, to: memoriesNeedingEmbeddings.count, by: batchSize) {
            let end = min(batch + batchSize, memoriesNeedingEmbeddings.count)
            let batchMemories = Array(memoriesNeedingEmbeddings[batch..<end])
            
            do {
                let texts = batchMemories.map { $0.content }
                let embeddings = try await EmbeddingService.shared.generateEmbeddings(for: texts)
                
                for (i, memory) in batchMemories.enumerated() where i < embeddings.count {
                    if let index = memories.firstIndex(where: { $0.id == memory.id }) {
                        memories[index] = memories[index].withEmbedding(embeddings[i])
                    }
                }
                
                saveMemories()
            } catch {
                print("AIMemoryService: Batch embedding generation failed: \(error)")
            }
        }
    }
    
    /// Get count of memories without embeddings
    var memoriesWithoutEmbeddings: Int {
        memories.filter { !$0.hasEmbedding }.count
    }
    
    // MARK: - Memory Extraction
    
    /// Extract potential memories from an AI response
    func extractPotentialMemories(from content: String, messageId: UUID, conversationId: UUID) -> [AIMemory] {
        var potentialMemories: [AIMemory] = []
        
        // Look for verse references that might be favorites
        let versePattern = #"\(([1-3]?\s?[A-Za-z]+\s+\d+:\d+(?:-\d+)?)\)"#
        if let regex = try? NSRegularExpression(pattern: versePattern) {
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, range: range)
            
            for match in matches {
                if let verseRange = Range(match.range(at: 1), in: content) {
                    let verse = String(content[verseRange])
                    potentialMemories.append(AIMemory(
                        type: .favoriteVerse,
                        content: "Verse mentioned in conversation",
                        sourceMessageId: messageId,
                        sourceConversationId: conversationId,
                        relatedVerses: [verse]
                    ))
                }
            }
        }
        
        return potentialMemories
    }
    
    // MARK: - Persistence (Local)
    
    private func loadMemories() {
        guard let data = UserDefaults.standard.data(forKey: memoriesKey) else {
            memories = []
            return
        }
        
        do {
            memories = try JSONDecoder().decode([AIMemory].self, from: data)
        } catch {
            print("Failed to load memories: \(error)")
            memories = []
        }
    }
    
    private func saveMemories() {
        do {
            let data = try JSONEncoder().encode(memories)
            UserDefaults.standard.set(data, forKey: memoriesKey)
        } catch {
            print("Failed to save memories: \(error)")
        }
    }
    
    // MARK: - Cloud Sync (Supabase)
    
    /// Check if user is authenticated for cloud sync
    private var isUserAuthenticated: Bool {
        AuthService.shared.authState.isAuthenticated
    }
    
    private func syncToCloudIfNeeded() {
        guard preferencesService.isMemoryEnabled,
              isUserAuthenticated,
              SupabaseService.shared.isConfigured else { return }
        
        Task {
            await syncToCloud()
        }
    }
    
    /// Sync memories to Supabase
    /// Note: Requires backend table setup for ai_memories
    func syncToCloud() async {
        guard isUserAuthenticated,
              SupabaseService.shared.isConfigured else { return }
        
        do {
            let data = try JSONEncoder().encode(memories)
            guard String(data: data, encoding: .utf8) != nil else { return }
            
            // TODO: Implement Supabase upsert when backend table is ready
            // try await SupabaseService.shared.client.from("ai_memories")
            //     .upsert(["user_id": userId, "memories_json": jsonString])
            //     .execute()
            
            print("Memory sync: \(memories.count) memories ready for cloud sync")
            lastSyncDate = Date()
        } catch {
            print("Failed to prepare memories for sync: \(error)")
        }
    }
    
    /// Load memories from Supabase
    /// Note: Requires backend table setup for ai_memories
    func loadFromCloud() async {
        guard isUserAuthenticated,
              SupabaseService.shared.isConfigured else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement Supabase fetch when backend table is ready
        // do {
        //     let response = try await SupabaseService.shared.client.from("ai_memories")
        //         .select()
        //         .eq("user_id", value: userId)
        //         .single()
        //         .execute()
        //     
        //     if let jsonString = response.data["memories_json"] as? String,
        //        let data = jsonString.data(using: .utf8) {
        //         let cloudMemories = try JSONDecoder().decode([AIMemory].self, from: data)
        //         // Merge logic here
        //     }
        // } catch {
        //     print("Failed to load memories from cloud: \(error)")
        // }
        
        print("Memory load from cloud: Feature pending backend setup")
    }
    
    // MARK: - Export
    
    /// Export memories as JSON
    func exportAsJSON() -> Data? {
        try? JSONEncoder().encode(memories)
    }
    
    /// Export memories as text
    func exportAsText() -> String {
        var text = "# TRC AI Memories\n\n"
        
        for type in MemoryType.allCases {
            let typeMemories = memories(ofType: type)
            if !typeMemories.isEmpty {
                text += "## \(type.displayName)\n\n"
                for memory in typeMemories {
                    text += "- \(memory.content)\n"
                    if !memory.relatedVerses.isEmpty {
                        text += "  Verses: \(memory.relatedVerses.joined(separator: ", "))\n"
                    }
                    text += "  Added: \(memory.formattedDate)\n\n"
                }
            }
        }
        
        return text
    }
}

