//
//  ChatMessage.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Chat Message Model
//

import Foundation
import SwiftUI

/// Represents a single message in the chat
struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    // For assistant messages
    var title: String?
    var citations: [AICitation]
    var followUps: [String]
    var actions: [AIAction]
    var mode: AIMode?
    
    // For safety responses
    var isSafetyResponse: Bool
    var safetyResources: [String]?
    
    // Image attachments (for vision messages)
    var imageAttachments: [ChatImageAttachment]
    
    // Streaming state (not persisted)
    var isStreaming: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp, title, citations
        case followUps, actions, mode, isSafetyResponse, safetyResources
        case imageAttachments
    }
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        title: String? = nil,
        citations: [AICitation] = [],
        followUps: [String] = [],
        actions: [AIAction] = [],
        mode: AIMode? = nil,
        isSafetyResponse: Bool = false,
        safetyResources: [String]? = nil,
        imageAttachments: [ChatImageAttachment] = [],
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.title = title
        self.citations = citations
        self.followUps = followUps
        self.actions = actions
        self.mode = mode
        self.isSafetyResponse = isSafetyResponse
        self.safetyResources = safetyResources
        self.imageAttachments = imageAttachments
        self.isStreaming = isStreaming
    }
    
    // Custom encode/decode to handle isStreaming (not persisted)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(MessageRole.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        citations = try container.decodeIfPresent([AICitation].self, forKey: .citations) ?? []
        followUps = try container.decodeIfPresent([String].self, forKey: .followUps) ?? []
        actions = try container.decodeIfPresent([AIAction].self, forKey: .actions) ?? []
        mode = try container.decodeIfPresent(AIMode.self, forKey: .mode)
        isSafetyResponse = try container.decodeIfPresent(Bool.self, forKey: .isSafetyResponse) ?? false
        safetyResources = try container.decodeIfPresent([String].self, forKey: .safetyResources)
        imageAttachments = try container.decodeIfPresent([ChatImageAttachment].self, forKey: .imageAttachments) ?? []
        isStreaming = false // Never persist streaming state
    }
    
    /// Whether this message has attached images
    var hasImages: Bool {
        !imageAttachments.isEmpty
    }
    
    /// Create a user message
    static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content)
    }
    
    /// Create a user message with images
    static func user(_ content: String, images: [ChatImageAttachment]) -> ChatMessage {
        ChatMessage(role: .user, content: content, imageAttachments: images)
    }
    
    /// Create an assistant message (streaming placeholder)
    static func assistantStreaming() -> ChatMessage {
        ChatMessage(role: .assistant, content: "", isStreaming: true)
    }
    
    /// Create a safety response message
    static func safety(_ response: SafetyResponse) -> ChatMessage {
        ChatMessage(
            role: .assistant,
            content: response.message,
            citations: response.calmingVerses,
            isSafetyResponse: true,
            safetyResources: response.resourceLinks.map { $0.url }
        )
    }
    
    /// Update content during streaming
    func withAppendedContent(_ newContent: String) -> ChatMessage {
        ChatMessage(
            id: id,
            role: role,
            content: content + newContent,
            timestamp: timestamp,
            title: title,
            citations: citations,
            followUps: followUps,
            actions: actions,
            mode: mode,
            isSafetyResponse: isSafetyResponse,
            safetyResources: safetyResources,
            imageAttachments: imageAttachments,
            isStreaming: isStreaming
        )
    }
    
    /// Finalize message after streaming
    func finalized(with response: AIResponse, resolvedCitations: [AICitation]) -> ChatMessage {
        ChatMessage(
            id: id,
            role: role,
            content: response.answerMarkdown,
            timestamp: timestamp,
            title: response.title,
            citations: resolvedCitations,
            followUps: response.followUps,
            actions: response.actions,
            mode: response.parsedMode,
            isSafetyResponse: false,
            safetyResources: nil,
            isStreaming: false
        )
    }
    
    /// Time formatted for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Date formatted for grouping
    var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(timestamp) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: timestamp)
        }
    }
}

/// The role of a chat message sender
enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

