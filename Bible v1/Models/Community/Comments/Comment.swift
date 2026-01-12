//
//  Comment.swift
//  Bible v1
//
//  Community Tab - Comment Model
//

import Foundation

/// Engagement counts for a comment
struct CommentEngagement: Codable, Hashable {
    var amen: Int
    var prayed: Int
    var love: Int
    var helpful: Int
    var curious: Int
    var hug: Int
    
    static let zero = CommentEngagement(
        amen: 0, prayed: 0, love: 0, helpful: 0, curious: 0, hug: 0
    )
    
    /// Total reactions count
    var totalReactions: Int {
        amen + prayed + love + helpful + curious + hug
    }
}

/// A comment on a post
struct Comment: Identifiable, Codable, Hashable {
    let id: UUID
    let postId: UUID
    let authorId: UUID
    let parentCommentId: UUID?
    let depth: Int
    var content: String
    var isAnonymous: Bool
    var engagement: CommentEngagement
    var isBestAnswer: Bool
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    
    // Joined data
    var author: CommunityProfileSummary?
    var userReactions: [ReactionType]?
    var replies: [Comment]?
    var replyCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case authorId = "author_id"
        case parentCommentId = "parent_comment_id"
        case depth, content
        case isAnonymous = "is_anonymous"
        case engagement
        case isBestAnswer = "is_best_answer"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case author
        case userReactions = "user_reactions"
        case replies
        case replyCount = "reply_count"
    }
    
    init(
        id: UUID = UUID(),
        postId: UUID,
        authorId: UUID,
        parentCommentId: UUID? = nil,
        depth: Int = 0,
        content: String,
        isAnonymous: Bool = false,
        engagement: CommentEngagement = .zero,
        isBestAnswer: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        author: CommunityProfileSummary? = nil,
        userReactions: [ReactionType]? = nil,
        replies: [Comment]? = nil,
        replyCount: Int? = nil
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.parentCommentId = parentCommentId
        self.depth = depth
        self.content = content
        self.isAnonymous = isAnonymous
        self.engagement = engagement
        self.isBestAnswer = isBestAnswer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.author = author
        self.userReactions = userReactions
        self.replies = replies
        self.replyCount = replyCount
    }
    
    /// Check if this is a root comment (not a reply)
    var isRootComment: Bool {
        parentCommentId == nil
    }
    
    /// Check if this is a reply
    var isReply: Bool {
        parentCommentId != nil
    }
    
    /// Check if soft-deleted
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    /// Relative time since creation
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// Check if comment has replies
    var hasReplies: Bool {
        (replyCount ?? 0) > 0 || (replies?.isEmpty == false)
    }
}

/// Comment thread with nested replies
struct CommentThread: Identifiable, Codable {
    let id: UUID
    let rootComment: Comment
    var replies: [Comment]
    var totalCount: Int
    var hasMore: Bool
    
    init(
        id: UUID = UUID(),
        rootComment: Comment,
        replies: [Comment] = [],
        totalCount: Int = 0,
        hasMore: Bool = false
    ) {
        self.id = id
        self.rootComment = rootComment
        self.replies = replies
        self.totalCount = totalCount
        self.hasMore = hasMore
    }
    
    /// Build threads from flat comment list
    static func buildThreads(from comments: [Comment]) -> [CommentThread] {
        let rootComments = comments.filter { $0.isRootComment }
        let repliesById = Dictionary(grouping: comments.filter { $0.isReply }) { $0.parentCommentId! }
        
        return rootComments.map { root in
            CommentThread(
                id: root.id,
                rootComment: root,
                replies: buildNestedReplies(for: root.id, from: repliesById),
                totalCount: countAllReplies(for: root.id, from: repliesById)
            )
        }
    }
    
    private static func buildNestedReplies(for parentId: UUID, from repliesById: [UUID: [Comment]]) -> [Comment] {
        guard let directReplies = repliesById[parentId] else { return [] }
        return directReplies.map { reply in
            var mutableReply = reply
            mutableReply.replies = buildNestedReplies(for: reply.id, from: repliesById)
            return mutableReply
        }
    }
    
    private static func countAllReplies(for parentId: UUID, from repliesById: [UUID: [Comment]]) -> Int {
        guard let directReplies = repliesById[parentId] else { return 0 }
        return directReplies.count + directReplies.reduce(0) { $0 + countAllReplies(for: $1.id, from: repliesById) }
    }
}

/// Request to create a comment
struct CreateCommentRequest: Codable {
    let postId: UUID
    let parentCommentId: UUID?
    let content: String
    let isAnonymous: Bool
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case parentCommentId = "parent_comment_id"
        case content
        case isAnonymous = "is_anonymous"
    }
}

