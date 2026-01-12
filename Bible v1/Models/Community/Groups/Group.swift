//
//  Group.swift
//  Bible v1
//
//  Community Tab - Group Model
//

import Foundation

/// A community group
struct CommunityGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    let type: GroupType
    var privacy: GroupPrivacy
    var avatarUrl: String?
    var coverUrl: String?
    var rules: [String]
    var joinQuestions: [String]
    var linkedReadingPlanId: UUID?
    var churchVerificationStatus: VerificationRequestStatus?
    var memberCount: Int
    var postCount: Int
    var weeklyPrompt: String?
    var settings: GroupSettings
    let createdBy: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    // Joined data
    var creator: CommunityProfileSummary?
    var userMembership: GroupMember?
    var recentMembers: [CommunityProfileSummary]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, privacy
        case avatarUrl = "avatar_url"
        case coverUrl = "cover_url"
        case rules
        case joinQuestions = "join_questions"
        case linkedReadingPlanId = "linked_reading_plan_id"
        case churchVerificationStatus = "church_verification_status"
        case memberCount = "member_count"
        case postCount = "post_count"
        case weeklyPrompt = "weekly_prompt"
        case settings
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case creator
        case userMembership = "user_membership"
        case recentMembers = "recent_members"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        type: GroupType,
        privacy: GroupPrivacy = .public,
        avatarUrl: String? = nil,
        coverUrl: String? = nil,
        rules: [String] = [],
        joinQuestions: [String] = [],
        linkedReadingPlanId: UUID? = nil,
        churchVerificationStatus: VerificationRequestStatus? = nil,
        memberCount: Int = 0,
        postCount: Int = 0,
        weeklyPrompt: String? = nil,
        settings: GroupSettings = .default,
        createdBy: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        creator: CommunityProfileSummary? = nil,
        userMembership: GroupMember? = nil,
        recentMembers: [CommunityProfileSummary]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.privacy = privacy
        self.avatarUrl = avatarUrl
        self.coverUrl = coverUrl
        self.rules = rules
        self.joinQuestions = joinQuestions
        self.linkedReadingPlanId = linkedReadingPlanId
        self.churchVerificationStatus = churchVerificationStatus
        self.memberCount = memberCount
        self.postCount = postCount
        self.weeklyPrompt = weeklyPrompt
        self.settings = settings
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.creator = creator
        self.userMembership = userMembership
        self.recentMembers = recentMembers
    }
    
    /// Check if user is a member
    var isMember: Bool {
        userMembership != nil
    }
    
    /// Check if user is owner or moderator
    var canModerate: Bool {
        guard let membership = userMembership else { return false }
        return membership.role == .owner || membership.role == .moderator
    }
    
    /// Check if user is owner
    var isOwner: Bool {
        userMembership?.role == .owner
    }
    
    /// Check if group requires approval to join
    var requiresApproval: Bool {
        privacy == .private && !joinQuestions.isEmpty
    }
    
    /// Check if group is verified church
    var isVerifiedChurch: Bool {
        type == .church && churchVerificationStatus == .approved
    }
}

/// Group settings
struct GroupSettings: Codable, Hashable {
    var allowMemberPosts: Bool
    var requirePostApproval: Bool
    var allowAnonymousPosts: Bool
    var allowEvents: Bool
    var allowLiveRooms: Bool
    var notifyOnNewPosts: Bool
    var notifyOnEvents: Bool
    
    static let `default` = GroupSettings(
        allowMemberPosts: true,
        requirePostApproval: false,
        allowAnonymousPosts: true,
        allowEvents: true,
        allowLiveRooms: true,
        notifyOnNewPosts: true,
        notifyOnEvents: true
    )
    
    enum CodingKeys: String, CodingKey {
        case allowMemberPosts = "allow_member_posts"
        case requirePostApproval = "require_post_approval"
        case allowAnonymousPosts = "allow_anonymous_posts"
        case allowEvents = "allow_events"
        case allowLiveRooms = "allow_live_rooms"
        case notifyOnNewPosts = "notify_on_new_posts"
        case notifyOnEvents = "notify_on_events"
    }
}

/// Request to create a group
struct CreateGroupRequest: Codable {
    let name: String
    let description: String?
    let type: GroupType
    let privacy: GroupPrivacy
    let rules: [String]
    let joinQuestions: [String]
    let linkedReadingPlanId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case name, description, type, privacy, rules
        case joinQuestions = "join_questions"
        case linkedReadingPlanId = "linked_reading_plan_id"
    }
}

/// Group summary for lists
struct GroupSummary: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let type: GroupType
    let privacy: GroupPrivacy
    let avatarUrl: String?
    let memberCount: Int
    let isMember: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, privacy
        case avatarUrl = "avatar_url"
        case memberCount = "member_count"
        case isMember = "is_member"
    }
}

