//
//  Reaction.swift
//  Bible v1
//
//  Community Tab - Reaction Model
//

import Foundation

/// Target type for reactions
enum ReactionTargetType: String, Codable {
    case post = "post"
    case comment = "comment"
}

/// A reaction on a post or comment
struct Reaction: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let targetType: ReactionTargetType
    let targetId: UUID
    let reactionType: ReactionType
    let createdAt: Date
    
    // Joined data
    var user: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case targetType = "target_type"
        case targetId = "target_id"
        case reactionType = "reaction_type"
        case createdAt = "created_at"
        case user
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        targetType: ReactionTargetType,
        targetId: UUID,
        reactionType: ReactionType,
        createdAt: Date = Date(),
        user: CommunityProfileSummary? = nil
    ) {
        self.id = id
        self.userId = userId
        self.targetType = targetType
        self.targetId = targetId
        self.reactionType = reactionType
        self.createdAt = createdAt
        self.user = user
    }
}

/// Request to add a reaction
struct AddReactionRequest: Codable {
    let targetType: ReactionTargetType
    let targetId: UUID
    let reactionType: ReactionType
    
    enum CodingKeys: String, CodingKey {
        case targetType = "target_type"
        case targetId = "target_id"
        case reactionType = "reaction_type"
    }
}

/// Summary of reactions for display
struct ReactionSummary: Codable {
    let type: ReactionType
    let count: Int
    let hasUserReacted: Bool
    let recentUsers: [CommunityProfileSummary]
    
    enum CodingKeys: String, CodingKey {
        case type, count
        case hasUserReacted = "has_user_reacted"
        case recentUsers = "recent_users"
    }
}

