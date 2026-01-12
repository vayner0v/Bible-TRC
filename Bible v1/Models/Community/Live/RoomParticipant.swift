//
//  RoomParticipant.swift
//  Bible v1
//
//  Community Tab - Room Participant Model
//

import Foundation
import SwiftUI

/// A participant in a live room
struct RoomParticipant: Codable, Hashable {
    let roomId: UUID
    let userId: UUID
    var role: RoomRole
    let joinedAt: Date
    var leftAt: Date?
    var isMuted: Bool
    var hasRaisedHand: Bool
    
    // Joined data
    var user: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case leftAt = "left_at"
        case isMuted = "is_muted"
        case hasRaisedHand = "has_raised_hand"
        case user
    }
    
    init(
        roomId: UUID,
        userId: UUID,
        role: RoomRole = .listener,
        joinedAt: Date = Date(),
        leftAt: Date? = nil,
        isMuted: Bool = true,
        hasRaisedHand: Bool = false,
        user: CommunityProfileSummary? = nil
    ) {
        self.roomId = roomId
        self.userId = userId
        self.role = role
        self.joinedAt = joinedAt
        self.leftAt = leftAt
        self.isMuted = isMuted
        self.hasRaisedHand = hasRaisedHand
        self.user = user
    }
    
    /// Check if participant is currently in the room
    var isActive: Bool {
        leftAt == nil
    }
    
    /// Check if participant can speak
    var canSpeak: Bool {
        role == .host || role == .coHost || role == .speaker
    }
    
    /// Check if participant can moderate
    var canModerate: Bool {
        role == .host || role == .coHost
    }
    
    /// Duration in room
    var duration: TimeInterval {
        let endTime = leftAt ?? Date()
        return endTime.timeIntervalSince(joinedAt)
    }
}

/// Roles in a live room
enum RoomRole: String, Codable, CaseIterable {
    case host = "host"
    case coHost = "co_host"
    case speaker = "speaker"
    case listener = "listener"
    
    var displayName: String {
        switch self {
        case .host: return "Host"
        case .coHost: return "Co-Host"
        case .speaker: return "Speaker"
        case .listener: return "Listener"
        }
    }
    
    var icon: String {
        switch self {
        case .host: return "crown.fill"
        case .coHost: return "person.badge.shield.checkmark.fill"
        case .speaker: return "mic.fill"
        case .listener: return "ear"
        }
    }
    
    var color: Color {
        switch self {
        case .host: return .orange
        case .coHost: return .purple
        case .speaker: return .blue
        case .listener: return .gray
        }
    }
    
    /// Sort order for display
    var sortOrder: Int {
        switch self {
        case .host: return 0
        case .coHost: return 1
        case .speaker: return 2
        case .listener: return 3
        }
    }
}

/// Action to perform on a participant
enum ParticipantAction: String, CaseIterable {
    case mute
    case unmute
    case promoteToSpeaker
    case promoteToCoHost
    case demoteToListener
    case removeFromRoom
    
    var displayName: String {
        switch self {
        case .mute: return "Mute"
        case .unmute: return "Unmute"
        case .promoteToSpeaker: return "Make Speaker"
        case .promoteToCoHost: return "Make Co-Host"
        case .demoteToListener: return "Move to Listeners"
        case .removeFromRoom: return "Remove from Room"
        }
    }
    
    var icon: String {
        switch self {
        case .mute: return "mic.slash.fill"
        case .unmute: return "mic.fill"
        case .promoteToSpeaker: return "arrow.up.circle.fill"
        case .promoteToCoHost: return "person.badge.shield.checkmark.fill"
        case .demoteToListener: return "arrow.down.circle.fill"
        case .removeFromRoom: return "xmark.circle.fill"
        }
    }
    
    var isDestructive: Bool {
        self == .removeFromRoom
    }
}

