//
//  Block.swift
//  Bible v1
//
//  Community Tab - Block Relationship Model
//

import Foundation

/// A block relationship between users
struct Block: Codable, Hashable {
    let blockerId: UUID
    let blockedId: UUID
    let createdAt: Date
    
    // Joined data
    var blocked: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case blockerId = "blocker_id"
        case blockedId = "blocked_id"
        case createdAt = "created_at"
        case blocked
    }
    
    init(
        blockerId: UUID,
        blockedId: UUID,
        createdAt: Date = Date(),
        blocked: CommunityProfileSummary? = nil
    ) {
        self.blockerId = blockerId
        self.blockedId = blockedId
        self.createdAt = createdAt
        self.blocked = blocked
    }
}

/// A mute relationship
struct Mute: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let mutedId: UUID
    let muteType: MuteType
    let expiresAt: Date?
    let createdAt: Date
    
    // Joined data
    var mutedUser: CommunityProfileSummary?
    var mutedGroup: CommunityGroup?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mutedId = "muted_id"
        case muteType = "mute_type"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case mutedUser = "muted_user"
        case mutedGroup = "muted_group"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        mutedId: UUID,
        muteType: MuteType,
        expiresAt: Date? = nil,
        createdAt: Date = Date(),
        mutedUser: CommunityProfileSummary? = nil,
        mutedGroup: CommunityGroup? = nil
    ) {
        self.id = id
        self.userId = userId
        self.mutedId = mutedId
        self.muteType = muteType
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.mutedUser = mutedUser
        self.mutedGroup = mutedGroup
    }
    
    /// Check if mute is still active
    var isActive: Bool {
        if let expiresAt = expiresAt {
            return expiresAt > Date()
        }
        return true
    }
}

/// Types of mutes
enum MuteType: String, Codable {
    case user = "user"
    case group = "group"
    case topic = "topic"
    
    var displayName: String {
        switch self {
        case .user: return "User"
        case .group: return "Group"
        case .topic: return "Topic"
        }
    }
}

/// Mute duration options
enum MuteDuration: CaseIterable {
    case oneHour
    case oneDay
    case oneWeek
    case oneMonth
    case forever
    
    var displayName: String {
        switch self {
        case .oneHour: return "1 hour"
        case .oneDay: return "1 day"
        case .oneWeek: return "1 week"
        case .oneMonth: return "1 month"
        case .forever: return "Forever"
        }
    }
    
    var expiresAt: Date? {
        let calendar = Calendar.current
        switch self {
        case .oneHour: return calendar.date(byAdding: .hour, value: 1, to: Date())
        case .oneDay: return calendar.date(byAdding: .day, value: 1, to: Date())
        case .oneWeek: return calendar.date(byAdding: .weekOfYear, value: 1, to: Date())
        case .oneMonth: return calendar.date(byAdding: .month, value: 1, to: Date())
        case .forever: return nil
        }
    }
}

