//
//  ChatConversation.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Conversation Model
//

import Foundation

/// Represents a complete chat conversation
struct ChatConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var currentMode: AIMode
    let dateCreated: Date
    var dateModified: Date
    var translationId: String
    var isArchived: Bool
    var dateArchived: Date?
    
    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        messages: [ChatMessage] = [],
        currentMode: AIMode = .study,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        translationId: String = "engKJV",
        isArchived: Bool = false,
        dateArchived: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.currentMode = currentMode
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.translationId = translationId
        self.isArchived = isArchived
        self.dateArchived = dateArchived
    }
    
    /// Add a message to the conversation
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        dateModified = Date()
        
        // Auto-generate title from first user message if still default
        if title == "New Conversation",
           message.role == .user,
           !message.content.isEmpty {
            title = generateTitle(from: message.content)
        }
    }
    
    /// Update a message (for streaming)
    mutating func updateMessage(_ message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            dateModified = Date()
        }
    }
    
    /// Remove the last message (for error recovery)
    mutating func removeLastMessage() {
        if !messages.isEmpty {
            messages.removeLast()
            dateModified = Date()
        }
    }
    
    /// Get the last user message
    var lastUserMessage: ChatMessage? {
        messages.last { $0.role == .user }
    }
    
    /// Get the last assistant message
    var lastAssistantMessage: ChatMessage? {
        messages.last { $0.role == .assistant }
    }
    
    /// Message count for display
    var messageCount: Int {
        messages.count
    }
    
    /// Formatted date for list display
    var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(dateModified) {
            formatter.timeStyle = .short
            return formatter.string(from: dateModified)
        } else if Calendar.current.isDateInYesterday(dateModified) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: dateModified)
        }
    }
    
    /// Preview text for list display
    var previewText: String {
        if let lastMessage = messages.last {
            let text = lastMessage.content
            if text.count > 60 {
                return String(text.prefix(60)) + "..."
            }
            return text
        }
        return "No messages yet"
    }
    
    /// Generate a title from the first message
    private func generateTitle(from content: String) -> String {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(6)
        let title = words.joined(separator: " ")
        if title.count > 40 {
            return String(title.prefix(40)) + "..."
        }
        return title.isEmpty ? "New Conversation" : title
    }
    
    /// Build context for API (last N messages)
    func buildContextMessages(limit: Int = 10) -> [[String: String]] {
        let recentMessages = messages.suffix(limit)
        return recentMessages.compactMap { message -> [String: String]? in
            guard message.role != .system else { return nil }
            return [
                "role": message.role.rawValue,
                "content": message.content
            ]
        }
    }
    
    // MARK: - Archive Methods
    
    /// Archive the conversation
    mutating func archive() {
        isArchived = true
        dateArchived = Date()
        dateModified = Date()
    }
    
    /// Unarchive the conversation
    mutating func unarchive() {
        isArchived = false
        dateArchived = nil
        dateModified = Date()
    }
    
    /// Formatted archive date
    var formattedArchiveDate: String? {
        guard let date = dateArchived else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

