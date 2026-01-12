//
//  LiveRoom.swift
//  Bible v1
//
//  Community Tab - Live Room Model
//

import Foundation
import SwiftUI

/// A live audio/video room
struct LiveRoom: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    let type: LiveRoomType
    let hostId: UUID
    var coHostIds: [UUID]
    var groupId: UUID?
    var status: LiveRoomStatus
    var scheduledAt: Date?
    var startedAt: Date?
    var endedAt: Date?
    var maxParticipants: Int
    var isVideoEnabled: Bool
    var recordingUrl: String?
    var participantCount: Int
    var settings: LiveRoomSettings
    let createdAt: Date
    
    // Joined data
    var host: CommunityProfileSummary?
    var coHosts: [CommunityProfileSummary]?
    var group: GroupSummary?
    var participants: [RoomParticipant]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, type
        case hostId = "host_id"
        case coHostIds = "co_host_ids"
        case groupId = "group_id"
        case status
        case scheduledAt = "scheduled_at"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case maxParticipants = "max_participants"
        case isVideoEnabled = "is_video_enabled"
        case recordingUrl = "recording_url"
        case participantCount = "participant_count"
        case settings
        case createdAt = "created_at"
        case host, coHosts, group, participants
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        type: LiveRoomType = .open,
        hostId: UUID,
        coHostIds: [UUID] = [],
        groupId: UUID? = nil,
        status: LiveRoomStatus = .scheduled,
        scheduledAt: Date? = nil,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        maxParticipants: Int = 100,
        isVideoEnabled: Bool = false,
        recordingUrl: String? = nil,
        participantCount: Int = 0,
        settings: LiveRoomSettings = .default,
        createdAt: Date = Date(),
        host: CommunityProfileSummary? = nil,
        coHosts: [CommunityProfileSummary]? = nil,
        group: GroupSummary? = nil,
        participants: [RoomParticipant]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.hostId = hostId
        self.coHostIds = coHostIds
        self.groupId = groupId
        self.status = status
        self.scheduledAt = scheduledAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.maxParticipants = maxParticipants
        self.isVideoEnabled = isVideoEnabled
        self.recordingUrl = recordingUrl
        self.participantCount = participantCount
        self.settings = settings
        self.createdAt = createdAt
        self.host = host
        self.coHosts = coHosts
        self.group = group
        self.participants = participants
    }
    
    /// Check if room is currently live
    var isLive: Bool {
        status == .live
    }
    
    /// Check if room is scheduled for the future
    var isScheduled: Bool {
        status == .scheduled
    }
    
    /// Check if room has ended
    var hasEnded: Bool {
        status == .ended
    }
    
    /// Check if room is full
    var isFull: Bool {
        participantCount >= maxParticipants
    }
    
    /// Check if user is host
    func isHost(_ userId: UUID) -> Bool {
        hostId == userId
    }
    
    /// Check if user is co-host
    func isCoHost(_ userId: UUID) -> Bool {
        coHostIds.contains(userId)
    }
    
    /// Check if user can moderate
    func canModerate(_ userId: UUID) -> Bool {
        isHost(userId) || isCoHost(userId)
    }
    
    /// Formatted scheduled time
    var formattedScheduledTime: String? {
        guard let scheduledAt = scheduledAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scheduledAt)
    }
    
    /// Duration of live room
    var duration: TimeInterval? {
        guard let startedAt = startedAt else { return nil }
        let endTime = endedAt ?? Date()
        return endTime.timeIntervalSince(startedAt)
    }
    
    /// Formatted duration
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

/// Live room settings
struct LiveRoomSettings: Codable, Hashable {
    var allowHandRaise: Bool
    var autoMuteOnJoin: Bool
    var allowRecording: Bool
    var allowChat: Bool
    var onlyHostCanInvite: Bool
    
    static let `default` = LiveRoomSettings(
        allowHandRaise: true,
        autoMuteOnJoin: true,
        allowRecording: false,
        allowChat: true,
        onlyHostCanInvite: false
    )
    
    enum CodingKeys: String, CodingKey {
        case allowHandRaise = "allow_hand_raise"
        case autoMuteOnJoin = "auto_mute_on_join"
        case allowRecording = "allow_recording"
        case allowChat = "allow_chat"
        case onlyHostCanInvite = "only_host_can_invite"
    }
}

/// Types of live rooms
enum LiveRoomType: String, Codable, CaseIterable, Identifiable {
    case prayer = "prayer"
    case study = "study"
    case discussion = "discussion"
    case open = "open"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .prayer: return "Prayer Room"
        case .study: return "Bible Study"
        case .discussion: return "Discussion"
        case .open: return "Open Room"
        }
    }
    
    var icon: String {
        switch self {
        case .prayer: return "hands.sparkles.fill"
        case .study: return "book.fill"
        case .discussion: return "bubble.left.and.bubble.right.fill"
        case .open: return "person.3.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .prayer: return .purple
        case .study: return .blue
        case .discussion: return .orange
        case .open: return .green
        }
    }
}

/// Status of a live room
enum LiveRoomStatus: String, Codable {
    case scheduled = "scheduled"
    case live = "live"
    case ended = "ended"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .live: return "Live"
        case .ended: return "Ended"
        }
    }
    
    var color: Color {
        switch self {
        case .scheduled: return .orange
        case .live: return .red
        case .ended: return .gray
        }
    }
}

/// Request to create a live room
struct CreateLiveRoomRequest: Codable {
    let title: String
    let description: String?
    let type: LiveRoomType
    let groupId: UUID?
    let scheduledAt: Date?
    let maxParticipants: Int
    let isVideoEnabled: Bool
    let settings: LiveRoomSettings
    
    enum CodingKeys: String, CodingKey {
        case title, description, type
        case groupId = "group_id"
        case scheduledAt = "scheduled_at"
        case maxParticipants = "max_participants"
        case isVideoEnabled = "is_video_enabled"
        case settings
    }
}

