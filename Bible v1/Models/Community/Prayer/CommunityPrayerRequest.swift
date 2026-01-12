//
//  CommunityPrayerRequest.swift
//  Bible v1
//
//  Community Tab - Community Prayer Request Model
//

import Foundation
import SwiftUI

/// Prayer urgency levels
enum CommunityPrayerUrgency: String, Codable, CaseIterable {
    case urgent = "urgent"
    case normal = "normal"
    
    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .normal: return "Normal"
        }
    }
    
    var icon: String {
        switch self {
        case .urgent: return "exclamationmark.circle.fill"
        case .normal: return "clock"
        }
    }
    
    var color: Color {
        switch self {
        case .urgent: return .red
        case .normal: return .blue
        }
    }
}

/// Community prayer request (extends a post)
struct CommunityPrayerRequest: Identifiable, Codable {
    let postId: UUID
    var category: CommunityPrayerCategory
    var urgency: CommunityPrayerUrgency
    var durationDays: Int
    var expiresAt: Date?
    var isAnswered: Bool
    var answeredAt: Date?
    var answeredNote: String?
    var prayerCount: Int
    let createdAt: Date
    
    // Joined data from posts table
    var post: Post?
    var prayerCircle: [CommunityProfileSummary]?
    
    var id: UUID { postId }
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category, urgency
        case durationDays = "duration_days"
        case expiresAt = "expires_at"
        case isAnswered = "is_answered"
        case answeredAt = "answered_at"
        case answeredNote = "answered_note"
        case prayerCount = "prayer_count"
        case createdAt = "created_at"
        case post
        case prayerCircle = "prayer_circle"
    }
    
    init(
        postId: UUID,
        category: CommunityPrayerCategory = .other,
        urgency: CommunityPrayerUrgency = .normal,
        durationDays: Int = 7,
        expiresAt: Date? = nil,
        isAnswered: Bool = false,
        answeredAt: Date? = nil,
        answeredNote: String? = nil,
        prayerCount: Int = 0,
        createdAt: Date = Date(),
        post: Post? = nil,
        prayerCircle: [CommunityProfileSummary]? = nil
    ) {
        self.postId = postId
        self.category = category
        self.urgency = urgency
        self.durationDays = durationDays
        self.expiresAt = expiresAt
        self.isAnswered = isAnswered
        self.answeredAt = answeredAt
        self.answeredNote = answeredNote
        self.prayerCount = prayerCount
        self.createdAt = createdAt
        self.post = post
        self.prayerCircle = prayerCircle
    }
    
    /// Check if prayer request is still active
    var isActive: Bool {
        if isAnswered { return false }
        if let expiresAt = expiresAt, expiresAt < Date() { return false }
        return true
    }
    
    /// Check if prayer request is expired
    var isExpired: Bool {
        if let expiresAt = expiresAt {
            return expiresAt < Date()
        }
        return false
    }
    
    /// Days remaining
    var daysRemaining: Int? {
        guard let expiresAt = expiresAt else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        return max(0, days)
    }
    
    /// Days since created
    var daysSinceCreated: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
}

/// Categories for community prayers
enum CommunityPrayerCategory: String, Codable, CaseIterable, Identifiable {
    case health = "health"
    case family = "family"
    case work = "work"
    case anxiety = "anxiety"
    case finances = "finances"
    case relationships = "relationships"
    case spiritual = "spiritual"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .family: return "Family"
        case .work: return "Work"
        case .anxiety: return "Anxiety"
        case .finances: return "Finances"
        case .relationships: return "Relationships"
        case .spiritual: return "Spiritual"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "cross.case.fill"
        case .family: return "house.fill"
        case .work: return "briefcase.fill"
        case .anxiety: return "cloud.sun.fill"
        case .finances: return "dollarsign.circle.fill"
        case .relationships: return "person.2.fill"
        case .spiritual: return "sparkles"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .health: return .green
        case .family: return .orange
        case .work: return .brown
        case .anxiety: return .teal
        case .finances: return .green
        case .relationships: return .red
        case .spiritual: return .purple
        case .other: return .gray
        }
    }
}

