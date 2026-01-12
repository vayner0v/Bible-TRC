//
//  FeedService.swift
//  Bible v1
//
//  Community Tab - Feed Service
//

import Foundation
import Supabase
import Combine

/// Service for managing community feeds
@MainActor
final class FeedService: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var forYouPosts: [Post] = []
    @Published private(set) var followingPosts: [Post] = []
    @Published private(set) var isLoadingForYou = false
    @Published private(set) var isLoadingFollowing = false
    @Published private(set) var hasMoreForYou = true
    @Published private(set) var hasMoreFollowing = true
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    private var currentUserId: UUID?
    private var forYouOffset = 0
    private var followingOffset = 0
    private let pageSize = 20
    
    // MARK: - Initialization
    
    func initialize(userId: UUID) async {
        currentUserId = userId
        await loadInitialFeeds()
    }
    
    func reset() {
        currentUserId = nil
        forYouPosts = []
        followingPosts = []
        forYouOffset = 0
        followingOffset = 0
        hasMoreForYou = true
        hasMoreFollowing = true
    }
    
    // MARK: - Public Methods
    
    /// Load initial feeds
    func loadInitialFeeds() async {
        async let forYou: () = loadForYouFeed(refresh: true)
        async let following: () = loadFollowingFeed(refresh: true)
        _ = await (forYou, following)
    }
    
    /// Load For You feed
    func loadForYouFeed(refresh: Bool = false) async {
        guard !isLoadingForYou else { return }
        
        if refresh {
            forYouOffset = 0
            hasMoreForYou = true
        }
        
        guard hasMoreForYou else { return }
        
        isLoadingForYou = true
        defer { isLoadingForYou = false }
        
        do {
            let posts = try await fetchForYouPosts(offset: forYouOffset, limit: pageSize)
            
            if refresh {
                forYouPosts = posts
            } else {
                forYouPosts.append(contentsOf: posts)
            }
            
            forYouOffset += posts.count
            hasMoreForYou = posts.count == pageSize
        } catch {
            print("❌ Feed: Failed to load For You - \(error.localizedDescription)")
        }
    }
    
    /// Load Following feed
    func loadFollowingFeed(refresh: Bool = false) async {
        guard !isLoadingFollowing, let userId = currentUserId else { return }
        
        if refresh {
            followingOffset = 0
            hasMoreFollowing = true
        }
        
        guard hasMoreFollowing else { return }
        
        isLoadingFollowing = true
        defer { isLoadingFollowing = false }
        
        do {
            let posts = try await fetchFollowingPosts(
                userId: userId,
                offset: followingOffset,
                limit: pageSize
            )
            
            if refresh {
                followingPosts = posts
            } else {
                followingPosts.append(contentsOf: posts)
            }
            
            followingOffset += posts.count
            hasMoreFollowing = posts.count == pageSize
        } catch {
            print("❌ Feed: Failed to load Following - \(error.localizedDescription)")
        }
    }
    
    /// Load posts by mode
    func loadPosts(mode: FeedMode, offset: Int = 0, limit: Int = 20) async throws -> [Post] {
        let postTypes = mode.postTypes
        
        guard !postTypes.isEmpty else {
            // For study and live modes, return empty (handled differently)
            return []
        }
        
        let typeValues = postTypes.map { $0.rawValue }
        
        let query = supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .in("type", values: typeValues)
            .eq("visibility", value: "public")
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
        
        let posts: [Post] = try await query.execute().value
        
        return try await enrichPosts(posts)
    }
    
    /// Load posts for a specific group
    func loadGroupPosts(groupId: UUID, offset: Int = 0, limit: Int = 20) async throws -> [Post] {
        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .eq("group_id", value: groupId.uuidString)
            .is("deleted_at", value: nil)
            .order("is_pinned", ascending: false)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return try await enrichPosts(posts)
    }
    
    /// Load posts by a specific user
    func loadUserPosts(userId: UUID, offset: Int = 0, limit: Int = 20) async throws -> [Post] {
        let posts: [Post]
        
        // If viewing own posts, show all. Otherwise only public
        if userId == currentUserId {
            posts = try await supabase
                .from("posts")
                .select("*, author:community_profiles!author_id(*)")
                .eq("author_id", value: userId.uuidString)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        } else {
            posts = try await supabase
                .from("posts")
                .select("*, author:community_profiles!author_id(*)")
                .eq("author_id", value: userId.uuidString)
                .eq("visibility", value: "public")
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        }
        
        return try await enrichPosts(posts)
    }
    
    /// Load a single post by ID
    func loadPost(id: UUID) async throws -> Post? {
        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .eq("id", value: id.uuidString)
            .is("deleted_at", value: nil)
            .execute()
            .value
        
        guard let post = posts.first else { return nil }
        
        let enriched = try await enrichPosts([post])
        return enriched.first
    }
    
    /// Refresh a post in the feeds
    func refreshPost(_ postId: UUID) async {
        guard let updatedPost = try? await loadPost(id: postId) else { return }
        
        // Update in For You
        if let index = forYouPosts.firstIndex(where: { $0.id == postId }) {
            forYouPosts[index] = updatedPost
        }
        
        // Update in Following
        if let index = followingPosts.firstIndex(where: { $0.id == postId }) {
            followingPosts[index] = updatedPost
        }
    }
    
    /// Add a new post to feeds
    func addPost(_ post: Post) {
        // Add to For You (all posts appear there)
        forYouPosts.insert(post, at: 0)
        
        // Add to Following if it's the current user's post
        if post.authorId == currentUserId {
            followingPosts.insert(post, at: 0)
        }
    }
    
    /// Remove a post from feeds
    func removePost(_ postId: UUID) {
        forYouPosts.removeAll { $0.id == postId }
        followingPosts.removeAll { $0.id == postId }
    }
    
    // MARK: - Private Methods
    
    private func fetchForYouPosts(offset: Int, limit: Int) async throws -> [Post] {
        // For You algorithm: Recent posts with some engagement weighting
        // Simple version: ordered by recency with public visibility
        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .eq("visibility", value: "public")
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return try await enrichPosts(posts)
    }
    
    private func fetchFollowingPosts(userId: UUID, offset: Int, limit: Int) async throws -> [Post] {
        // Get IDs of users being followed
        let follows: [Follow] = try await supabase
            .from("follows")
            .select("followee_id")
            .eq("follower_id", value: userId.uuidString)
            .eq("state", value: "active")
            .execute()
            .value
        
        let followeeIds = follows.map { $0.followeeId.uuidString }
        
        // Include current user's posts
        var allIds = followeeIds
        allIds.append(userId.uuidString)
        
        guard !allIds.isEmpty else { return [] }
        
        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .in("author_id", values: allIds)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return try await enrichPosts(posts)
    }
    
    /// Enrich posts with user reactions and bookmark status
    private func enrichPosts(_ posts: [Post]) async throws -> [Post] {
        guard let userId = currentUserId, !posts.isEmpty else { return posts }
        
        let postIds = posts.map { $0.id.uuidString }
        
        // Get user's reactions on these posts
        let reactions: [Reaction] = try await supabase
            .from("reactions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("target_type", value: "post")
            .in("target_id", values: postIds)
            .execute()
            .value
        
        // Map reactions by post ID
        let reactionsByPost = Dictionary(grouping: reactions) { $0.targetId }
        
        // Enrich posts
        return posts.map { post in
            var enrichedPost = post
            enrichedPost.userReactions = reactionsByPost[post.id]?.map { $0.reactionType } ?? []
            return enrichedPost
        }
    }
}

