//
//  Report.swift
//  Bible v1
//
//  Community Tab - Report Model
//

import Foundation
import SwiftUI

/// A content report
struct Report: Identifiable, Codable {
    let id: UUID
    let reporterId: UUID
    let targetType: ReportTargetType
    let targetId: UUID
    let reason: ReportReason
    var description: String?
    var status: ReportStatus
    var aiFlags: [String: Any]?
    var assignedTo: UUID?
    var resolution: String?
    let createdAt: Date
    var resolvedAt: Date?
    
    // Joined data
    var reporter: CommunityProfileSummary?
    var targetPost: Post?
    var targetComment: Comment?
    var targetUser: CommunityProfileSummary?
    var targetGroup: GroupSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case reporterId = "reporter_id"
        case targetType = "target_type"
        case targetId = "target_id"
        case reason, description, status
        case aiFlags = "ai_flags"
        case assignedTo = "assigned_to"
        case resolution
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
        case reporter
        case targetPost = "target_post"
        case targetComment = "target_comment"
        case targetUser = "target_user"
        case targetGroup = "target_group"
    }
    
    init(
        id: UUID = UUID(),
        reporterId: UUID,
        targetType: ReportTargetType,
        targetId: UUID,
        reason: ReportReason,
        description: String? = nil,
        status: ReportStatus = .pending,
        aiFlags: [String: Any]? = nil,
        assignedTo: UUID? = nil,
        resolution: String? = nil,
        createdAt: Date = Date(),
        resolvedAt: Date? = nil,
        reporter: CommunityProfileSummary? = nil,
        targetPost: Post? = nil,
        targetComment: Comment? = nil,
        targetUser: CommunityProfileSummary? = nil,
        targetGroup: GroupSummary? = nil
    ) {
        self.id = id
        self.reporterId = reporterId
        self.targetType = targetType
        self.targetId = targetId
        self.reason = reason
        self.description = description
        self.status = status
        self.aiFlags = aiFlags
        self.assignedTo = assignedTo
        self.resolution = resolution
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
        self.reporter = reporter
        self.targetPost = targetPost
        self.targetComment = targetComment
        self.targetUser = targetUser
        self.targetGroup = targetGroup
    }
    
    // Custom Codable for aiFlags (Any type)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        reporterId = try container.decode(UUID.self, forKey: .reporterId)
        targetType = try container.decode(ReportTargetType.self, forKey: .targetType)
        targetId = try container.decode(UUID.self, forKey: .targetId)
        reason = try container.decode(ReportReason.self, forKey: .reason)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decode(ReportStatus.self, forKey: .status)
        aiFlags = nil // Skip decoding complex Any type
        assignedTo = try container.decodeIfPresent(UUID.self, forKey: .assignedTo)
        resolution = try container.decodeIfPresent(String.self, forKey: .resolution)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        resolvedAt = try container.decodeIfPresent(Date.self, forKey: .resolvedAt)
        reporter = try container.decodeIfPresent(CommunityProfileSummary.self, forKey: .reporter)
        targetPost = try container.decodeIfPresent(Post.self, forKey: .targetPost)
        targetComment = try container.decodeIfPresent(Comment.self, forKey: .targetComment)
        targetUser = try container.decodeIfPresent(CommunityProfileSummary.self, forKey: .targetUser)
        targetGroup = try container.decodeIfPresent(GroupSummary.self, forKey: .targetGroup)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reporterId, forKey: .reporterId)
        try container.encode(targetType, forKey: .targetType)
        try container.encode(targetId, forKey: .targetId)
        try container.encode(reason, forKey: .reason)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(status, forKey: .status)
        // Skip encoding aiFlags
        try container.encodeIfPresent(assignedTo, forKey: .assignedTo)
        try container.encodeIfPresent(resolution, forKey: .resolution)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(resolvedAt, forKey: .resolvedAt)
    }
    
    /// Check if report is pending
    var isPending: Bool {
        status == .pending
    }
    
    /// Check if report is resolved
    var isResolved: Bool {
        status == .resolved || status == .dismissed
    }
}

/// Target types for reports
enum ReportTargetType: String, Codable, CaseIterable {
    case post = "post"
    case comment = "comment"
    case user = "user"
    case group = "group"
    case room = "room"
    case message = "message"
    
    var displayName: String {
        switch self {
        case .post: return "Post"
        case .comment: return "Comment"
        case .user: return "User"
        case .group: return "Group"
        case .room: return "Live Room"
        case .message: return "Message"
        }
    }
}

/// Reasons for reporting
enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case spam = "spam"
    case harassment = "harassment"
    case hate = "hate"
    case misinformation = "misinformation"
    case selfHarm = "self_harm"
    case inappropriate = "inappropriate"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .hate: return "Hate Speech"
        case .misinformation: return "Misinformation"
        case .selfHarm: return "Self-Harm Content"
        case .inappropriate: return "Inappropriate Content"
        case .other: return "Other"
        }
    }
    
    var description: String {
        switch self {
        case .spam: return "Unwanted commercial content or repetitive posts"
        case .harassment: return "Bullying, threats, or targeted harassment"
        case .hate: return "Content promoting hatred against groups"
        case .misinformation: return "False or misleading information"
        case .selfHarm: return "Content promoting self-harm or suicide"
        case .inappropriate: return "Content not appropriate for this community"
        case .other: return "Something else not listed above"
        }
    }
    
    var icon: String {
        switch self {
        case .spam: return "envelope.badge.fill"
        case .harassment: return "exclamationmark.bubble.fill"
        case .hate: return "hand.raised.slash.fill"
        case .misinformation: return "exclamationmark.triangle.fill"
        case .selfHarm: return "heart.slash.fill"
        case .inappropriate: return "eye.slash.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .spam: return .gray
        case .harassment: return .orange
        case .hate: return .red
        case .misinformation: return .yellow
        case .selfHarm: return .red
        case .inappropriate: return .purple
        case .other: return .blue
        }
    }
    
    /// Priority for moderation queue (lower = higher priority)
    var priority: Int {
        switch self {
        case .selfHarm: return 1
        case .hate: return 2
        case .harassment: return 3
        case .misinformation: return 4
        case .inappropriate: return 5
        case .spam: return 6
        case .other: return 7
        }
    }
}

/// Status of a report
enum ReportStatus: String, Codable {
    case pending = "pending"
    case reviewing = "reviewing"
    case resolved = "resolved"
    case dismissed = "dismissed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .reviewing: return "Under Review"
        case .resolved: return "Resolved"
        case .dismissed: return "Dismissed"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .reviewing: return .blue
        case .resolved: return .green
        case .dismissed: return .gray
        }
    }
}

/// Request to create a report
struct CreateReportRequest: Codable {
    let targetType: ReportTargetType
    let targetId: UUID
    let reason: ReportReason
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case targetType = "target_type"
        case targetId = "target_id"
        case reason, description
    }
}

