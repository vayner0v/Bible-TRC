//
//  CommunityProfile.swift
//  Bible v1
//
//  Community Tab - User Profile Model
//

import Foundation

/// Privacy settings for a community profile
struct ProfilePrivacySettings: Codable, Hashable {
    var profileVisible: Bool
    var showActivity: Bool
    var allowMessages: MessagePermission
    
    enum MessagePermission: String, Codable {
        case everyone = "everyone"
        case followers = "followers"
        case requests = "requests"
        case nobody = "nobody"
    }
    
    static let `default` = ProfilePrivacySettings(
        profileVisible: true,
        showActivity: true,
        allowMessages: .requests
    )
    
    enum CodingKeys: String, CodingKey {
        case profileVisible = "profile_visible"
        case showActivity = "show_activity"
        case allowMessages = "allow_messages"
    }
}

/// Content filter settings for a user
struct ContentFilterSettings: Codable, Hashable {
    var hidePolitical: Bool
    var scriptureOnly: Bool
    var blockedKeywords: [String]
    
    static let `default` = ContentFilterSettings(
        hidePolitical: true,
        scriptureOnly: false,
        blockedKeywords: []
    )
    
    enum CodingKeys: String, CodingKey {
        case hidePolitical = "hide_political"
        case scriptureOnly = "scripture_only"
        case blockedKeywords = "blocked_keywords"
    }
}

/// Favorite verse reference stored in profile
struct FavoriteVerseRef: Codable, Hashable {
    let book: String
    let chapter: Int
    let verse: Int
    let translationId: String
    let text: String?
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, verse
        case translationId = "translation_id"
        case text
    }
}

/// Community profile extending auth user
struct CommunityProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var username: String?
    var avatarUrl: String?
    var bio: String?
    var testimony: String?
    var favoriteVerseRef: FavoriteVerseRef?
    var preferredTranslation: String
    var denomination: String?
    var churchName: String?
    var locationCity: String?
    var isVerified: Bool
    var verificationType: VerificationType?
    var privacySettings: ProfilePrivacySettings
    var contentFilters: ContentFilterSettings
    var followerCount: Int
    var followingCount: Int
    var postCount: Int
    var prayerCount: Int
    var badges: [ProfileBadge]
    var lastActiveAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case username
        case avatarUrl = "avatar_url"
        case bio, testimony
        case favoriteVerseRef = "favorite_verse_ref"
        case preferredTranslation = "preferred_translation"
        case denomination
        case churchName = "church_name"
        case locationCity = "location_city"
        case isVerified = "is_verified"
        case verificationType = "verification_type"
        case privacySettings = "privacy_settings"
        case contentFilters = "content_filters"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case postCount = "post_count"
        case prayerCount = "prayer_count"
        case badges
        case lastActiveAt = "last_active_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID,
        displayName: String,
        username: String? = nil,
        avatarUrl: String? = nil,
        bio: String? = nil,
        testimony: String? = nil,
        favoriteVerseRef: FavoriteVerseRef? = nil,
        preferredTranslation: String = "KJV",
        denomination: String? = nil,
        churchName: String? = nil,
        locationCity: String? = nil,
        isVerified: Bool = false,
        verificationType: VerificationType? = nil,
        privacySettings: ProfilePrivacySettings = .default,
        contentFilters: ContentFilterSettings = .default,
        followerCount: Int = 0,
        followingCount: Int = 0,
        postCount: Int = 0,
        prayerCount: Int = 0,
        badges: [ProfileBadge] = [],
        lastActiveAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.testimony = testimony
        self.favoriteVerseRef = favoriteVerseRef
        self.preferredTranslation = preferredTranslation
        self.denomination = denomination
        self.churchName = churchName
        self.locationCity = locationCity
        self.isVerified = isVerified
        self.verificationType = verificationType
        self.privacySettings = privacySettings
        self.contentFilters = contentFilters
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.postCount = postCount
        self.prayerCount = prayerCount
        self.badges = badges
        self.lastActiveAt = lastActiveAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Create a new profile for a user
    static func create(for userId: UUID, displayName: String) -> CommunityProfile {
        CommunityProfile(
            id: userId,
            displayName: displayName
        )
    }
    
    /// Profile summary for display in lists
    var summary: String {
        if let bio = bio, !bio.isEmpty {
            return bio
        }
        if let churchName = churchName {
            return churchName
        }
        if let denomination = denomination {
            return denomination
        }
        return ""
    }
    
    /// Check if profile has a complete bio section
    var hasCompleteBio: Bool {
        bio != nil && !bio!.isEmpty
    }
    
    /// Check if profile has testimony
    var hasTestimony: Bool {
        testimony != nil && !testimony!.isEmpty
    }
}

/// Lightweight profile for displaying in lists
struct CommunityProfileSummary: Identifiable, Codable, Hashable {
    let id: UUID
    let displayName: String
    let username: String?
    let avatarUrl: String?
    let isVerified: Bool
    let verificationType: VerificationType?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case username
        case avatarUrl = "avatar_url"
        case isVerified = "is_verified"
        case verificationType = "verification_type"
    }
    
    init(from profile: CommunityProfile) {
        self.id = profile.id
        self.displayName = profile.displayName
        self.username = profile.username
        self.avatarUrl = profile.avatarUrl
        self.isVerified = profile.isVerified
        self.verificationType = profile.verificationType
    }
    
    init(
        id: UUID,
        displayName: String,
        username: String? = nil,
        avatarUrl: String? = nil,
        isVerified: Bool = false,
        verificationType: VerificationType? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.avatarUrl = avatarUrl
        self.isVerified = isVerified
        self.verificationType = verificationType
    }
}

