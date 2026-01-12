//
//  ChatStorageService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Persistent Chat Storage
//

import Foundation
import Combine

/// Service for persisting chat conversations
class ChatStorageService: ObservableObject {
    static let shared = ChatStorageService()
    
    // MARK: - Storage Keys
    
    private let conversationsKey = "trc_ai_conversations"
    private let currentConversationIdKey = "trc_ai_current_conversation_id"
    
    // MARK: - Published State
    
    @Published private(set) var conversations: [ChatConversation] = []
    @Published var currentConversationId: UUID?
    
    // MARK: - Initialization
    
    init() {
        loadConversations()
        loadCurrentConversationId()
    }
    
    // MARK: - Current Conversation
    
    /// Get the current conversation
    var currentConversation: ChatConversation? {
        guard let id = currentConversationId else { return nil }
        return conversations.first { $0.id == id }
    }
    
    /// Get or create a current conversation
    func getOrCreateCurrentConversation(translationId: String = "engKJV") -> ChatConversation {
        if let current = currentConversation {
            return current
        }
        
        let newConversation = ChatConversation(translationId: translationId)
        addConversation(newConversation)
        setCurrentConversation(newConversation.id)
        return newConversation
    }
    
    /// Set the current conversation
    func setCurrentConversation(_ id: UUID) {
        currentConversationId = id
        UserDefaults.standard.set(id.uuidString, forKey: currentConversationIdKey)
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new conversation
    func addConversation(_ conversation: ChatConversation) {
        conversations.insert(conversation, at: 0) // Most recent first
        saveConversations()
    }
    
    /// Update an existing conversation
    func updateConversation(_ conversation: ChatConversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            // Move to top of list
            let updated = conversations.remove(at: index)
            conversations.insert(updated, at: 0)
            saveConversations()
        }
    }
    
    /// Delete a conversation
    func deleteConversation(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        
        // If we deleted the current conversation, clear the reference
        if currentConversationId == id {
            currentConversationId = conversations.first?.id
            if let newId = currentConversationId {
                UserDefaults.standard.set(newId.uuidString, forKey: currentConversationIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: currentConversationIdKey)
            }
        }
        
        saveConversations()
    }
    
    /// Delete all conversations
    func deleteAllConversations() {
        conversations.removeAll()
        currentConversationId = nil
        UserDefaults.standard.removeObject(forKey: currentConversationIdKey)
        saveConversations()
    }
    
    /// Start a new conversation
    func startNewConversation(mode: AIMode = .study, translationId: String = "engKJV") -> ChatConversation {
        let newConversation = ChatConversation(
            currentMode: mode,
            translationId: translationId
        )
        addConversation(newConversation)
        setCurrentConversation(newConversation.id)
        return newConversation
    }
    
    // MARK: - Message Operations
    
    /// Add a message to a conversation
    func addMessage(_ message: ChatMessage, to conversationId: UUID) {
        guard var conversation = conversations.first(where: { $0.id == conversationId }) else {
            return
        }
        
        conversation.addMessage(message)
        updateConversation(conversation)
    }
    
    /// Update a message in a conversation (for streaming updates)
    func updateMessage(_ message: ChatMessage, in conversationId: UUID) {
        guard var conversation = conversations.first(where: { $0.id == conversationId }) else {
            return
        }
        
        conversation.updateMessage(message)
        updateConversation(conversation)
    }
    
    /// Remove the last message from a conversation (for error recovery)
    func removeLastMessage(from conversationId: UUID) {
        guard var conversation = conversations.first(where: { $0.id == conversationId }) else {
            return
        }
        
        conversation.removeLastMessage()
        updateConversation(conversation)
    }
    
    /// Update conversation mode
    func updateMode(_ mode: AIMode, for conversationId: UUID) {
        guard var conversation = conversations.first(where: { $0.id == conversationId }) else {
            return
        }
        
        conversation.currentMode = mode
        updateConversation(conversation)
    }
    
