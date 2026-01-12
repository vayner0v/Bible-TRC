//
//  ProfileBadge.swift
//  Bible v1
//
//  Community Tab - Profile Badge Model
//

import Foundation
import SwiftUI

/// Types of badges users can earn
enum BadgeType: String, Codable, CaseIterable {
    case earlyAdopter = "early_adopter"
    case prayerWarrior = "prayer_warrior"
    case encourager = "encourager"
    case contributor = "contributor"
    case verseSharer = "verse_sharer"
    case groupLeader = "group_leader"
    case liveHost = "live_host"
    case mentor = "mentor"
    case faithful = "faithful"
    case anniversary = "anniversary"
    
    var displayName: String {
        switch self {
        case .earlyAdopter: return "Early Adopter"
        case .prayerWarrior: return "Prayer Warrior"
        case .encourager: return "Encourager"
        case .contributor: return "Contributor"
        case .verseSharer: return "Verse Sharer"
        case .groupLeader: return "Group Leader"
        case .liveHost: return "Live Host"
        case .mentor: return "Mentor"
        case .faithful: return "Faithful"
        case .anniversary: return "Anniversary"
        }
    }
    
    var icon: String {
        switch self {
        case .earlyAdopter: return "star.fill"
        case .prayerWarrior: return "hands.sparkles.fill"
        case .encourager: return "heart.fill"
        case .contributor: return "pencil.circle.fill"
        case .verseSharer: return "quote.bubble.fill"
        case .groupLeader: return "person.3.fill"
        case .liveHost: return "video.fill"
        case .mentor: return "graduationcap.fill"
        case .faithful: return "flame.fill"
        case .anniversary: return "gift.fill"
        }
    }
    
    var description: String {
        switch self {
        case .earlyAdopter: return "Joined during early access"
        case .prayerWarrior: return "Prayed for 100+ requests"
        case .encourager: return "Received 100+ reactions"
        case .contributor: return "Created 50+ posts"
        case .verseSharer: return "Shared 25+ verse cards"
        case .groupLeader: return "Leading a community group"
        case .liveHost: return "Hosted 10+ live rooms"
        case .mentor: return "Helped 50+ community members"
        case .faithful: return "Active for 30+ consecutive days"
        case .anniversary: return "1 year community member"
        }
    }
    
    var color: Color {
        switch self {
        case .earlyAdopter: return .yellow
        case .prayerWarrior: return .purple
        case .encourager: return .pink
        case .contributor: return .blue
        case .verseSharer: return .green
        case .groupLeader: return .orange
        case .liveHost: return .red
        case .mentor: return .indigo
        case .faithful: return .orange
        case .anniversary: return .cyan
        }
    }
}

/// A badge earned by a user
struct ProfileBadge: Identifiable, Codable, Hashable {
    let id: UUID
    let type: BadgeType
    let earnedAt: Date
    let level: Int?
    
    var displayName: String { type.displayName }
    var icon: String { type.icon }
    var description: String { type.description }
    var color: Color { type.color }
    
    enum CodingKeys: String, CodingKey {
        case id, type
        case earnedAt = "earned_at"
        case level
    }
    
    init(
        id: UUID = UUID(),
        type: BadgeType,
        earnedAt: Date = Date(),
        level: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.earnedAt = earnedAt
        self.level = level
    }
    
    /// Formatted date when badge was earned
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: earnedAt)
    }
}

