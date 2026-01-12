//
//  MessageRequest.swift
//  Bible v1
//
//  Community Tab - Message Request Model
//

import Foundation

/// A request to start a conversation
struct MessageRequest: Identifiable, Codable {
    let id: UUID
    let fromUserId: UUID
    let toUserId: UUID
    var status: MessageRequestStatus
    var initialMessage: String?
    let createdAt: Date
    var respondedAt: Date?
    
    // Joined data
    var fromUser: CommunityProfileSummary?
    var toUser: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case status
        case initialMessage = "initial_message"
        case createdAt = "created_at"
        case respondedAt = "responded_at"
        case fromUser = "from_user"
        case toUser = "to_user"
    }
    
    init(
        id: UUID = UUID(),
        fromUserId: UUID,
        toUserId: UUID,
        status: MessageRequestStatus = .pending,
        initialMessage: String? = nil,
        createdAt: Date = Date(),
        respondedAt: Date? = nil,
        fromUser: CommunityProfileSummary? = nil,
        toUser: CommunityProfileSummary? = nil
    ) {
        self.id = id
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.status = status
        self.initialMessage = initialMessage
        self.createdAt = createdAt
        self.respondedAt = respondedAt
        self.fromUser = fromUser
        self.toUser = toUser
    }
    
    /// Check if request is pending
    var isPending: Bool {
        status == .pending
    }
    
    /// Check if request was accepted
    var wasAccepted: Bool {
        status == .accepted
    }
    
    /// Check if request was declined
    var wasDeclined: Bool {
        status == .declined
    }
}

/// Status of a message request
enum MessageRequestStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        }
    }
}

/// Request to send a message request
struct SendMessageRequestPayload: Codable {
    let toUserId: UUID
    let initialMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case toUserId = "to_user_id"
        case initialMessage = "initial_message"
    }
}