    // MARK: - Persistence
    
    private func loadConversations() {
        guard let data = UserDefaults.standard.data(forKey: conversationsKey) else {
            conversations = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            conversations = try decoder.decode([ChatConversation].self, from: data)
        } catch {
            print("Failed to load conversations: \(error)")
            conversations = []
        }
    }
    
    private func saveConversations() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(conversations)
            UserDefaults.standard.set(data, forKey: conversationsKey)
        } catch {
            print("Failed to save conversations: \(error)")
        }
    }
    
    private func loadCurrentConversationId() {
        guard let idString = UserDefaults.standard.string(forKey: currentConversationIdKey),
              let id = UUID(uuidString: idString) else {
            currentConversationId = conversations.first?.id
            return
        }
        
        // Verify the conversation still exists
        if conversations.contains(where: { $0.id == id }) {
            currentConversationId = id
        } else {
            currentConversationId = conversations.first?.id
        }
    }
    
    // MARK: - Archive Operations
    
    /// Archive a conversation
    func archiveConversation(_ id: UUID) {
        guard var conversation = conversations.first(where: { $0.id == id }) else {
            return
        }
        
        conversation.archive()
        
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            conversations[index] = conversation
            saveConversations()
        }
        
        // If we archived the current conversation, select a new one
        if currentConversationId == id {
            currentConversationId = activeConversations.first?.id
            if let newId = currentConversationId {
                UserDefaults.standard.set(newId.uuidString, forKey: currentConversationIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: currentConversationIdKey)
            }
        }
    }
    
    /// Unarchive a conversation
    func unarchiveConversation(_ id: UUID) {
        guard var conversation = conversations.first(where: { $0.id == id }) else {
            return
        }
        
        conversation.unarchive()
        
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            conversations[index] = conversation
            // Move to top of list
            let updated = conversations.remove(at: index)
            conversations.insert(updated, at: 0)
            saveConversations()
        }
    }
    
    /// Get only active (non-archived) conversations
    var activeConversations: [ChatConversation] {
        conversations.filter { !$0.isArchived }
    }
    
    /// Get only archived conversations
    var archivedConversations: [ChatConversation] {
        conversations.filter { $0.isArchived }
    }
    
    /// Archived conversation count
    var archivedCount: Int {
        archivedConversations.count
    }
    
    // MARK: - Search & Filter
    
    /// Search conversations by content (searches active conversations by default)
    func searchConversations(query: String, includeArchived: Bool = false) -> [ChatConversation] {
        let baseConversations = includeArchived ? conversations : activeConversations
        guard !query.isEmpty else { return baseConversations }
        
        let lowercased = query.lowercased()
        return baseConversations.filter { conversation in
            conversation.title.lowercased().contains(lowercased) ||
            conversation.messages.contains { message in
                message.content.lowercased().contains(lowercased)
            }
        }
    }
    
    /// Enhanced search that returns message-level results with context
    func searchWithHighlights(query: String, includeArchived: Bool = false) -> [ConversationSearchResult] {
        let baseConversations = includeArchived ? conversations : activeConversations
        guard !query.isEmpty else { return [] }
        
        let lowercased = query.lowercased()
        var results: [ConversationSearchResult] = []
        
        for conversation in baseConversations {
            var matchingMessages: [MessageSearchMatch] = []
            
            for message in conversation.messages {
                let content = message.content
                let contentLower = content.lowercased()
                
                if contentLower.contains(lowercased) {
                    // Find all match ranges
                    let ranges = findMatchRanges(in: content, for: query)
                    
                    // Create context snippet around first match
                    let snippet = createContextSnippet(
                        content: content,
                        query: query,
                        maxLength: 150
                    )
                    
                    matchingMessages.append(MessageSearchMatch(
                        message: message,
                        matchRanges: ranges,
                        contextSnippet: snippet
                    ))
                }
            }
            
            // Also check title match
            let titleMatches = conversation.title.lowercased().contains(lowercased)
            
            if !matchingMessages.isEmpty || titleMatches {
                results.append(ConversationSearchResult(
                    conversation: conversation,
                    matchingMessages: matchingMessages,
                    titleMatches: titleMatches,
                    totalMatchCount: matchingMessages.reduce(0) { $0 + $1.matchRanges.count }
                ))
            }
        }
        
        // Sort by relevance (total match count, then recency)
        return results.sorted { a, b in
            if a.totalMatchCount != b.totalMatchCount {
                return a.totalMatchCount > b.totalMatchCount
            }
            return a.conversation.dateModified > b.conversation.dateModified
        }
    }
    
    /// Find all ranges where query matches in content
    private func findMatchRanges(in content: String, for query: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchRange = content.startIndex..<content.endIndex
        
        while let range = content.range(of: query, options: .caseInsensitive, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<content.endIndex
        }
        
        return ranges
    }
    
    /// Create a context snippet around the first match
    private func createContextSnippet(content: String, query: String, maxLength: Int) -> String {
        guard let range = content.range(of: query, options: .caseInsensitive) else {
            return String(content.prefix(maxLength))
        }
        
        let matchStart = content.distance(from: content.startIndex, to: range.lowerBound)
        let contextStart = max(0, matchStart - 40)
        let contextEnd = min(content.count, matchStart + query.count + 80)
        
        let startIndex = content.index(content.startIndex, offsetBy: contextStart)
        let endIndex = content.index(content.startIndex, offsetBy: contextEnd)
        
        var snippet = String(content[startIndex..<endIndex])
        
        // Add ellipsis if truncated
        if contextStart > 0 {
            snippet = "..." + snippet
        }
        if contextEnd < content.count {
            snippet = snippet + "..."
        }
        
        return snippet
    }
    
    /// Get conversations by mode (active only)
    func conversations(for mode: AIMode) -> [ChatConversation] {
        activeConversations.filter { $0.currentMode == mode }
    }
    
    /// Get conversations from today (active only)
    var todaysConversations: [ChatConversation] {
        let calendar = Calendar.current
        return activeConversations.filter {
            calendar.isDateInToday($0.dateModified)
        }
    }
    
    /// Get recent conversations (last 7 days, active only)
    var recentConversations: [ChatConversation] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return activeConversations.filter { $0.dateModified >= weekAgo }
    }
    
    // MARK: - Statistics
    
    /// Total message count across all conversations
    var totalMessageCount: Int {
        conversations.reduce(0) { $0 + $1.messageCount }
    }
    
    /// Total conversation count
    var conversationCount: Int {
        conversations.count
    }
    
    /// Active conversation count
    var activeConversationCount: Int {
        activeConversations.count
    }
    
    // MARK: - Date Grouping
    
    /// Group active conversations by date for sidebar display
    var groupedActiveConversations: [(title: String, conversations: [ChatConversation])] {
        var groups: [(title: String, conversations: [ChatConversation])] = []
        let calendar = Calendar.current
        
        let today = activeConversations.filter { calendar.isDateInToday($0.dateModified) }
        if !today.isEmpty {
            groups.append(("Today", today))
        }
        
        let yesterday = activeConversations.filter { calendar.isDateInYesterday($0.dateModified) }
        if !yesterday.isEmpty {
            groups.append(("Yesterday", yesterday))
        }
        
        let thisWeek = activeConversations.filter { conv in
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return false }
            return conv.dateModified >= weekAgo && 
                   !calendar.isDateInToday(conv.dateModified) && 
                   !calendar.isDateInYesterday(conv.dateModified)
        }
        if !thisWeek.isEmpty {
            groups.append(("This Week", thisWeek))
        }
        
        let older = activeConversations.filter { conv in
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return false }
            return conv.dateModified < weekAgo
        }
        if !older.isEmpty {
            groups.append(("Older", older))
        }
        
        return groups
    }
}

