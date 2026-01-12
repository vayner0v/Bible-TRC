//
//  PostService.swift
//  Bible v1
//
//  Community Tab - Post Service
//

import Foundation
import Supabase

/// Service for managing posts
@MainActor
final class PostService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Create
    
    /// Create a new post
    func createPost(_ request: CreatePostRequest, authorId: UUID) async throws -> Post {
        // Validate content
        guard !request.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommunityError.validation("Post content cannot be empty")
        }
        
        // Validate verse card has verse
        if request.type == .verseCard && request.verseRef == nil {
            throw CommunityError.validation("Verse cards must include a verse reference")
        }
        
        // Create post
        let post = Post(
            authorId: authorId,
            type: request.type,
            content: request.content,
            verseRef: request.verseRef,
            reflectionType: request.reflectionType,
            tone: request.tone,
            tags: request.tags,
            mediaUrls: request.mediaUrls,
            verseCardConfig: request.verseCardConfig,
            visibility: request.visibility,
            groupId: request.groupId,
            isAnonymous: request.isAnonymous,
            allowComments: request.allowComments
        )
        
        let createdPost: Post = try await supabase
            .from("posts")
            .insert(post)
            .select("*, author:community_profiles!author_id(*)")
            .single()
            .execute()
            .value
        
        // If it's a prayer request, create the prayer_requests entry
        if request.type == .prayer {
            try await createPrayerRequestEntry(for: createdPost.id)
        }
        
        return createdPost
    }
    
    /// Create prayer request entry
    private func createPrayerRequestEntry(for postId: UUID) async throws {
        let prayerRequest = CommunityPrayerRequest(
            postId: postId,
            category: .other,
            urgency: .normal,
            durationDays: 7,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        
        try await supabase
            .from("prayer_requests")
            .insert(prayerRequest)
            .execute()
    }
    
    // MARK: - Read
    
    /// Get a post by ID
    func getPost(id: UUID) async throws -> Post? {
        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .eq("id", value: id.uuidString)
            .is("deleted_at", value: nil)
            .execute()
            .value
        
        return posts.first
    }
    
    /// Get posts by IDs
    func getPosts(ids: [UUID]) async throws -> [Post] {
        guard !ids.isEmpty else { return [] }
        
        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .in("id", values: ids.map { $0.uuidString })
            .is("deleted_at", value: nil)
            .execute()
            .value
        
        return posts
    }
    
    // MARK: - Update
    
    /// Update a post
    func updatePost(id: UUID, content: String?, tags: [String]?, allowComments: Bool?) async throws -> Post {
        var updates: [String: AnyEncodable] = [
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        if let content = content {
            guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CommunityError.validation("Post content cannot be empty")
            }
            updates["content"] = AnyEncodable(content)
        }
        
        if let tags = tags {
            updates["tags"] = AnyEncodable(tags)
        }
        
        if let allowComments = allowComments {
            updates["allow_comments"] = AnyEncodable(allowComments)
        }
        
        let updatedPost: Post = try await supabase
            .from("posts")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select("*, author:community_profiles!author_id(*)")
            .single()
            .execute()
            .value
        
        return updatedPost
    }
    
    /// Pin/unpin a post in a group
    func togglePinPost(id: UUID, isPinned: Bool) async throws {
        try await supabase
            .from("posts")
            .update(["is_pinned": isPinned])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Delete
    
    /// Soft delete a post
    func deletePost(id: UUID) async throws {
        try await supabase
            .from("posts")
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Hard delete a post (admin only)
    func permanentlyDeletePost(id: UUID) async throws {
        try await supabase
            .from("posts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Comments
    
    /// Get comments for a post
    func getComments(postId: UUID, offset: Int = 0, limit: Int = 50) async throws -> [Comment] {
        let comments: [Comment] = try await supabase
            .from("comments")
            .select("*, author:community_profiles!author_id(*)")
            .eq("post_id", value: postId.uuidString)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: true)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return comments
    }
    
    /// Create a comment
    func createComment(_ request: CreateCommentRequest, authorId: UUID) async throws -> Comment {
        guard !request.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommunityError.validation("Comment cannot be empty")
        }
        
        // Calculate depth
        var depth = 0
        if let parentId = request.parentCommentId {
            let parents: [Comment] = try await supabase
                .from("comments")
                .select("depth")
                .eq("id", value: parentId.uuidString)
                .execute()
                .value
            
            if let parent = parents.first {
                depth = parent.depth + 1
            }
        }
        
        let comment = Comment(
            postId: request.postId,
            authorId: authorId,
            parentCommentId: request.parentCommentId,
            depth: depth,
            content: request.content,
            isAnonymous: request.isAnonymous
        )
        
        let createdComment: Comment = try await supabase
            .from("comments")
            .insert(comment)
            .select("*, author:community_profiles!author_id(*)")
            .single()
            .execute()
            .value
        
        return createdComment
    }
    
    /// Delete a comment
    func deleteComment(id: UUID) async throws {
        try await supabase
            .from("comments")
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Mark comment as best answer
    func markBestAnswer(commentId: UUID, postId: UUID) async throws {
        // First, unmark any existing best answer
        try await supabase
            .from("comments")
            .update(["is_best_answer": false])
            .eq("post_id", value: postId.uuidString)
            .execute()
        
        // Mark the new best answer
        try await supabase
            .from("comments")
            .update(["is_best_answer": true])
            .eq("id", value: commentId.uuidString)
            .execute()
    }
    
    // MARK: - Search
    
    /// Search posts
    func searchPosts(query: String, type: PostType? = nil, offset: Int = 0, limit: Int = 20) async throws -> [Post] {
        var queryBuilder = supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .eq("visibility", value: "public")
            .is("deleted_at", value: nil)
            .ilike("content", pattern: "%\(query)%")
        
        if let type = type {
            queryBuilder = queryBuilder.eq("type", value: type.rawValue)
        }
        
        let posts: [Post] = try await queryBuilder
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return posts
    }
    
    /// Search posts by tag
    func searchByTag(tag: String, offset: Int = 0, limit: Int = 20) async throws -> [Post] {
        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, author:community_profiles!author_id(*)")
            .eq("visibility", value: "public")
            .is("deleted_at", value: nil)
            .contains("tags", value: [tag])
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return posts
    }
}

