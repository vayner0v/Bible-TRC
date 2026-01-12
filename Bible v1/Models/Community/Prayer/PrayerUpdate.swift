//
//  PrayerUpdate.swift
//  Bible v1
//
//  Community Tab - Prayer Update Model
//

import Foundation
import SwiftUI

/// An update on a prayer request
struct PrayerUpdate: Identifiable, Codable {
    let id: UUID
    let prayerPostId: UUID
    let authorId: UUID
    var content: String
    let updateType: PrayerUpdateType
    let createdAt: Date
    
    // Joined data
    var author: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case prayerPostId = "prayer_post_id"
        case authorId = "author_id"
        case content
        case updateType = "update_type"
        case createdAt = "created_at"
        case author
    }
    
    init(
        id: UUID = UUID(),
        prayerPostId: UUID,
        authorId: UUID,
        content: String,
        updateType: PrayerUpdateType,
        createdAt: Date = Date(),
        author: CommunityProfileSummary? = nil
    ) {
        self.id = id
        self.prayerPostId = prayerPostId
        self.authorId = authorId
        self.content = content
        self.updateType = updateType
        self.createdAt = createdAt
        self.author = author
    }
    
    /// Relative time since creation
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

/// Types of prayer updates
enum PrayerUpdateType: String, Codable, CaseIterable {
    case update = "update"
    case answered = "answered"
    case continued = "continued"
    
    var displayName: String {
        switch self {
        case .update: return "Update"
        case .answered: return "Answered!"
        case .continued: return "Still Praying"
        }
    }
    
    var icon: String {
        switch self {
        case .update: return "arrow.clockwise"
        case .answered: return "checkmark.circle.fill"
        case .continued: return "clock.arrow.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .update: return .blue
        case .answered: return .green
        case .continued: return .orange
        }
    }
}

/// Request to add a prayer update
struct CreatePrayerUpdateRequest: Codable {
    let prayerPostId: UUID
    let content: String
    let updateType: PrayerUpdateType
    
    enum CodingKeys: String, CodingKey {
        case prayerPostId = "prayer_post_id"
        case content
        case updateType = "update_type"
    }
}

