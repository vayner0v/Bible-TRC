//
//  DiscoveryService.swift
//  Bible v1
//
//  Community Tab - Discovery Service
//

import Foundation
import Supabase
import CoreLocation

/// Service for discovery features - trending, suggestions, nearby
@MainActor
final class DiscoveryService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Trending
    
    /// Get trending items
    func getTrending(type: TrendingType, timeRange: TrendingTimeRange = .day, limit: Int = 10) async throws -> [TrendingItem] {
        let items: [TrendingItem] = try await supabase
            .from("trending_cache")
            .select()
            .eq("type", value: type.rawValue)
            .order("score", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return items
    }
    
    /// Get all trending (verses, topics, tags)
    func getAllTrending(limit: Int = 5) async throws -> (verses: [TrendingItem], topics: [TrendingItem], tags: [TrendingItem]) {
        async let verses = getTrending(type: .verse, limit: limit)
        async let topics = getTrending(type: .topic, limit: limit)
        async let tags = getTrending(type: .tag, limit: limit)
        
        return try await (verses, topics, tags)
    }
    
    /// Compute trending (call periodically via cron/edge function)
    func computeTrending() async throws {
        // This would typically be done by a Supabase Edge Function
        // Here we just refresh the cache from recent posts
        
        let since = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
        
        // Get recent posts
        let posts: [Post] = try await supabase
            .from("posts")
            .select()
            .gte("created_at", value: ISO8601DateFormatter().string(from: since))
            .is("deleted_at", value: nil)
            .execute()
            .value
        
        // Count tags
        var tagCounts: [String: Int] = [:]
        for post in posts {
            for tag in post.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        // Create trending items for tags
        for (tag, count) in tagCounts.sorted(by: { $0.value > $1.value }).prefix(20) {
            let item = TrendingItem(
                type: .tag,
                identifier: tag,
                score: Double(count),
                postCount24h: count,
                engagement24h: 0
            )
            
            try await supabase
                .from("trending_cache")
                .upsert(item, onConflict: "type,identifier")
                .execute()
        }
    }
    
    // MARK: - User Suggestions
    
    /// Get suggested users to follow
    func getSuggestedUsers(userId: UUID, limit: Int = 10) async throws -> [UserSuggestion] {
        var suggestions: [UserSuggestion] = []
        
        // 1. Get users followed by people you follow (mutual connections)
        let mutualSuggestions = try await getMutualFollowerSuggestions(userId: userId, limit: limit / 2)
        suggestions.append(contentsOf: mutualSuggestions)
        
        // 2. Get users with similar reading patterns
        let similarSuggestions = try await getSimilarReaderSuggestions(userId: userId, limit: limit / 2)
        suggestions.append(contentsOf: similarSuggestions)
        
        // 3. Fill with popular users if needed
        if suggestions.count < limit {
            let popularSuggestions = try await getPopularUserSuggestions(
                userId: userId,
                excludeIds: suggestions.map { $0.user.id },
                limit: limit - suggestions.count
            )
            suggestions.append(contentsOf: popularSuggestions)
        }
        
        // Remove duplicates and sort by score
        let uniqueSuggestions = Array(Dictionary(grouping: suggestions) { $0.user.id }
            .compactMapValues { $0.first }
            .values)
            .sorted { $0.score > $1.score }
        
        return Array(uniqueSuggestions.prefix(limit))
    }
    
    /// Get mutual follower suggestions
    private func getMutualFollowerSuggestions(userId: UUID, limit: Int) async throws -> [UserSuggestion] {
        // Get users I follow
        let following: [Follow] = try await supabase
            .from("follows")
            .select("followee_id")
            .eq("follower_id", value: userId.uuidString)
            .eq("state", value: "active")
            .execute()
            .value
        
        let followingIds = following.map { $0.followeeId.uuidString }
        
        guard !followingIds.isEmpty else { return [] }
        
        // Get users they follow that I don't
        let theirFollowing: [Follow] = try await supabase
            .from("follows")
            .select("followee_id, follower_id")
            .in("follower_id", values: followingIds)
            .eq("state", value: "active")
            .execute()
            .value
        
        // Count how many of my follows follow each user
        var followCounts: [UUID: Int] = [:]
        for follow in theirFollowing {
            if follow.followeeId != userId && !followingIds.contains(follow.followeeId.uuidString) {
                followCounts[follow.followeeId, default: 0] += 1
            }
        }
        
        // Get top suggested user IDs
        let topUserIds = followCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
        
        guard !topUserIds.isEmpty else { return [] }
        
        // Get profiles
        let profiles: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .select()
            .in("id", values: topUserIds.map { $0.uuidString })
            .execute()
            .value
        
        return profiles.map { profile in
            UserSuggestion(
                user: CommunityProfileSummary(from: profile),
                reason: .mutualFollowers,
                score: Double(followCounts[profile.id] ?? 0),
                mutualFollowers: followCounts[profile.id]
            )
        }
    }
    
    /// Get similar reader suggestions
    private func getSimilarReaderSuggestions(userId: UUID, limit: Int) async throws -> [UserSuggestion] {
        // Get user's reading patterns
        let patterns: [UserReadingPattern] = try await supabase
            .from("user_reading_patterns")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        guard let myPattern = patterns.first, !myPattern.favoriteTopics.isEmpty else {
            return []
        }
        
        // Find users with similar topics
        let similarUsers: [UserReadingPattern] = try await supabase
            .from("user_reading_patterns")
            .select()
            .neq("user_id", value: userId.uuidString)
            .overlaps("favorite_topics", value: myPattern.favoriteTopics)
            .limit(limit * 2)
            .execute()
            .value
        
        let userIds = similarUsers.map { $0.userId.uuidString }
        
        guard !userIds.isEmpty else { return [] }
        
        // Get profiles
        let profiles: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .select()
            .in("id", values: userIds)
            .limit(limit)
            .execute()
            .value
        
        return profiles.map { profile in
            let userPattern = similarUsers.first { $0.userId == profile.id }
            let commonTopics = Set(myPattern.favoriteTopics).intersection(Set(userPattern?.favoriteTopics ?? []))
            
            return UserSuggestion(
                user: CommunityProfileSummary(from: profile),
                reason: .similarReading,
                score: Double(commonTopics.count),
                commonTopics: Array(commonTopics)
            )
        }
    }
    
    /// Get popular user suggestions
    private func getPopularUserSuggestions(userId: UUID, excludeIds: [UUID], limit: Int) async throws -> [UserSuggestion] {
        let excludeStrings = ([userId] + excludeIds).map { $0.uuidString }
        
        let profiles: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .select()
            .not("id", operator: .in, value: excludeStrings)
            .order("follower_count", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return profiles.map { profile in
            UserSuggestion(
                user: CommunityProfileSummary(from: profile),
                reason: .popular,
                score: Double(profile.followerCount)
            )
        }
    }
    
    // MARK: - Nearby
    
    /// Get nearby users
    func getNearbyUsers(userId: UUID, latitude: Double, longitude: Double, radiusKm: Double = 50, limit: Int = 20) async throws -> [CommunityProfileSummary] {
        // Note: This requires PostGIS extension in Supabase
        // Using a simple distance calculation via RPC function
        
        // For now, return users in the same city
        let currentUser = try await CommunityService.shared.profileService.getProfile(userId: userId)
        
        guard let city = currentUser?.locationCity else { return [] }
        
        let profiles: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .select()
            .eq("location_city", value: city)
            .neq("id", value: userId.uuidString)
            .limit(limit)
            .execute()
            .value
        
        return profiles.map { CommunityProfileSummary(from: $0) }
    }
    
    // MARK: - Group Suggestions
    
    /// Get suggested groups
    func getSuggestedGroups(userId: UUID, limit: Int = 10) async throws -> [GroupSuggestion] {
        var suggestions: [GroupSuggestion] = []
        
        // Get groups that people I follow are in
        let following: [Follow] = try await supabase
            .from("follows")
            .select("followee_id")
            .eq("follower_id", value: userId.uuidString)
            .eq("state", value: "active")
            .limit(50)
            .execute()
            .value
        
        let followingIds = following.map { $0.followeeId.uuidString }
        
        if !followingIds.isEmpty {
            let memberships: [GroupMember] = try await supabase
                .from("group_members")
                .select("group_id")
                .in("user_id", values: followingIds)
                .execute()
                .value
            
            var groupCounts: [UUID: Int] = [:]
            for membership in memberships {
                groupCounts[membership.groupId, default: 0] += 1
            }
            
            let topGroupIds = groupCounts.sorted { $0.value > $1.value }
                .prefix(limit / 2)
                .map { $0.key.uuidString }
            
            if !topGroupIds.isEmpty {
                let groups: [CommunityGroup] = try await supabase
                    .from("groups")
                    .select()
                    .in("id", values: topGroupIds)
                    .execute()
                    .value
                
                for group in groups {
                    suggestions.append(GroupSuggestion(
                        id: UUID(),
                        group: GroupSummary(
                            id: group.id,
                            name: group.name,
                            type: group.type,
                            privacy: group.privacy,
                            avatarUrl: group.avatarUrl,
                            memberCount: group.memberCount,
                            isMember: false
                        ),
                        reason: .followersInGroup,
                        score: Double(groupCounts[group.id] ?? 0)
                    ))
                }
            }
        }
        
        // Fill with popular groups
        if suggestions.count < limit {
            let existingIds = suggestions.map { $0.group.id.uuidString }
            
            let popularGroups: [CommunityGroup] = try await supabase
                .from("groups")
                .select()
                .eq("privacy", value: "public")
                .not("id", operator: .in, value: existingIds.isEmpty ? [""] : existingIds)
                .order("member_count", ascending: false)
                .limit(limit - suggestions.count)
                .execute()
                .value
            
            for group in popularGroups {
                suggestions.append(GroupSuggestion(
                    id: UUID(),
                    group: GroupSummary(
                        id: group.id,
                        name: group.name,
                        type: group.type,
                        privacy: group.privacy,
                        avatarUrl: group.avatarUrl,
                        memberCount: group.memberCount,
                        isMember: false
                    ),
                    reason: .popular,
                    score: Double(group.memberCount)
                ))
            }
        }
        
        return suggestions
    }
}

// MARK: - Supporting Types

/// User reading pattern
struct UserReadingPattern: Codable {
    let userId: UUID
    let booksRead: [String: Int]?
    let favoriteTopics: [String]
    let readingFrequency: [String: Int]?
    let lastComputedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case booksRead = "books_read"
        case favoriteTopics = "favorite_topics"
        case readingFrequency = "reading_frequency"
        case lastComputedAt = "last_computed_at"
    }
}

