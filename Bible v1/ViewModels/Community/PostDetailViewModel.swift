//
//  PostDetailViewModel.swift
//  Bible v1
//
//  Community Tab - Post Detail View Model
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PostDetailViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var post: Post?
    @Published private(set) var comments: [Comment] = []
    @Published private(set) var commentThreads: [CommentThread] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingComments = false
    @Published private(set) var isSendingComment = false
    @Published var error: CommunityError?
    @Published var newCommentText = ""
    @Published var replyingTo: Comment?
    @Published var showDeleteConfirmation = false
    @Published var showReportSheet = false
    
    // MARK: - Properties
    
    let postId: UUID
    
    private var postService: PostService { CommunityService.shared.postService }
    private var reactionService: ReactionService { CommunityService.shared.reactionService }
    private var currentUserId: UUID? { CommunityService.shared.currentProfile?.id }
    
    // MARK: - Initialization
    
    init(postId: UUID) {
        self.postId = postId
    }
    
    init(post: Post) {
        self.postId = post.id
        self.post = post
    }
    
    // MARK: - Public Methods
    
    /// Load post and comments
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let postTask = postService.getPost(id: postId)
            async let commentsTask = postService.getComments(postId: postId)
            
            let (loadedPost, loadedComments) = try await (postTask, commentsTask)
            
            post = loadedPost
            comments = loadedComments
            commentThreads = CommentThread.buildThreads(from: loadedComments)
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Refresh comments
    func refreshComments() async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        
        do {
            comments = try await postService.getComments(postId: postId)
            commentThreads = CommentThread.buildThreads(from: comments)
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Toggle reaction on post
    func toggleReaction(_ type: ReactionType) async {
        guard let userId = currentUserId else { return }
        
        do {
            try await reactionService.toggleReaction(
                userId: userId,
                targetType: .post,
                targetId: postId,
                reactionType: type
            )
            
            // Refresh post to get updated engagement
            if let updatedPost = try await postService.getPost(id: postId) {
                post = updatedPost
            }
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Toggle reaction on comment
    func toggleCommentReaction(_ commentId: UUID, type: ReactionType) async {
        guard let userId = currentUserId else { return }
        
        do {
            try await reactionService.toggleReaction(
                userId: userId,
                targetType: .comment,
                targetId: commentId,
                reactionType: type
            )
            
            await refreshComments()
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Send a comment
    func sendComment() async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let userId = currentUserId else { return }
        
        isSendingComment = true
        defer {
            isSendingComment = false
            newCommentText = ""
            replyingTo = nil
        }
        
        do {
            let request = CreateCommentRequest(
                postId: postId,
                parentCommentId: replyingTo?.id,
                content: newCommentText,
                isAnonymous: false
            )
            
            _ = try await postService.createComment(request, authorId: userId)
            await refreshComments()
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Delete post (if author)
    func deletePost() async {
        do {
            try await postService.deletePost(id: postId)
            // Navigation will handle popping back
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Delete comment
    func deleteComment(_ commentId: UUID) async {
        do {
            try await postService.deleteComment(id: commentId)
            await refreshComments()
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Mark comment as best answer
    func markBestAnswer(_ commentId: UUID) async {
        do {
            try await postService.markBestAnswer(commentId: commentId, postId: postId)
            await refreshComments()
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Report post
    func reportPost(reason: ReportReason, description: String?) async {
        guard let userId = currentUserId else { return }
        
        do {
            let request = CreateReportRequest(
                targetType: .post,
                targetId: postId,
                reason: reason,
                description: description
            )
            try await CommunityService.shared.moderationService.createReport(request, reporterId: userId)
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Start replying to a comment
    func startReply(to comment: Comment) {
        replyingTo = comment
    }
    
    /// Cancel reply
    func cancelReply() {
        replyingTo = nil
    }
    
    /// Check if current user is the author
    var isAuthor: Bool {
        post?.authorId == currentUserId
    }
    
    /// Check if user has reacted with a specific type
    func hasReacted(_ type: ReactionType) -> Bool {
        post?.userReactions?.contains(type) ?? false
    }
}

