//
//  Post.swift
//  Bible v1
//
//  Community Tab - Post Model
//

import Foundation

/// Verse reference attached to a post
struct PostVerseRef: Codable, Hashable {
    let book: String
    let chapter: Int
    let startVerse: Int
    let endVerse: Int?
    let translationId: String
    
    enum CodingKeys: String, CodingKey {
        case book, chapter
        case startVerse = "start_verse"
        case endVerse = "end_verse"
        case translationId = "translation_id"
    }
    
    /// Short reference string (e.g., "John 3:16")
    var shortReference: String {
        if let endVerse = endVerse, endVerse != startVerse {
            return "\(book) \(chapter):\(startVerse)-\(endVerse)"
        }
        return "\(book) \(chapter):\(startVerse)"
    }
    
    /// Full reference with translation (e.g., "John 3:16 (NIV)")
    var fullReference: String {
        "\(shortReference) (\(translationId.uppercased()))"
    }
}

/// Engagement counts for a post
struct PostEngagement: Codable, Hashable {
    var amen: Int
    var prayed: Int
    var love: Int
    var helpful: Int
    var curious: Int
    var hug: Int
    var comments: Int
    var shares: Int
    
    static let zero = PostEngagement(
        amen: 0, prayed: 0, love: 0, helpful: 0,
        curious: 0, hug: 0, comments: 0, shares: 0
    )
    
    /// Total reactions count
    var totalReactions: Int {
        amen + prayed + love + helpful + curious + hug
    }
}

/// A community post
struct Post: Identifiable, Codable, Hashable {
    let id: UUID
    let authorId: UUID
    let type: PostType
    var content: String
    var verseRef: PostVerseRef?
    var reflectionType: ReflectionType?
    var tone: PostTone?
    var tags: [String]
    var mediaUrls: [String]
    var verseCardConfig: VerseCardConfig?
    var visibility: PostVisibility
    var groupId: UUID?
    var isAnonymous: Bool
    var allowComments: Bool
    var isPinned: Bool
    var engagement: PostEngagement
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    
    // Joined data (not stored in posts table)
    var author: CommunityProfileSummary?
    var userReactions: [ReactionType]?
    var isBookmarked: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case type, content
        case verseRef = "verse_ref"
        case reflectionType = "reflection_type"
        case tone, tags
        case mediaUrls = "media_urls"
        case verseCardConfig = "verse_card_config"
        case visibility
        case groupId = "group_id"
        case isAnonymous = "is_anonymous"
        case allowComments = "allow_comments"
        case isPinned = "is_pinned"
        case engagement
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case author
        case userReactions = "user_reactions"
        case isBookmarked = "is_bookmarked"
    }
    
    init(
        id: UUID = UUID(),
        authorId: UUID,
        type: PostType,
        content: String,
        verseRef: PostVerseRef? = nil,
        reflectionType: ReflectionType? = nil,
        tone: PostTone? = nil,
        tags: [String] = [],
        mediaUrls: [String] = [],
        verseCardConfig: VerseCardConfig? = nil,
        visibility: PostVisibility = .public,
        groupId: UUID? = nil,
        isAnonymous: Bool = false,
        allowComments: Bool = true,
        isPinned: Bool = false,
        engagement: PostEngagement = .zero,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        author: CommunityProfileSummary? = nil,
        userReactions: [ReactionType]? = nil,
        isBookmarked: Bool? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.type = type
        self.content = content
        self.verseRef = verseRef
        self.reflectionType = reflectionType
        self.tone = tone
        self.tags = tags
        self.mediaUrls = mediaUrls
        self.verseCardConfig = verseCardConfig
        self.visibility = visibility
        self.groupId = groupId
        self.isAnonymous = isAnonymous
        self.allowComments = allowComments
        self.isPinned = isPinned
        self.engagement = engagement
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.author = author
        self.userReactions = userReactions
        self.isBookmarked = isBookmarked
    }
    
    /// Check if post has a verse attached
    var hasVerse: Bool {
        verseRef != nil
    }
    
    /// Check if post has media
    var hasMedia: Bool {
        !mediaUrls.isEmpty
    }
    
    /// Check if post is a prayer request
    var isPrayerRequest: Bool {
        type == .prayer
    }
    
    /// Check if post is a question
    var isQuestion: Bool {
        type == .question
    }
    
    /// Check if post is soft-deleted
    var isDeleted: Bool {
        deletedAt != nil
    }
    
    /// Preview text for display
    var previewText: String {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 200 {
            return String(text.prefix(200)) + "..."
        }
        return text
    }
    
    /// Relative time since creation
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

/// Post creation request
struct CreatePostRequest: Codable {
    let type: PostType
    let content: String
    let verseRef: PostVerseRef?
    let reflectionType: ReflectionType?
    let tone: PostTone?
    let tags: [String]
    let mediaUrls: [String]
    let verseCardConfig: VerseCardConfig?
    let visibility: PostVisibility
    let groupId: UUID?
    let isAnonymous: Bool
    let allowComments: Bool
    
    enum CodingKeys: String, CodingKey {
        case type, content
        case verseRef = "verse_ref"
        case reflectionType = "reflection_type"
        case tone, tags
        case mediaUrls = "media_urls"
        case verseCardConfig = "verse_card_config"
        case visibility
        case groupId = "group_id"
        case isAnonymous = "is_anonymous"
        case allowComments = "allow_comments"
    }
}