// MARK: - Export

extension ChatStorageService {
    
    /// Export a conversation as text
    func exportConversation(_ conversation: ChatConversation) -> String {
        var text = "# \(conversation.title)\n"
        text += "Mode: \(conversation.currentMode.displayName)\n"
        text += "Date: \(conversation.formattedDate)\n\n"
        
        for message in conversation.messages {
            let role = message.role == .user ? "You" : "TRC AI"
            text += "**\(role)** (\(message.formattedTime)):\n"
            text += "\(message.content)\n\n"
            
            if !message.citations.isEmpty {
                text += "Citations: \(message.citations.map { $0.reference }.joined(separator: ", "))\n\n"
            }
        }
        
        return text
    }
    
    /// Export all conversations as JSON
    func exportAllAsJSON() -> Data? {
        try? JSONEncoder().encode(conversations)
    }
    
    /// Import conversations from JSON data
    func importFromJSON(_ data: Data) throws -> Int {
        let decoder = JSONDecoder()
        let imported = try decoder.decode([ChatConversation].self, from: data)
        
        // Merge with existing, avoiding duplicates by ID
        let existingIds = Set(conversations.map { $0.id })
        let newConversations = imported.filter { !existingIds.contains($0.id) }
        
        conversations.append(contentsOf: newConversations)
        conversations.sort { $0.dateModified > $1.dateModified }
        saveConversations()
        
        return newConversations.count
    }
}

