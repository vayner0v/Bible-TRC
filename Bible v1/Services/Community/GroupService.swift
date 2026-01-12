//
//  GroupService.swift
//  Bible v1
//
//  Community Tab - Group Service
//

import Foundation
import Supabase

/// Service for managing groups
@MainActor
final class GroupService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Group CRUD
    
    /// Create a new group
    func createGroup(_ request: CreateGroupRequest, createdBy: UUID) async throws -> CommunityGroup {
        let group = CommunityGroup(
            name: request.name,
            description: request.description,
            type: request.type,
            privacy: request.privacy,
            rules: request.rules,
            joinQuestions: request.joinQuestions,
            linkedReadingPlanId: request.linkedReadingPlanId,
            createdBy: createdBy
        )
        
        let createdGroup: CommunityGroup = try await supabase
            .from("groups")
            .insert(group)
            .select()
            .single()
            .execute()
            .value
        
        // Add creator as owner
        let membership = GroupMember(
            groupId: createdGroup.id,
            userId: createdBy,
            role: .owner
        )
        
        try await supabase
            .from("group_members")
            .insert(membership)
            .execute()
        
        return createdGroup
    }
    
    /// Get a group by ID
    func getGroup(id: UUID, userId: UUID? = nil) async throws -> CommunityGroup? {
        var group: CommunityGroup = try await supabase
            .from("groups")
            .select("*, creator:community_profiles!created_by(*)")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        // Get user's membership if userId provided
        if let userId = userId {
            let memberships: [GroupMember] = try await supabase
                .from("group_members")
                .select()
                .eq("group_id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            group.userMembership = memberships.first
        }
        
        return group
    }
    
    /// Update a group
    func updateGroup(id: UUID, name: String?, description: String?, rules: [String]?, weeklyPrompt: String?) async throws -> CommunityGroup {
        var updates: [String: AnyEncodable] = [
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        if let name = name { updates["name"] = AnyEncodable(name) }
        if let description = description { updates["description"] = AnyEncodable(description) }
        if let rules = rules { updates["rules"] = AnyEncodable(rules) }
        if let weeklyPrompt = weeklyPrompt { updates["weekly_prompt"] = AnyEncodable(weeklyPrompt) }
        
        let group: CommunityGroup = try await supabase
            .from("groups")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        return group
    }
    
    /// Delete a group
    func deleteGroup(id: UUID) async throws {
        try await supabase
            .from("groups")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Membership
    
    /// Join a group
    func joinGroup(groupId: UUID, userId: UUID, answers: [String: String]? = nil) async throws {
        let group = try await getGroup(id: groupId)
        
        guard let group = group else {
            throw CommunityError.notFound
        }
        
        // Check if private and requires answers
        if group.privacy == .private && !group.joinQuestions.isEmpty {
            guard answers != nil else {
                throw CommunityError.validation("Please answer the join questions")
            }
        }
        
        let membership = GroupMember(
            groupId: groupId,
            userId: userId,
            role: .member,
            joinAnswers: answers
        )
        
        try await supabase
            .from("group_members")
            .insert(membership)
            .execute()
    }
    
    /// Leave a group
    func leaveGroup(groupId: UUID, userId: UUID) async throws {
        // Check if user is owner
        let membership = try await getMembership(groupId: groupId, userId: userId)
        
        if membership?.role == .owner {
            throw CommunityError.validation("Owners cannot leave. Transfer ownership first.")
        }
        
        try await supabase
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Get membership
    func getMembership(groupId: UUID, userId: UUID) async throws -> GroupMember? {
        let memberships: [GroupMember] = try await supabase
            .from("group_members")
            .select()
            .eq("group_id", value: groupId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return memberships.first
    }
    
    /// Get group members
    func getMembers(groupId: UUID, offset: Int = 0, limit: Int = 50) async throws -> [GroupMember] {
        let members: [GroupMember] = try await supabase
            .from("group_members")
            .select("*, user:community_profiles!user_id(*)")
            .eq("group_id", value: groupId.uuidString)
            .order("role", ascending: true)
            .order("joined_at", ascending: true)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return members
    }
    
    /// Update member role
    func updateMemberRole(groupId: UUID, userId: UUID, newRole: GroupRole) async throws {
        try await supabase
            .from("group_members")
            .update(["role": newRole.rawValue])
            .eq("group_id", value: groupId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Remove member from group
    func removeMember(groupId: UUID, userId: UUID) async throws {
        try await supabase
            .from("group_members")
            .delete()
            .eq("group_id", value: groupId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    // MARK: - Discovery
    
    /// Get user's groups
    func getUserGroups(userId: UUID) async throws -> [CommunityGroup] {
        let memberships: [GroupMember] = try await supabase
            .from("group_members")
            .select("group_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let groupIds = memberships.map { $0.groupId.uuidString }
        
        guard !groupIds.isEmpty else { return [] }
        
        let groups: [CommunityGroup] = try await supabase
            .from("groups")
            .select()
            .in("id", values: groupIds)
            .order("updated_at", ascending: false)
            .execute()
            .value
        
        return groups
    }
    
    /// Discover groups
    func discoverGroups(type: GroupType? = nil, offset: Int = 0, limit: Int = 20) async throws -> [CommunityGroup] {
        var query = supabase
            .from("groups")
            .select()
            .eq("privacy", value: "public")
        
        if let type = type {
            query = query.eq("type", value: type.rawValue)
        }
        
        let groups: [CommunityGroup] = try await query
            .order("member_count", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return groups
    }
    
    /// Search groups
    func searchGroups(query: String, offset: Int = 0, limit: Int = 20) async throws -> [CommunityGroup] {
        let groups: [CommunityGroup] = try await supabase
            .from("groups")
            .select()
            .or("privacy.eq.public,privacy.eq.private")
            .or("name.ilike.%\(query)%,description.ilike.%\(query)%")
            .order("member_count", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return groups
    }
    
    // MARK: - Events
    
    /// Create a group event
    func createEvent(_ request: CreateEventRequest, createdBy: UUID) async throws -> GroupEvent {
        var event = GroupEvent(
            groupId: request.groupId,
            title: request.title,
            description: request.description,
            eventType: request.eventType,
            scheduledAt: request.scheduledAt,
            durationMinutes: request.durationMinutes,
            createdBy: createdBy
        )
        
        // Create live room if needed
        if request.createLiveRoom {
            let room = try await CommunityService.shared.liveRoomService.createRoom(
                CreateLiveRoomRequest(
                    title: request.title,
                    description: request.description,
                    type: request.eventType == .prayer ? .prayer : .study,
                    groupId: request.groupId,
                    scheduledAt: request.scheduledAt,
                    maxParticipants: 100,
                    isVideoEnabled: false,
                    settings: .default
                ),
                hostId: createdBy
            )
            event.liveRoomId = room.id
        }
        
        let createdEvent: GroupEvent = try await supabase
            .from("group_events")
            .insert(event)
            .select()
            .single()
            .execute()
            .value
        
        return createdEvent
    }
    
    /// Get group events
    func getEvents(groupId: UUID, upcoming: Bool = true) async throws -> [GroupEvent] {
        var query = supabase
            .from("group_events")
            .select("*, creator:community_profiles!created_by(*)")
            .eq("group_id", value: groupId.uuidString)
        
        if upcoming {
            let now = ISO8601DateFormatter().string(from: Date())
            query = query.gte("scheduled_at", value: now)
        }
        
        let events: [GroupEvent] = try await query
            .order("scheduled_at", ascending: true)
            .execute()
            .value
        
        return events
    }
    
    /// Delete an event
    func deleteEvent(id: UUID) async throws {
        try await supabase
            .from("group_events")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

