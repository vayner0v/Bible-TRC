//
//  GroupMember.swift
//  Bible v1
//
//  Community Tab - Group Member Model
//

import Foundation
import SwiftUI

/// A member of a group
struct GroupMember: Codable, Hashable {
    let groupId: UUID
    let userId: UUID
    var role: GroupRole
    let joinedAt: Date
    var joinAnswers: [String: String]?
    var isMuted: Bool
    
    // Joined data
    var user: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case joinAnswers = "join_answers"
        case isMuted = "is_muted"
        case user
    }
    
    init(
        groupId: UUID,
        userId: UUID,
        role: GroupRole = .member,
        joinedAt: Date = Date(),
        joinAnswers: [String: String]? = nil,
        isMuted: Bool = false,
        user: CommunityProfileSummary? = nil
    ) {
        self.groupId = groupId
        self.userId = userId
        self.role = role
        self.joinedAt = joinedAt
        self.joinAnswers = joinAnswers
        self.isMuted = isMuted
        self.user = user
    }
}

/// Roles within a group
enum GroupRole: String, Codable, CaseIterable {
    case owner = "owner"
    case moderator = "moderator"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .moderator: return "Moderator"
        case .member: return "Member"
        }
    }
    
    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .moderator: return "shield.fill"
        case .member: return "person.fill"
        }
    }
    
    var roleColor: Color {
        switch self {
        case .owner: return .orange
        case .moderator: return .purple
        case .member: return .gray
        }
    }
    
    /// Permissions for this role
    var permissions: GroupPermissions {
        switch self {
        case .owner:
            return GroupPermissions(
                canPost: true,
                canComment: true,
                canDeletePosts: true,
                canDeleteComments: true,
                canBanMembers: true,
                canPromoteMembers: true,
                canEditGroup: true,
                canDeleteGroup: true,
                canCreateEvents: true,
                canStartLiveRooms: true
            )
        case .moderator:
            return GroupPermissions(
                canPost: true,
                canComment: true,
                canDeletePosts: true,
                canDeleteComments: true,
                canBanMembers: true,
                canPromoteMembers: false,
                canEditGroup: false,
                canDeleteGroup: false,
                canCreateEvents: true,
                canStartLiveRooms: true
            )
        case .member:
            return GroupPermissions(
                canPost: true,
                canComment: true,
                canDeletePosts: false,
                canDeleteComments: false,
                canBanMembers: false,
                canPromoteMembers: false,
                canEditGroup: false,
                canDeleteGroup: false,
                canCreateEvents: false,
                canStartLiveRooms: false
            )
        }
    }
}

/// Permissions within a group
struct GroupPermissions {
    let canPost: Bool
    let canComment: Bool
    let canDeletePosts: Bool
    let canDeleteComments: Bool
    let canBanMembers: Bool
    let canPromoteMembers: Bool
    let canEditGroup: Bool
    let canDeleteGroup: Bool
    let canCreateEvents: Bool
    let canStartLiveRooms: Bool
}

/// Request to join a group
struct JoinGroupRequest: Codable {
    let groupId: UUID
    let answers: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case answers
    }
}

/// Pending join request
struct GroupJoinRequest: Identifiable, Codable {
    let id: UUID
    let groupId: UUID
    let userId: UUID
    let answers: [String: String]?
    let status: JoinRequestStatus
    let createdAt: Date
    var reviewedAt: Date?
    var reviewedBy: UUID?
    
    // Joined data
    var user: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case answers, status
        case createdAt = "created_at"
        case reviewedAt = "reviewed_at"
        case reviewedBy = "reviewed_by"
        case user
    }
}

/// Status of a join request
enum JoinRequestStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