// MARK: - Usage Statistics

extension ChatStorageService {
    
    /// Comprehensive usage statistics
    var usageStatistics: AIUsageStatistics {
        AIUsageStatistics(
            totalConversations: conversationCount,
            activeConversations: activeConversationCount,
            archivedConversations: archivedCount,
            totalMessages: totalMessageCount,
            userMessages: userMessageCount,
            aiMessages: aiMessageCount,
            totalCitations: totalCitationCount,
            conversationsByMode: conversationCountByMode,
            messagesByDay: messageCountByDay,
            averageMessagesPerConversation: averageMessagesPerConversation,
            mostActiveDay: mostActiveDay,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            topCitedBooks: topCitedBooks,
            firstConversationDate: conversations.last?.dateCreated,
            accountAgeDays: accountAgeDays
        )
    }
    
    /// User message count
    private var userMessageCount: Int {
        conversations.flatMap { $0.messages }.filter { $0.role == .user }.count
    }
    
    /// AI message count
    private var aiMessageCount: Int {
        conversations.flatMap { $0.messages }.filter { $0.role == .assistant }.count
    }
    
    /// Total citations across all messages
    private var totalCitationCount: Int {
        conversations.flatMap { $0.messages }.flatMap { $0.citations }.count
    }
    
    /// Conversation count by mode
    private var conversationCountByMode: [AIMode: Int] {
        var counts: [AIMode: Int] = [:]
        for mode in AIMode.allCases {
            counts[mode] = conversations.filter { $0.currentMode == mode }.count
        }
        return counts
    }
    
    /// Message count by day (last 30 days)
    private var messageCountByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for conversation in conversations {
            for message in conversation.messages {
                let day = calendar.startOfDay(for: message.timestamp)
                counts[day, default: 0] += 1
            }
        }
        
