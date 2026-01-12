//
//  PrayerCircle.swift
//  Bible v1
//
//  Community Tab - Prayer Circle Model
//

import Foundation

/// A member of a prayer circle
struct PrayerCircleMember: Codable, Hashable {
    let prayerPostId: UUID
    let userId: UUID
    let prayedAt: Date
    var hasReminder: Bool
    var reminderFrequency: ReminderFrequency?
    
    // Joined data
    var user: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case prayerPostId = "prayer_post_id"
        case userId = "user_id"
        case prayedAt = "prayed_at"
        case hasReminder = "has_reminder"
        case reminderFrequency = "reminder_frequency"
        case user
    }
    
    init(
        prayerPostId: UUID,
        userId: UUID,
        prayedAt: Date = Date(),
        hasReminder: Bool = false,
        reminderFrequency: ReminderFrequency? = nil,
        user: CommunityProfileSummary? = nil
    ) {
        self.prayerPostId = prayerPostId
        self.userId = userId
        self.prayedAt = prayedAt
        self.hasReminder = hasReminder
        self.reminderFrequency = reminderFrequency
        self.user = user
    }
}

/// Reminder frequency options
enum ReminderFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
    
    var description: String {
        switch self {
        case .daily: return "Remind me every day"
        case .weekly: return "Remind me once a week"
        }
    }
}

/// Prayer circle summary for a request
struct PrayerCircle: Codable {
    let prayerPostId: UUID
    let memberCount: Int
    let recentMembers: [CommunityProfileSummary]
    let hasUserPrayed: Bool
    let userPrayedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case prayerPostId = "prayer_post_id"
        case memberCount = "member_count"
        case recentMembers = "recent_members"
        case hasUserPrayed = "has_user_prayed"
        case userPrayedAt = "user_prayed_at"
    }
}

/// Request to join a prayer circle
struct JoinPrayerCircleRequest: Codable {
    let prayerPostId: UUID
    let setReminder: Bool
    let reminderFrequency: ReminderFrequency?
    
    enum CodingKeys: String, CodingKey {
        case prayerPostId = "prayer_post_id"
        case setReminder = "set_reminder"
        case reminderFrequency = "reminder_frequency"
    }
}

