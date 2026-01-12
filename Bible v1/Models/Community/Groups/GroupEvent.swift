//
//  GroupEvent.swift
//  Bible v1
//
//  Community Tab - Group Event Model
//

import Foundation
import SwiftUI

/// A scheduled event within a group
struct GroupEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let groupId: UUID
    var title: String
    var description: String?
    let eventType: EventType
    var scheduledAt: Date
    var durationMinutes: Int
    var liveRoomId: UUID?
    let createdBy: UUID?
    var attendeeCount: Int
    let createdAt: Date
    
    // Joined data
    var group: GroupSummary?
    var creator: CommunityProfileSummary?
    var isAttending: Bool?
    var liveRoom: LiveRoom?
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case title, description
        case eventType = "event_type"
        case scheduledAt = "scheduled_at"
        case durationMinutes = "duration_minutes"
        case liveRoomId = "live_room_id"
        case createdBy = "created_by"
        case attendeeCount = "attendee_count"
        case createdAt = "created_at"
        case group, creator
        case isAttending = "is_attending"
        case liveRoom = "live_room"
    }
    
    init(
        id: UUID = UUID(),
        groupId: UUID,
        title: String,
        description: String? = nil,
        eventType: EventType,
        scheduledAt: Date,
        durationMinutes: Int = 60,
        liveRoomId: UUID? = nil,
        createdBy: UUID? = nil,
        attendeeCount: Int = 0,
        createdAt: Date = Date(),
        group: GroupSummary? = nil,
        creator: CommunityProfileSummary? = nil,
        isAttending: Bool? = nil,
        liveRoom: LiveRoom? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.title = title
        self.description = description
        self.eventType = eventType
        self.scheduledAt = scheduledAt
        self.durationMinutes = durationMinutes
        self.liveRoomId = liveRoomId
        self.createdBy = createdBy
        self.attendeeCount = attendeeCount
        self.createdAt = createdAt
        self.group = group
        self.creator = creator
        self.isAttending = isAttending
        self.liveRoom = liveRoom
    }
    
    /// Check if event is happening now
    var isHappeningNow: Bool {
        let now = Date()
        let endTime = scheduledAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return now >= scheduledAt && now <= endTime
    }
    
    /// Check if event is upcoming
    var isUpcoming: Bool {
        scheduledAt > Date()
    }
    
    /// Check if event is past
    var isPast: Bool {
        let endTime = scheduledAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return endTime < Date()
    }
    
    /// End time of the event
    var endTime: Date {
        scheduledAt.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scheduledAt)
    }
    
    /// Formatted duration
    var formattedDuration: String {
        if durationMinutes < 60 {
            return "\(durationMinutes) min"
        } else if durationMinutes == 60 {
            return "1 hour"
        } else {
            let hours = durationMinutes / 60
            let mins = durationMinutes % 60
            if mins == 0 {
                return "\(hours) hours"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
}

/// Types of group events
enum EventType: String, Codable, CaseIterable, Identifiable {
    case study = "study"
    case prayer = "prayer"
    case liveRoom = "live_room"
    case meetup = "meetup"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .study: return "Bible Study"
        case .prayer: return "Prayer Meeting"
        case .liveRoom: return "Live Room"
        case .meetup: return "Meetup"
        }
    }
    
    var icon: String {
        switch self {
        case .study: return "book.fill"
        case .prayer: return "hands.sparkles.fill"
        case .liveRoom: return "video.fill"
        case .meetup: return "person.3.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .study: return .blue
        case .prayer: return .purple
        case .liveRoom: return .red
        case .meetup: return .green
        }
    }
    
    /// Whether this event type requires a live room
    var requiresLiveRoom: Bool {
        self == .liveRoom
    }
}

/// Request to create an event
struct CreateEventRequest: Codable {
    let groupId: UUID
    let title: String
    let description: String?
    let eventType: EventType
    let scheduledAt: Date
    let durationMinutes: Int
    let createLiveRoom: Bool
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case title, description
        case eventType = "event_type"
        case scheduledAt = "scheduled_at"
        case durationMinutes = "duration_minutes"
        case createLiveRoom = "create_live_room"
    }
}

/// Event attendee
struct EventAttendee: Identifiable, Codable {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let rsvpStatus: RSVPStatus
    let createdAt: Date
    
    // Joined data
    var user: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case rsvpStatus = "rsvp_status"
        case createdAt = "created_at"
        case user
    }
}

/// RSVP status for events
enum RSVPStatus: String, Codable {
    case going = "going"
    case maybe = "maybe"
    case notGoing = "not_going"
    
    var displayName: String {
        switch self {
        case .going: return "Going"
        case .maybe: return "Maybe"
        case .notGoing: return "Not Going"
        }
    }
    
    var icon: String {
        switch self {
        case .going: return "checkmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        case .notGoing: return "xmark.circle.fill"
        }
    }
}

