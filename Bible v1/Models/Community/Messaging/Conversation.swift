//
//  Conversation.swift
//  Bible v1
//
//  Community Tab - Conversation Model
//

import Foundation

/// A conversation (DM or group chat)
struct Conversation: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ConversationType
    var participantIds: [UUID]
    var groupId: UUID?
    var lastMessageAt: Date?
    let createdAt: Date
    
    // Joined data
    var participants: [CommunityProfileSummary]?
    var lastMessage: Message?
    var unreadCount: Int?
    var group: GroupSummary?
    
    enum CodingKeys: String, CodingKey {
        case id, type
        case participantIds = "participant_ids"
        case groupId = "group_id"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
        case participants
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case group
    }
    
    init(
        id: UUID = UUID(),
        type: ConversationType = .direct,
        participantIds: [UUID],
        groupId: UUID? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date = Date(),
        participants: [CommunityProfileSummary]? = nil,
        lastMessage: Message? = nil,
        unreadCount: Int? = nil,
        group: GroupSummary? = nil
    ) {
        self.id = id
        self.type = type
        self.participantIds = participantIds
        self.groupId = groupId
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.participants = participants
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.group = group
    }
    
    /// Get the other participant in a direct conversation
    func otherParticipant(currentUserId: UUID) -> CommunityProfileSummary? {
        participants?.first { $0.id != currentUserId }
    }
    
    /// Display name for the conversation
    func displayName(currentUserId: UUID) -> String {
        if let group = group {
            return group.name
        }
        if let other = otherParticipant(currentUserId: currentUserId) {
            return other.displayName
        }
        return "Conversation"
    }
    
    /// Check if has unread messages
    var hasUnread: Bool {
        (unreadCount ?? 0) > 0
    }
}

/// Types of conversations
enum ConversationType: String, Codable {
    case direct = "direct"
    case groupChat = "group_chat"
    
    var displayName: String {
        switch self {
        case .direct: return "Direct Message"
        case .groupChat: return "Group Chat"
        }
    }
}

