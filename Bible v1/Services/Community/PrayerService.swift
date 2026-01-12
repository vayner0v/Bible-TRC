//
//  PrayerService.swift
//  Bible v1
//
//  Community Tab - Prayer Service
//

import Foundation
import Supabase

/// Service for managing prayer requests and circles
@MainActor
final class PrayerService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Prayer Requests
    
    /// Get prayer requests feed
    func getPrayerFeed(category: CommunityPrayerCategory? = nil, offset: Int = 0, limit: Int = 20) async throws -> [CommunityPrayerRequest] {
        var query = supabase
            .from("prayer_requests")
            .select("*, post:posts!post_id(*, author:community_profiles!author_id(*))")
            .eq("is_answered", value: false)
        
        if let category = category {
            query = query.eq("category", value: category.rawValue)
        }
        
        let requests: [CommunityPrayerRequest] = try await query
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return requests
    }
    
    /// Get a specific prayer request
    func getPrayerRequest(postId: UUID) async throws -> CommunityPrayerRequest? {
        let requests: [CommunityPrayerRequest] = try await supabase
            .from("prayer_requests")
            .select("*, post:posts!post_id(*, author:community_profiles!author_id(*))")
            .eq("post_id", value: postId.uuidString)
            .execute()
            .value
        
        return requests.first
    }
    
    /// Update prayer request details
    func updatePrayerRequest(
        postId: UUID,
        category: CommunityPrayerCategory? = nil,
        urgency: CommunityPrayerUrgency? = nil,
        durationDays: Int? = nil
    ) async throws {
        var updates: [String: AnyEncodable] = [:]
        
        if let category = category {
            updates["category"] = AnyEncodable(category.rawValue)
        }
        if let urgency = urgency {
            updates["urgency"] = AnyEncodable(urgency.rawValue)
        }
        if let durationDays = durationDays {
            updates["duration_days"] = AnyEncodable(durationDays)
            let expiresAt = Calendar.current.date(byAdding: .day, value: durationDays, to: Date())
            if let expiresAt = expiresAt {
                updates["expires_at"] = AnyEncodable(ISO8601DateFormatter().string(from: expiresAt))
            }
        }
        
        try await supabase
            .from("prayer_requests")
            .update(updates)
            .eq("post_id", value: postId.uuidString)
            .execute()
    }
    
    /// Mark prayer as answered
    func markAnswered(postId: UUID, note: String?) async throws {
        let updates: [String: AnyEncodable] = [
            "is_answered": AnyEncodable(true),
            "answered_at": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
            "answered_note": AnyEncodable(note ?? "")
        ]
        
        try await supabase
            .from("prayer_requests")
            .update(updates)
            .eq("post_id", value: postId.uuidString)
            .execute()
        
        // Create an update
        if let userId = CommunityService.shared.currentProfile?.id {
            _ = try await addPrayerUpdate(
                postId: postId,
                authorId: userId,
                content: note ?? "Prayer answered! Thank you for praying.",
                type: .answered
            )
        }
    }
    
    // MARK: - Prayer Circle
    
    /// Join a prayer circle
    func joinPrayerCircle(request: JoinPrayerCircleRequest, userId: UUID) async throws {
        let member = PrayerCircleMember(
            prayerPostId: request.prayerPostId,
            userId: userId,
            hasReminder: request.setReminder,
            reminderFrequency: request.reminderFrequency
        )
        
        try await supabase
            .from("prayer_circle_members")
            .upsert(member, onConflict: "prayer_post_id,user_id")
            .execute()
    }
    
    /// Leave a prayer circle
    func leavePrayerCircle(postId: UUID, userId: UUID) async throws {
        try await supabase
            .from("prayer_circle_members")
            .delete()
            .eq("prayer_post_id", value: postId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Get prayer circle for a request
    func getPrayerCircle(postId: UUID, userId: UUID? = nil) async throws -> PrayerCircle {
        let members: [PrayerCircleMember] = try await supabase
            .from("prayer_circle_members")
            .select("*, user:community_profiles!user_id(*)")
            .eq("prayer_post_id", value: postId.uuidString)
            .order("prayed_at", ascending: false)
            .limit(10)
            .execute()
            .value
        
        let recentProfiles = members.compactMap { $0.user }
        
        // Get total count
        let allMembers: [PrayerCircleMember] = try await supabase
            .from("prayer_circle_members")
            .select("user_id")
            .eq("prayer_post_id", value: postId.uuidString)
            .execute()
            .value
        
        // Check if user has prayed
        var hasUserPrayed = false
        var userPrayedAt: Date? = nil
        
        if let userId = userId {
            if let userMember = members.first(where: { $0.userId == userId }) {
                hasUserPrayed = true
                userPrayedAt = userMember.prayedAt
            }
        }
        
        return PrayerCircle(
            prayerPostId: postId,
            memberCount: allMembers.count,
            recentMembers: recentProfiles,
            hasUserPrayed: hasUserPrayed,
            userPrayedAt: userPrayedAt
        )
    }
    
    /// Get prayers the user has joined
    func getUserPrayerCircles(userId: UUID, offset: Int = 0, limit: Int = 20) async throws -> [CommunityPrayerRequest] {
        let memberships: [PrayerCircleMember] = try await supabase
            .from("prayer_circle_members")
            .select("prayer_post_id")
            .eq("user_id", value: userId.uuidString)
            .order("prayed_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        let postIds = memberships.map { $0.prayerPostId.uuidString }
        
        guard !postIds.isEmpty else { return [] }
        
        let requests: [CommunityPrayerRequest] = try await supabase
            .from("prayer_requests")
            .select("*, post:posts!post_id(*, author:community_profiles!author_id(*))")
            .in("post_id", values: postIds)
            .execute()
            .value
        
        return requests
    }
    
    /// Update prayer reminder settings
    func updateReminder(postId: UUID, userId: UUID, hasReminder: Bool, frequency: ReminderFrequency?) async throws {
        var updates: [String: AnyEncodable] = [
            "has_reminder": AnyEncodable(hasReminder)
        ]
        
        if let frequency = frequency {
            updates["reminder_frequency"] = AnyEncodable(frequency.rawValue)
        }
        
        try await supabase
            .from("prayer_circle_members")
            .update(updates)
            .eq("prayer_post_id", value: postId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    // MARK: - Prayer Updates
    
    /// Add a prayer update
    func addPrayerUpdate(postId: UUID, authorId: UUID, content: String, type: PrayerUpdateType) async throws -> PrayerUpdate {
        let update = PrayerUpdate(
            prayerPostId: postId,
            authorId: authorId,
            content: content,
            updateType: type
        )
        
        let created: PrayerUpdate = try await supabase
            .from("prayer_updates")
            .insert(update)
            .select()
            .single()
            .execute()
            .value
        
        return created
    }
    
    /// Get updates for a prayer request
    func getPrayerUpdates(postId: UUID) async throws -> [PrayerUpdate] {
        let updates: [PrayerUpdate] = try await supabase
            .from("prayer_updates")
            .select("*, author:community_profiles!author_id(*)")
            .eq("prayer_post_id", value: postId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return updates
    }
    
    // MARK: - Answered Prayers
    
    /// Get answered prayers
    func getAnsweredPrayers(userId: UUID? = nil, offset: Int = 0, limit: Int = 20) async throws -> [CommunityPrayerRequest] {
        var query = supabase
            .from("prayer_requests")
            .select("*, post:posts!post_id(*, author:community_profiles!author_id(*))")
            .eq("is_answered", value: true)
        
        if let userId = userId {
            // Get user's answered prayers
            query = query.eq("post.author_id", value: userId.uuidString)
        }
        
        let requests: [CommunityPrayerRequest] = try await query
            .order("answered_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return requests
    }
}

