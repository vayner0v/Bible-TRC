//
//  ModerationAction.swift
//  Bible v1
//
//  Community Tab - Moderation Action Model
//

import Foundation
import SwiftUI

/// A moderation action taken
struct ModerationAction: Identifiable, Codable {
    let id: UUID
    let moderatorId: UUID?
    let targetType: ReportTargetType
    let targetId: UUID
    let action: ModerationActionType
    var reason: String?
    var durationHours: Int?
    let createdAt: Date
    
    // Joined data
    var moderator: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case moderatorId = "moderator_id"
        case targetType = "target_type"
        case targetId = "target_id"
        case action, reason
        case durationHours = "duration_hours"
        case createdAt = "created_at"
        case moderator
    }
    
    init(
        id: UUID = UUID(),
        moderatorId: UUID? = nil,
        targetType: ReportTargetType,
        targetId: UUID,
        action: ModerationActionType,
        reason: String? = nil,
        durationHours: Int? = nil,
        createdAt: Date = Date(),
        moderator: CommunityProfileSummary? = nil
    ) {
        self.id = id
        self.moderatorId = moderatorId
        self.targetType = targetType
        self.targetId = targetId
        self.action = action
        self.reason = reason
        self.durationHours = durationHours
        self.createdAt = createdAt
        self.moderator = moderator
    }
    
    /// Expiration date for temporary actions
    var expiresAt: Date? {
        guard let hours = durationHours else { return nil }
        return Calendar.current.date(byAdding: .hour, value: hours, to: createdAt)
    }
    
    /// Check if action is still in effect
    var isActive: Bool {
        if let expiresAt = expiresAt {
            return expiresAt > Date()
        }
        return true
    }
}

/// Types of moderation actions
enum ModerationActionType: String, Codable, CaseIterable {
    case warn = "warn"
    case mute = "mute"
    case ban = "ban"
    case delete = "delete"
    case restore = "restore"
    
    var displayName: String {
        switch self {
        case .warn: return "Warning"
        case .mute: return "Mute"
        case .ban: return "Ban"
        case .delete: return "Delete"
        case .restore: return "Restore"
        }
    }
    
    var description: String {
        switch self {
        case .warn: return "Send a warning to the user"
        case .mute: return "Temporarily prevent user from posting"
        case .ban: return "Remove user from community"
        case .delete: return "Remove the content"
        case .restore: return "Restore previously removed content"
        }
    }
    
    var icon: String {
        switch self {
        case .warn: return "exclamationmark.triangle.fill"
        case .mute: return "speaker.slash.fill"
        case .ban: return "xmark.circle.fill"
        case .delete: return "trash.fill"
        case .restore: return "arrow.uturn.backward.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .warn: return .yellow
        case .mute: return .orange
        case .ban: return .red
        case .delete: return .red
        case .restore: return .green
        }
    }
    
    /// Whether this action is reversible
    var isReversible: Bool {
        switch self {
        case .warn, .mute, .ban, .delete: return true
        case .restore: return false
        }
    }
}

/// User ban record
struct UserBan: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let bannedBy: UUID?
    var reason: String?
    var isPermanent: Bool
    var expiresAt: Date?
    let createdAt: Date
    
    // Joined data
    var user: CommunityProfileSummary?
    var banner: CommunityProfileSummary?
    
    var isActive: Bool {
        if isPermanent { return true }
        if let expiresAt = expiresAt {
            return expiresAt > Date()
        }
        return true
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case bannedBy = "banned_by"
        case reason
        case isPermanent = "is_permanent"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case user, banner
    }
}

/// Keyword filter for content moderation
struct KeywordFilter: Identifiable, Codable {
    let id: UUID
    var pattern: String
    var action: FilterAction
    var isRegex: Bool
    var category: FilterCategory
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, pattern, action
        case isRegex = "is_regex"
        case category
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        pattern: String,
        action: FilterAction = .flag,
        isRegex: Bool = false,
        category: FilterCategory,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.pattern = pattern
        self.action = action
        self.isRegex = isRegex
        self.category = category
        self.createdAt = createdAt
    }
}

/// Actions for keyword filters
enum FilterAction: String, Codable {
    case flag = "flag"
    case block = "block"
    case requireReview = "require_review"
    
    var displayName: String {
        switch self {
        case .flag: return "Flag for Review"
        case .block: return "Block Content"
        case .requireReview: return "Require Approval"
        }
    }
}

/// Categories for keyword filters
enum FilterCategory: String, Codable, CaseIterable {
    case spam = "spam"
    case profanity = "profanity"
    case political = "political"
    case crisis = "crisis"
    
    var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .profanity: return "Profanity"
        case .political: return "Political"
        case .crisis: return "Crisis Keywords"
        }
    }
    
    var color: Color {
        switch self {
        case .spam: return .gray
        case .profanity: return .orange
        case .political: return .blue
        case .crisis: return .red
        }
    }
}