        return counts
    }
    
    /// Average messages per conversation
    private var averageMessagesPerConversation: Double {
        guard !conversations.isEmpty else { return 0 }
        return Double(totalMessageCount) / Double(conversationCount)
    }
    
    /// Most active day of the week
    private var mostActiveDay: String? {
        var dayCounts: [Int: Int] = [:] // Weekday: count
        let calendar = Calendar.current
        
        for conversation in conversations {
            for message in conversation.messages {
                let weekday = calendar.component(.weekday, from: message.timestamp)
                dayCounts[weekday, default: 0] += 1
            }
        }
        
        guard let (weekday, _) = dayCounts.max(by: { $0.value < $1.value }) else { return nil }
        
        let formatter = DateFormatter()
        formatter.weekdaySymbols = Calendar.current.weekdaySymbols
        return formatter.weekdaySymbols[weekday - 1]
    }
    
    /// Current usage streak (consecutive days with at least one message)
    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get unique days with messages, sorted descending
        let messageDays = Set(
            conversations.flatMap { $0.messages }
                .map { calendar.startOfDay(for: $0.timestamp) }
        ).sorted(by: >)
        
        guard !messageDays.isEmpty else { return 0 }
        
        // Check if today or yesterday has a message (streak must be current)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard messageDays.first == today || messageDays.first == yesterday else { return 0 }
        
        var streak = 0
        var checkDate = messageDays.first!
        
        for day in messageDays {
            if day == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if day < checkDate {
                break
            }
        }
        
        return streak
    }
    
    /// Longest usage streak ever
    private var longestStreak: Int {
        let calendar = Calendar.current
        
        let messageDays = Set(
            conversations.flatMap { $0.messages }
                .map { calendar.startOfDay(for: $0.timestamp) }
        ).sorted()
        
        guard messageDays.count > 1 else { return messageDays.count }
        
        var longest = 1
        var current = 1
        
        for i in 1..<messageDays.count {
            let expected = calendar.date(byAdding: .day, value: 1, to: messageDays[i-1])!
            if messageDays[i] == expected {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        
        return longest
    }
    
    /// Top cited Bible books
    private var topCitedBooks: [(book: String, count: Int)] {
        var bookCounts: [String: Int] = [:]
        
        for conversation in conversations {
            for message in conversation.messages {
                for citation in message.citations {
                    if let bookName = citation.bookName {
                        bookCounts[bookName, default: 0] += 1
                    }
                }
            }
        }
        
        return bookCounts
            .map { (book: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }
    
    /// Account age in days
    private var accountAgeDays: Int {
        guard let firstDate = conversations.last?.dateCreated else { return 0 }
        return Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 0
    }
}

// MARK: - Usage Statistics Model

struct AIUsageStatistics {
    let totalConversations: Int
    let activeConversations: Int
    let archivedConversations: Int
    let totalMessages: Int
    let userMessages: Int
    let aiMessages: Int
    let totalCitations: Int
    let conversationsByMode: [AIMode: Int]
    let messagesByDay: [Date: Int]
    let averageMessagesPerConversation: Double
    let mostActiveDay: String?
    let currentStreak: Int
    let longestStreak: Int
    let topCitedBooks: [(book: String, count: Int)]
    let firstConversationDate: Date?
    let accountAgeDays: Int
    
    /// Messages in the last 7 days
    var messagesLast7Days: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return messagesByDay.filter { $0.key >= weekAgo }.values.reduce(0, +)
    }
    
    /// Messages in the last 30 days
    var messagesLast30Days: Int {
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return messagesByDay.filter { $0.key >= monthAgo }.values.reduce(0, +)
    }
}

// MARK: - Search Result Types

/// Result of a conversation search with message-level matches
struct ConversationSearchResult: Identifiable {
    let id = UUID()
    let conversation: ChatConversation
    let matchingMessages: [MessageSearchMatch]
    let titleMatches: Bool
    let totalMatchCount: Int
    
    /// Preview text for display
    var previewText: String {
        if let firstMatch = matchingMessages.first {
            return firstMatch.contextSnippet
        }
        return conversation.title
    }
}

/// A single message match within a conversation
struct MessageSearchMatch: Identifiable {
    let id = UUID()
    let message: ChatMessage
    let matchRanges: [Range<String.Index>]
    let contextSnippet: String
    
    /// Number of matches in this message
    var matchCount: Int {
        matchRanges.count
    }
}

