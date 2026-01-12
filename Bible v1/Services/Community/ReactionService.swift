//
//  ReactionService.swift
//  Bible v1
//
//  Community Tab - Reaction Service
//

import Foundation
import Supabase

/// Service for managing reactions
@MainActor
final class ReactionService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Public Methods
    
    /// Toggle a reaction (add if not exists, remove if exists)
    func toggleReaction(
        userId: UUID,
        targetType: ReactionTargetType,
        targetId: UUID,
        reactionType: ReactionType
    ) async throws {
        // Check if reaction exists
        let existing = try await getReaction(
            userId: userId,
            targetType: targetType,
            targetId: targetId,
            reactionType: reactionType
        )
        
        if existing != nil {
            // Remove reaction
            try await removeReaction(
                userId: userId,
                targetType: targetType,
                targetId: targetId,
                reactionType: reactionType
            )
        } else {
            // Add reaction
            try await addReaction(
                userId: userId,
                targetType: targetType,
                targetId: targetId,
                reactionType: reactionType
            )
        }
        
        // If this is a "prayed" reaction on a prayer post, handle prayer circle
        if reactionType == .prayed && targetType == .post {
            if existing == nil {
                try? await joinPrayerCircle(postId: targetId, userId: userId)
            }
        }
    }
    
    /// Add a reaction
    func addReaction(
        userId: UUID,
        targetType: ReactionTargetType,
        targetId: UUID,
        reactionType: ReactionType
    ) async throws {
        let reaction = Reaction(
            userId: userId,
            targetType: targetType,
            targetId: targetId,
            reactionType: reactionType
        )
        
        try await supabase
            .from("reactions")
            .upsert(reaction, onConflict: "user_id,target_type,target_id,reaction_type")
            .execute()
    }
    
    /// Remove a reaction
    func removeReaction(
        userId: UUID,
        targetType: ReactionTargetType,
        targetId: UUID,
        reactionType: ReactionType
    ) async throws {
        try await supabase
            .from("reactions")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("target_type", value: targetType.rawValue)
            .eq("target_id", value: targetId.uuidString)
            .eq("reaction_type", value: reactionType.rawValue)
            .execute()
    }
    
    /// Get a specific reaction
    func getReaction(
        userId: UUID,
        targetType: ReactionTargetType,
        targetId: UUID,
        reactionType: ReactionType
    ) async throws -> Reaction? {
        let reactions: [Reaction] = try await supabase
            .from("reactions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("target_type", value: targetType.rawValue)
            .eq("target_id", value: targetId.uuidString)
            .eq("reaction_type", value: reactionType.rawValue)
            .execute()
            .value
        
        return reactions.first
    }
    
    /// Get all user reactions for a target
    func getUserReactions(
        userId: UUID,
        targetType: ReactionTargetType,
        targetId: UUID
    ) async throws -> [ReactionType] {
        let reactions: [Reaction] = try await supabase
            .from("reactions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("target_type", value: targetType.rawValue)
            .eq("target_id", value: targetId.uuidString)
            .execute()
            .value
        
        return reactions.map { $0.reactionType }
    }
    
    /// Get all reactions for a target
    func getReactions(
        targetType: ReactionTargetType,
        targetId: UUID
    ) async throws -> [Reaction] {
        let reactions: [Reaction] = try await supabase
            .from("reactions")
            .select("*, user:community_profiles!user_id(*)")
            .eq("target_type", value: targetType.rawValue)
            .eq("target_id", value: targetId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return reactions
    }
    
    /// Get reaction counts for a target
    func getReactionCounts(
        targetType: ReactionTargetType,
        targetId: UUID
    ) async throws -> [ReactionType: Int] {
        let reactions: [Reaction] = try await supabase
            .from("reactions")
            .select()
            .eq("target_type", value: targetType.rawValue)
            .eq("target_id", value: targetId.uuidString)
            .execute()
            .value
        
        var counts: [ReactionType: Int] = [:]
        for reaction in reactions {
            counts[reaction.reactionType, default: 0] += 1
        }
        
        return counts
    }
    
    /// Get users who reacted with a specific type
    func getReactors(
        targetType: ReactionTargetType,
        targetId: UUID,
        reactionType: ReactionType,
        limit: Int = 50
    ) async throws -> [CommunityProfileSummary] {
        let reactions: [Reaction] = try await supabase
            .from("reactions")
            .select("*, user:community_profiles!user_id(*)")
            .eq("target_type", value: targetType.rawValue)
            .eq("target_id", value: targetId.uuidString)
            .eq("reaction_type", value: reactionType.rawValue)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return reactions.compactMap { $0.user }
    }
    
    // MARK: - Private Methods
    
    private func joinPrayerCircle(postId: UUID, userId: UUID) async throws {
        let member = PrayerCircleMember(
            prayerPostId: postId,
            userId: userId
        )
        
        try await supabase
            .from("prayer_circle_members")
            .upsert(member, onConflict: "prayer_post_id,user_id")
            .execute()
    }
}

