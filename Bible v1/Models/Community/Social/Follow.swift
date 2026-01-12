//
//  Follow.swift
//  Bible v1
//
//  Community Tab - Follow Relationship Model
//

import Foundation

/// State of a follow relationship
enum FollowState: String, Codable {
    case active = "active"
    case pending = "pending"
    case blocked = "blocked"
}

/// A follow relationship between users
struct Follow: Codable, Hashable {
    let followerId: UUID
    let followeeId: UUID
    let state: FollowState
    let createdAt: Date
    
    // Joined data
    var follower: CommunityProfileSummary?
    var followee: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followeeId = "followee_id"
        case state
        case createdAt = "created_at"
        case follower, followee
    }
    
    init(
        followerId: UUID,
        followeeId: UUID,
        state: FollowState = .active,
        createdAt: Date = Date(),
        follower: CommunityProfileSummary? = nil,
        followee: CommunityProfileSummary? = nil
    ) {
        self.followerId = followerId
        self.followeeId = followeeId
        self.state = state
        self.createdAt = createdAt
        self.follower = follower
        self.followee = followee
    }
}

/// Follow status between current user and another user
struct FollowStatus: Codable {
    let isFollowing: Bool
    let isFollowedBy: Bool
    let isPending: Bool
    let isBlocked: Bool
    
    enum CodingKeys: String, CodingKey {
        case isFollowing = "is_following"
        case isFollowedBy = "is_followed_by"
        case isPending = "is_pending"
        case isBlocked = "is_blocked"
    }
    
    static let notFollowing = FollowStatus(
        isFollowing: false,
        isFollowedBy: false,
        isPending: false,
        isBlocked: false
    )
    
    /// Check if mutual follows
    var isMutual: Bool {
        isFollowing && isFollowedBy
    }
}

/// Follower/following list item
struct FollowListItem: Identifiable, Codable {
    let id: UUID
    let profile: CommunityProfileSummary
    let followStatus: FollowStatus
    let followedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, profile
        case followStatus = "follow_status"
        case followedAt = "followed_at"
    }
}

