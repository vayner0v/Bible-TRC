//
//  Message.swift
//  Bible v1
//
//  Community Tab - Message Model
//

import Foundation

/// A message in a conversation
struct Message: Identifiable, Codable, Hashable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    var content: String
    var mediaUrl: String?
    var verseRef: PostVerseRef?
    var isRead: Bool
    var readAt: Date?
    let createdAt: Date
    var deletedAt: Date?
    
    // Joined data
    var sender: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case mediaUrl = "media_url"
        case verseRef = "verse_ref"
        case isRead = "is_read"
        case readAt = "read_at"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case sender
    }
    
    init(
        id: UUID = UUID(),
        conversationId: UUID,
        senderId: UUID,
        content: String,
        mediaUrl: String? = nil,
        verseRef: PostVerseRef? = nil,
        isRead: Bool = false,
        readAt: Date? = nil,
        createdAt: Date = Date(),
        deletedAt: Date? = nil,
        sender: CommunityProfileSummary? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.mediaUrl = mediaUrl
        self.verseRef = verseRef
        self.isRead = isRead
        self.readAt = readAt
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.sender = sender
    }
    
    /// Check if message is deleted
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    /// Check if message has media
    var hasMedia: Bool {
        mediaUrl != nil
    }
    
    /// Check if message has verse
    var hasVerse: Bool {
        verseRef != nil
    }
    
    /// Relative time since sent
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// Check if sent by current user
    func isSentBy(_ userId: UUID) -> Bool {
        senderId == userId
    }
}

/// Request to send a message
struct SendMessageRequest: Codable {
    let conversationId: UUID
    let content: String
    let mediaUrl: String?
    let verseRef: PostVerseRef?
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case content
        case mediaUrl = "media_url"
        case verseRef = "verse_ref"
    }
}

