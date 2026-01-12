//
//  CommunityModerationService.swift
//  Bible v1
//
//  Community Tab - Moderation Service
//

import Foundation
import Supabase

/// Service for community content moderation
@MainActor
final class CommunityModerationService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    /// Crisis keywords to detect
    private let crisisKeywords = [
        "suicide", "kill myself", "end my life", "want to die",
        "self harm", "hurt myself", "cutting", "no reason to live"
    ]
    
    /// Crisis hotline numbers by region
    private let crisisHotlines: [String: String] = [
        "US": "988",
        "UK": "116 123",
        "CA": "1-833-456-4566",
        "AU": "13 11 14",
        "default": "988"
    ]
    
    // MARK: - Reporting
    
    /// Create a report
    func createReport(_ request: CreateReportRequest, reporterId: UUID) async throws {
        let report = Report(
            reporterId: reporterId,
            targetType: request.targetType,
            targetId: request.targetId,
            reason: request.reason,
            description: request.description
        )
        
        try await supabase
            .from("reports")
            .insert(report)
            .execute()
    }
    
    /// Get reports (for moderators)
    func getReports(status: ReportStatus? = nil, offset: Int = 0, limit: Int = 50) async throws -> [Report] {
        var query = supabase
            .from("reports")
            .select("*, reporter:community_profiles!reporter_id(*)")
        
        if let status = status {
            query = query.eq("status", value: status.rawValue)
        }
        
        let reports: [Report] = try await query
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return reports
    }
    
    /// Update report status
    func updateReportStatus(reportId: UUID, status: ReportStatus, resolution: String?) async throws {
        var updates: [String: AnyEncodable] = [
            "status": AnyEncodable(status.rawValue)
        ]
        
        if status == .resolved || status == .dismissed {
            updates["resolved_at"] = AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        }
        
        if let resolution = resolution {
            updates["resolution"] = AnyEncodable(resolution)
        }
        
        try await supabase
            .from("reports")
            .update(updates)
            .eq("id", value: reportId.uuidString)
            .execute()
    }
    
    // MARK: - Content Filtering
    
    /// Check content for violations
    func checkContent(_ content: String) -> ContentCheckResult {
        let lowercased = content.lowercased()
        
        // Check for crisis keywords
        for keyword in crisisKeywords {
            if lowercased.contains(keyword) {
                return ContentCheckResult(
                    isAllowed: true, // Still allow, but flag
                    requiresReview: true,
                    isCrisis: true,
                    hotlineNumber: crisisHotlines["default"],
                    flaggedKeywords: [keyword]
                )
            }
        }
        
        // Check for external links (for new accounts)
        let urlPattern = #"https?://[^\s]+"#
        if let regex = try? NSRegularExpression(pattern: urlPattern),
           regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil {
            return ContentCheckResult(
                isAllowed: false,
                requiresReview: false,
                isCrisis: false,
                reason: "External links are restricted for new accounts"
            )
        }
        
        return ContentCheckResult(isAllowed: true)
    }
    
    /// Get keyword filters
    func getKeywordFilters(category: FilterCategory? = nil) async throws -> [KeywordFilter] {
        var query = supabase
            .from("keyword_filters")
            .select()
        
        if let category = category {
            query = query.eq("category", value: category.rawValue)
        }
        
        let filters: [KeywordFilter] = try await query.execute().value
        
        return filters
    }
    
    /// Add keyword filter
    func addKeywordFilter(pattern: String, action: FilterAction, category: FilterCategory, isRegex: Bool = false) async throws {
        let filter = KeywordFilter(
            pattern: pattern,
            action: action,
            isRegex: isRegex,
            category: category
        )
        
        try await supabase
            .from("keyword_filters")
            .insert(filter)
            .execute()
    }
    
    /// Remove keyword filter
    func removeKeywordFilter(id: UUID) async throws {
        try await supabase
            .from("keyword_filters")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Moderation Actions
    
    /// Take moderation action
    func takeAction(
        action: ModerationActionType,
        targetType: ReportTargetType,
        targetId: UUID,
        reason: String?,
        durationHours: Int? = nil,
        moderatorId: UUID
    ) async throws {
        // Record action
        let moderationAction = ModerationAction(
            moderatorId: moderatorId,
            targetType: targetType,
            targetId: targetId,
            action: action,
            reason: reason,
            durationHours: durationHours
        )
        
        try await supabase
            .from("moderation_actions")
            .insert(moderationAction)
            .execute()
        
        // Execute action
        switch action {
        case .delete:
            try await deleteContent(type: targetType, id: targetId)
        case .ban:
            if targetType == .user {
                try await banUser(userId: targetId, isPermanent: durationHours == nil, durationHours: durationHours, reason: reason, bannedBy: moderatorId)
            }
        case .mute:
            if targetType == .user {
                try await muteUser(userId: targetId, durationHours: durationHours ?? 24)
            }
        case .warn:
            // Send warning notification
            try await sendWarning(userId: targetId, reason: reason)
        case .restore:
            try await restoreContent(type: targetType, id: targetId)
        }
    }
    
    /// Get moderation actions for a target
    func getActions(targetType: ReportTargetType, targetId: UUID) async throws -> [ModerationAction] {
        let actions: [ModerationAction] = try await supabase
            .from("moderation_actions")
            .select("*, moderator:community_profiles!moderator_id(*)")
            .eq("target_type", value: targetType.rawValue)
            .eq("target_id", value: targetId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return actions
    }
    
    // MARK: - User Bans
    
    /// Ban a user
    func banUser(userId: UUID, isPermanent: Bool, durationHours: Int?, reason: String?, bannedBy: UUID) async throws {
        let expiresAt: Date?
        if !isPermanent, let hours = durationHours {
            expiresAt = Calendar.current.date(byAdding: .hour, value: hours, to: Date())
        } else {
            expiresAt = nil
        }
        
        let ban = UserBan(
            id: userId,
            userId: userId,
            bannedBy: bannedBy,
            reason: reason,
            isPermanent: isPermanent,
            expiresAt: expiresAt,
            createdAt: Date()
        )
        
        try await supabase
            .from("user_bans")
            .upsert(ban, onConflict: "user_id")
            .execute()
    }
    
    /// Unban a user
    func unbanUser(userId: UUID) async throws {
        try await supabase
            .from("user_bans")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Check if user is banned
    func isUserBanned(userId: UUID) async throws -> Bool {
        let bans: [UserBan] = try await supabase
            .from("user_bans")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        guard let ban = bans.first else { return false }
        
        return ban.isActive
    }
    
    // MARK: - Private Methods
    
    private func deleteContent(type: ReportTargetType, id: UUID) async throws {
        let tableName: String
        switch type {
        case .post: tableName = "posts"
        case .comment: tableName = "comments"
        case .message: tableName = "messages"
        default: return
        }
        
        try await supabase
            .from(tableName)
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    private func restoreContent(type: ReportTargetType, id: UUID) async throws {
        let tableName: String
        switch type {
        case .post: tableName = "posts"
        case .comment: tableName = "comments"
        case .message: tableName = "messages"
        default: return
        }
        
        // Use AnyEncodable wrapper to handle null
        try await supabase
            .from(tableName)
            .update(["deleted_at": AnyEncodable(Optional<String>.none)])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    private func muteUser(userId: UUID, durationHours: Int) async throws {
        // Implement user mute (prevent posting for duration)
        // This would typically set a flag on the user profile
        let expiresAt = Calendar.current.date(byAdding: .hour, value: durationHours, to: Date())
        
        let muteSettings = MuteSettings(
            isMuted: true,
            muteExpiresAt: ISO8601DateFormatter().string(from: expiresAt!)
        )
        
        try await supabase
            .from("community_profiles")
            .update(["privacy_settings": AnyEncodable(muteSettings)])
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    private func sendWarning(userId: UUID, reason: String?) async throws {
        // Create a notification for the user
        let notification = WarningNotification(
            id: UUID(),
            userId: userId,
            type: "warning",
            title: "Community Guidelines Warning",
            body: reason ?? "Your recent content has been flagged for review.",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("community_notifications")
            .insert(notification)
            .execute()
    }
}

// MARK: - Helper Structs for Encoding

private struct MuteSettings: Encodable {
    let isMuted: Bool
    let muteExpiresAt: String
    
    enum CodingKeys: String, CodingKey {
        case isMuted = "is_muted"
        case muteExpiresAt = "mute_expires_at"
    }
}

private struct WarningNotification: Encodable {
    let id: UUID
    let userId: UUID
    let type: String
    let title: String
    let body: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type, title, body
        case createdAt = "created_at"
    }
}

// MARK: - Supporting Types

/// Result of content check
struct ContentCheckResult {
    let isAllowed: Bool
    var requiresReview: Bool = false
    var isCrisis: Bool = false
    var hotlineNumber: String? = nil
    var flaggedKeywords: [String] = []
    var reason: String? = nil
}

