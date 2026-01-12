//
//  UserSuggestion.swift
//  Bible v1
//
//  Community Tab - User Suggestion Model
//

import Foundation

/// A suggested user to follow
struct UserSuggestion: Identifiable, Codable {
    let id: UUID
    let user: CommunityProfileSummary
    let reason: SuggestionReason
    let score: Double
    let mutualFollowers: Int?
    let mutualFollowerSamples: [CommunityProfileSummary]?
    let commonTopics: [String]?
    let commonVerses: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, user, reason, score
        case mutualFollowers = "mutual_followers"
        case mutualFollowerSamples = "mutual_follower_samples"
        case commonTopics = "common_topics"
        case commonVerses = "common_verses"
    }
    
    init(
        id: UUID = UUID(),
        user: CommunityProfileSummary,
        reason: SuggestionReason,
        score: Double = 0,
        mutualFollowers: Int? = nil,
        mutualFollowerSamples: [CommunityProfileSummary]? = nil,
        commonTopics: [String]? = nil,
        commonVerses: [String]? = nil
    ) {
        self.id = id
        self.user = user
        self.reason = reason
        self.score = score
        self.mutualFollowers = mutualFollowers
        self.mutualFollowerSamples = mutualFollowerSamples
        self.commonTopics = commonTopics
        self.commonVerses = commonVerses
    }
    
    /// Explanation text for why this user is suggested
    var reasonText: String {
        switch reason {
        case .mutualFollowers:
            if let count = mutualFollowers, count > 0 {
                return "Followed by \(count) people you follow"
            }
            return "People you follow also follow them"
        case .similarReading:
            if let topics = commonTopics, !topics.isEmpty {
                return "Also interested in \(topics.prefix(2).joined(separator: ", "))"
            }
            return "Similar reading interests"
        case .sameChurch:
            return "From your church"
        case .sameGroup:
            return "In a group with you"
        case .nearby:
            return "In your area"
        case .popular:
            return "Popular in the community"
        case .newUser:
            return "New to the community"
        }
    }
}

/// Reasons for user suggestions
enum SuggestionReason: String, Codable, CaseIterable {
    case mutualFollowers = "mutual_followers"
    case similarReading = "similar_reading"
    case sameChurch = "same_church"
    case sameGroup = "same_group"
    case nearby = "nearby"
    case popular = "popular"
    case newUser = "new_user"
    
    var displayName: String {
        switch self {
        case .mutualFollowers: return "Mutual Connections"
        case .similarReading: return "Similar Interests"
        case .sameChurch: return "Same Church"
        case .sameGroup: return "Same Group"
        case .nearby: return "Nearby"
        case .popular: return "Popular"
        case .newUser: return "New Member"
        }
    }
    
    var priority: Int {
        switch self {
        case .mutualFollowers: return 1
        case .sameChurch: return 2
        case .sameGroup: return 3
        case .similarReading: return 4
        case .nearby: return 5
        case .popular: return 6
        case .newUser: return 7
        }
    }
}

/// Group suggestion
struct GroupSuggestion: Identifiable, Codable {
    let id: UUID
    let group: GroupSummary
    let reason: GroupSuggestionReason
    let score: Double
    let membersSample: [CommunityProfileSummary]?
    
    enum CodingKeys: String, CodingKey {
        case id, group, reason, score
        case membersSample = "members_sample"
    }
    
    init(
        id: UUID = UUID(),
        group: GroupSummary,
        reason: GroupSuggestionReason,
        score: Double,
        membersSample: [CommunityProfileSummary]? = nil
    ) {
        self.id = id
        self.group = group
        self.reason = reason
        self.score = score
        self.membersSample = membersSample
    }
}

/// Reasons for group suggestions
enum GroupSuggestionReason: String, Codable {
    case followersInGroup = "followers_in_group"
    case matchingTopics = "matching_topics"
    case matchingReadingPlan = "matching_reading_plan"
    case nearby = "nearby"
    case popular = "popular"
    
    var displayName: String {
        switch self {
        case .followersInGroup: return "People you follow are here"
        case .matchingTopics: return "Matches your interests"
        case .matchingReadingPlan: return "Following similar plans"
        case .nearby: return "In your area"
        case .popular: return "Popular group"
        }
    }
}

