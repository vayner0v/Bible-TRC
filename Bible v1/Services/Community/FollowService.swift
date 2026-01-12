//
//  FollowService.swift
//  Bible v1
//
//  Community Tab - Follow Service
//

import Foundation
import Supabase

/// Service for managing follows and blocks
@MainActor
final class FollowService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Follow Methods
    
    /// Follow a user
    func follow(followerId: UUID, followeeId: UUID) async throws {
        guard followerId != followeeId else {
            throw CommunityError.validation("You cannot follow yourself")
        }
        
        // Check if blocked
        let isBlocked = try await isUserBlocked(blockerId: followeeId, blockedId: followerId)
        if isBlocked {
            throw CommunityError.permissionDenied
        }
        
        let follow = Follow(
            followerId: followerId,
            followeeId: followeeId,
            state: .active
        )
        
        try await supabase
            .from("follows")
            .upsert(follow, onConflict: "follower_id,followee_id")
            .execute()
    }
    
    /// Unfollow a user
    func unfollow(followerId: UUID, followeeId: UUID) async throws {
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: followerId.uuidString)
            .eq("followee_id", value: followeeId.uuidString)
            .execute()
    }
    
    /// Get follow status between two users
    func getFollowStatus(userId: UUID, targetId: UUID) async throws -> FollowStatus {
        // Check if following
        let followingResult: [Follow] = try await supabase
            .from("follows")
            .select()
            .eq("follower_id", value: userId.uuidString)
            .eq("followee_id", value: targetId.uuidString)
            .execute()
            .value
        
        // Check if followed by
        let followedByResult: [Follow] = try await supabase
            .from("follows")
            .select()
            .eq("follower_id", value: targetId.uuidString)
            .eq("followee_id", value: userId.uuidString)
            .execute()
            .value
        
        // Check if blocked
        let blockedResult: [Block] = try await supabase
            .from("blocks")
            .select()
            .eq("blocker_id", value: userId.uuidString)
            .eq("blocked_id", value: targetId.uuidString)
            .execute()
            .value
        
        let following = followingResult.first
        let followedBy = followedByResult.first
        
        return FollowStatus(
            isFollowing: following?.state == .active,
            isFollowedBy: followedBy?.state == .active,
            isPending: following?.state == .pending,
            isBlocked: !blockedResult.isEmpty
        )
    }
    
    /// Check if following
    func isFollowing(followerId: UUID, followeeId: UUID) async throws -> Bool {
        let result: [Follow] = try await supabase
            .from("follows")
            .select()
            .eq("follower_id", value: followerId.uuidString)
            .eq("followee_id", value: followeeId.uuidString)
            .eq("state", value: "active")
            .execute()
            .value
        
        return !result.isEmpty
    }
    
    /// Get followers of a user
    func getFollowers(
        userId: UUID,
        offset: Int = 0,
        limit: Int = 50
    ) async throws -> [FollowListItem] {
        let follows: [Follow] = try await supabase
            .from("follows")
            .select("*, follower:community_profiles!follower_id(*)")
            .eq("followee_id", value: userId.uuidString)
            .eq("state", value: "active")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return follows.compactMap { follow in
            guard let profile = follow.follower else { return nil }
            return FollowListItem(
                id: profile.id,
                profile: profile,
                followStatus: .notFollowing, // Will be enriched separately if needed
                followedAt: follow.createdAt
            )
        }
    }
    
    /// Get users that a user is following
    func getFollowing(
        userId: UUID,
        offset: Int = 0,
        limit: Int = 50
    ) async throws -> [FollowListItem] {
        let follows: [Follow] = try await supabase
            .from("follows")
            .select("*, followee:community_profiles!followee_id(*)")
            .eq("follower_id", value: userId.uuidString)
            .eq("state", value: "active")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return follows.compactMap { follow in
            guard let profile = follow.followee else { return nil }
            return FollowListItem(
                id: profile.id,
                profile: profile,
                followStatus: FollowStatus(
                    isFollowing: true,
                    isFollowedBy: false,
                    isPending: false,
                    isBlocked: false
                ),
                followedAt: follow.createdAt
            )
        }
    }
    
    /// Get mutual followers (users who follow each other)
    func getMutualFollowers(userId1: UUID, userId2: UUID) async throws -> [CommunityProfileSummary] {
        // Get followers of user1 who are also followed by user2
        let user1Followers: [Follow] = try await supabase
            .from("follows")
            .select("follower_id")
            .eq("followee_id", value: userId1.uuidString)
            .eq("state", value: "active")
            .execute()
            .value
        
        let user2Followers: [Follow] = try await supabase
            .from("follows")
            .select("follower_id")
            .eq("followee_id", value: userId2.uuidString)
            .eq("state", value: "active")
            .execute()
            .value
        
        let user1FollowerIds = Set(user1Followers.map { $0.followerId })
        let user2FollowerIds = Set(user2Followers.map { $0.followerId })
        let mutualIds = user1FollowerIds.intersection(user2FollowerIds)
        
        guard !mutualIds.isEmpty else { return [] }
        
        let profiles: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .select()
            .in("id", values: mutualIds.map { $0.uuidString })
            .execute()
            .value
        
        return profiles.map { CommunityProfileSummary(from: $0) }
    }
    
    // MARK: - Block Methods
    
    /// Block a user
    func blockUser(blockerId: UUID, blockedId: UUID) async throws {
        guard blockerId != blockedId else {
            throw CommunityError.validation("You cannot block yourself")
        }
        
        // Remove any existing follow relationship
        try await unfollow(followerId: blockerId, followeeId: blockedId)
        try await unfollow(followerId: blockedId, followeeId: blockerId)
        
        // Create block
        let block = Block(
            blockerId: blockerId,
            blockedId: blockedId
        )
        
        try await supabase
            .from("blocks")
            .upsert(block, onConflict: "blocker_id,blocked_id")
            .execute()
    }
    
    /// Unblock a user
    func unblockUser(blockerId: UUID, blockedId: UUID) async throws {
        try await supabase
            .from("blocks")
            .delete()
            .eq("blocker_id", value: blockerId.uuidString)
            .eq("blocked_id", value: blockedId.uuidString)
            .execute()
    }
    
    /// Check if a user is blocked
    func isUserBlocked(blockerId: UUID, blockedId: UUID) async throws -> Bool {
        let result: [Block] = try await supabase
            .from("blocks")
            .select()
            .eq("blocker_id", value: blockerId.uuidString)
            .eq("blocked_id", value: blockedId.uuidString)
            .execute()
            .value
        
        return !result.isEmpty
    }
    
    /// Get blocked users
    func getBlockedUsers(userId: UUID) async throws -> [CommunityProfileSummary] {
        let blocks: [Block] = try await supabase
            .from("blocks")
            .select("*, blocked:community_profiles!blocked_id(*)")
            .eq("blocker_id", value: userId.uuidString)
            .execute()
            .value
        
        return blocks.compactMap { $0.blocked }
    }
    
    // MARK: - Mute Methods
    
    /// Mute a user
    func muteUser(userId: UUID, mutedId: UUID, duration: MuteDuration) async throws {
        let mute = Mute(
            userId: userId,
            mutedId: mutedId,
            muteType: .user,
            expiresAt: duration.expiresAt
        )
        
        try await supabase
            .from("mutes")
            .insert(mute)
            .execute()
    }
    
    /// Unmute
    func unmute(userId: UUID, mutedId: UUID, muteType: MuteType) async throws {
        try await supabase
            .from("mutes")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("muted_id", value: mutedId.uuidString)
            .eq("mute_type", value: muteType.rawValue)
            .execute()
    }
    
    /// Get muted items
    func getMutedItems(userId: UUID, type: MuteType? = nil) async throws -> [Mute] {
        var query = supabase
            .from("mutes")
            .select()
            .eq("user_id", value: userId.uuidString)
        
        if let type = type {
            query = query.eq("mute_type", value: type.rawValue)
        }
        
        let mutes: [Mute] = try await query.execute().value
        
        // Filter out expired mutes
        return mutes.filter { $0.isActive }
    }
}

