//
//  LiveRoomService.swift
//  Bible v1
//
//  Community Tab - Live Room Service
//

import Foundation
import Supabase

/// Service for managing live audio/video rooms
@MainActor
final class LiveRoomService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Room CRUD
    
    /// Create a live room
    func createRoom(_ request: CreateLiveRoomRequest, hostId: UUID) async throws -> LiveRoom {
        let room = LiveRoom(
            title: request.title,
            description: request.description,
            type: request.type,
            hostId: hostId,
            groupId: request.groupId,
            status: request.scheduledAt != nil ? .scheduled : .live,
            scheduledAt: request.scheduledAt,
            startedAt: request.scheduledAt == nil ? Date() : nil,
            maxParticipants: request.maxParticipants,
            isVideoEnabled: request.isVideoEnabled,
            settings: request.settings
        )
        
        let created: LiveRoom = try await supabase
            .from("live_rooms")
            .insert(room)
            .select()
            .single()
            .execute()
            .value
        
        // Add host as participant
        let participant = RoomParticipant(
            roomId: created.id,
            userId: hostId,
            role: .host,
            isMuted: false
        )
        
        try await supabase
            .from("room_participants")
            .insert(participant)
            .execute()
        
        return created
    }
    
    /// Get a live room
    func getRoom(id: UUID) async throws -> LiveRoom? {
        let rooms: [LiveRoom] = try await supabase
            .from("live_rooms")
            .select("*, host:community_profiles!host_id(*)")
            .eq("id", value: id.uuidString)
            .execute()
            .value
        
        guard var room = rooms.first else { return nil }
        
        // Get participants
        let participants: [RoomParticipant] = try await supabase
            .from("room_participants")
            .select("*, user:community_profiles!user_id(*)")
            .eq("room_id", value: id.uuidString)
            .is("left_at", value: nil)
            .execute()
            .value
        
        room.participants = participants
        
        return room
    }
    
    /// Get live rooms feed
    func getLiveRooms(type: LiveRoomType? = nil, offset: Int = 0, limit: Int = 20) async throws -> [LiveRoom] {
        var query = supabase
            .from("live_rooms")
            .select("*, host:community_profiles!host_id(*)")
            .eq("status", value: "live")
        
        if let type = type {
            query = query.eq("type", value: type.rawValue)
        }
        
        let rooms: [LiveRoom] = try await query
            .order("participant_count", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return rooms
    }
    
    /// Get scheduled rooms
    func getScheduledRooms(groupId: UUID? = nil, offset: Int = 0, limit: Int = 20) async throws -> [LiveRoom] {
        var query = supabase
            .from("live_rooms")
            .select("*, host:community_profiles!host_id(*)")
            .eq("status", value: "scheduled")
            .gte("scheduled_at", value: ISO8601DateFormatter().string(from: Date()))
        
        if let groupId = groupId {
            query = query.eq("group_id", value: groupId.uuidString)
        }
        
        let rooms: [LiveRoom] = try await query
            .order("scheduled_at", ascending: true)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return rooms
    }
    
    // MARK: - Room Actions
    
    /// Start a scheduled room
    func startRoom(id: UUID) async throws {
        try await supabase
            .from("live_rooms")
            .update([
                "status": "live",
                "started_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// End a room
    func endRoom(id: UUID) async throws {
        try await supabase
            .from("live_rooms")
            .update([
                "status": "ended",
                "ended_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: id.uuidString)
            .execute()
        
        // Mark all participants as left
        try await supabase
            .from("room_participants")
            .update(["left_at": ISO8601DateFormatter().string(from: Date())])
            .eq("room_id", value: id.uuidString)
            .is("left_at", value: nil)
            .execute()
    }
    
    /// Update room settings
    func updateRoom(id: UUID, title: String?, description: String?, settings: LiveRoomSettings?) async throws {
        var updates: [String: AnyEncodable] = [:]
        
        if let title = title { updates["title"] = AnyEncodable(title) }
        if let description = description { updates["description"] = AnyEncodable(description) }
        if let settings = settings { updates["settings"] = AnyEncodable(settings) }
        
        try await supabase
            .from("live_rooms")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Participants
    
    /// Join a room
    func joinRoom(roomId: UUID, userId: UUID, role: RoomRole = .listener) async throws -> RoomParticipant {
        // Check room capacity
        let room = try await getRoom(id: roomId)
        guard let room = room else {
            throw CommunityError.notFound
        }
        
        guard room.status == .live else {
            throw CommunityError.validation("This room is not live")
        }
        
        guard room.participantCount < room.maxParticipants else {
            throw CommunityError.validation("This room is full")
        }
        
        let participant = RoomParticipant(
            roomId: roomId,
            userId: userId,
            role: role,
            isMuted: role == .listener ? room.settings.autoMuteOnJoin : false
        )
        
        let created: RoomParticipant = try await supabase
            .from("room_participants")
            .upsert(participant, onConflict: "room_id,user_id")
            .select()
            .single()
            .execute()
            .value
        
        // Update participant count
        try await updateParticipantCount(roomId: roomId)
        
        return created
    }
    
    /// Leave a room
    func leaveRoom(roomId: UUID, userId: UUID) async throws {
        try await supabase
            .from("room_participants")
            .update(["left_at": ISO8601DateFormatter().string(from: Date())])
            .eq("room_id", value: roomId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        // Update participant count
        try await updateParticipantCount(roomId: roomId)
    }
    
    /// Get participants in a room
    func getParticipants(roomId: UUID) async throws -> [RoomParticipant] {
        let participants: [RoomParticipant] = try await supabase
            .from("room_participants")
            .select("*, user:community_profiles!user_id(*)")
            .eq("room_id", value: roomId.uuidString)
            .is("left_at", value: nil)
            .order("role", ascending: true)
            .execute()
            .value
        
        return participants
    }
    
    /// Update participant role
    func updateParticipantRole(roomId: UUID, userId: UUID, role: RoomRole) async throws {
        try await supabase
            .from("room_participants")
            .update(["role": role.rawValue])
            .eq("room_id", value: roomId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Toggle mute status
    func toggleMute(roomId: UUID, userId: UUID, isMuted: Bool) async throws {
        try await supabase
            .from("room_participants")
            .update(["is_muted": isMuted])
            .eq("room_id", value: roomId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Raise/lower hand
    func setHandRaised(roomId: UUID, userId: UUID, raised: Bool) async throws {
        try await supabase
            .from("room_participants")
            .update(["has_raised_hand": raised])
            .eq("room_id", value: roomId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Remove participant from room
    func removeParticipant(roomId: UUID, userId: UUID) async throws {
        try await leaveRoom(roomId: roomId, userId: userId)
    }
    
    // MARK: - Private Methods
    
    private func updateParticipantCount(roomId: UUID) async throws {
        let participants: [RoomParticipant] = try await supabase
            .from("room_participants")
            .select("user_id")
            .eq("room_id", value: roomId.uuidString)
            .is("left_at", value: nil)
            .execute()
            .value
        
        try await supabase
            .from("live_rooms")
            .update(["participant_count": participants.count])
            .eq("id", value: roomId.uuidString)
            .execute()
    }
}

