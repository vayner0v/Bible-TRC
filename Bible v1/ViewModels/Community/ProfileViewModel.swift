//
//  ProfileViewModel.swift
//  Bible v1
//
//  Community Tab - Profile View Model
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var profile: CommunityProfile?
    @Published private(set) var posts: [Post] = []
    @Published private(set) var followStatus: FollowStatus = .notFollowing
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingPosts = false
    @Published private(set) var isFollowLoading = false
    @Published var error: CommunityError?
    @Published var showEditProfile = false
    @Published var showBlockConfirmation = false
    @Published var showReportSheet = false
    
    // MARK: - Properties
    
    let userId: UUID
    
    private var profileService: ProfileService { CommunityService.shared.profileService }
    private var followService: FollowService { CommunityService.shared.followService }
    private var feedService: FeedService { CommunityService.shared.feedService }
    private var currentUserId: UUID? { CommunityService.shared.currentProfile?.id }
    
    private var offset = 0
    private let pageSize = 20
    
    var isCurrentUser: Bool {
        userId == currentUserId
    }
    
    // MARK: - Initialization
    
    init(userId: UUID) {
        self.userId = userId
    }
    
    // MARK: - Public Methods
    
    /// Load profile data
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let profileTask = profileService.getProfile(userId: userId)
            async let postsTask = feedService.loadUserPosts(userId: userId, offset: 0, limit: pageSize)
            
            let (loadedProfile, loadedPosts) = try await (profileTask, postsTask)
            
            profile = loadedProfile
            posts = loadedPosts
            offset = loadedPosts.count
            
            // Load follow status if not current user
            if !isCurrentUser, let currentId = currentUserId {
                followStatus = try await followService.getFollowStatus(userId: currentId, targetId: userId)
            }
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Load more posts
    func loadMorePosts() async {
        guard !isLoadingPosts else { return }
        
        isLoadingPosts = true
        defer { isLoadingPosts = false }
        
        do {
            let newPosts = try await feedService.loadUserPosts(userId: userId, offset: offset, limit: pageSize)
            posts.append(contentsOf: newPosts)
            offset = posts.count
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Toggle follow
    func toggleFollow() async {
        guard let currentId = currentUserId, !isFollowLoading else { return }
        
        isFollowLoading = true
        defer { isFollowLoading = false }
        
        do {
            if followStatus.isFollowing {
                try await followService.unfollow(followerId: currentId, followeeId: userId)
            } else {
                try await followService.follow(followerId: currentId, followeeId: userId)
            }
            
            // Refresh follow status
            followStatus = try await followService.getFollowStatus(userId: currentId, targetId: userId)
            
            // Refresh profile for updated follower count
            profile = try await profileService.getProfile(userId: userId)
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Block user
    func blockUser() async {
        guard let currentId = currentUserId else { return }
        
        do {
            try await followService.blockUser(blockerId: currentId, blockedId: userId)
            followStatus = try await followService.getFollowStatus(userId: currentId, targetId: userId)
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Unblock user
    func unblockUser() async {
        guard let currentId = currentUserId else { return }
        
        do {
            try await followService.unblockUser(blockerId: currentId, blockedId: userId)
            followStatus = try await followService.getFollowStatus(userId: currentId, targetId: userId)
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Report user
    func reportUser(reason: ReportReason, description: String?) async {
        guard let currentId = currentUserId else { return }
        
        do {
            let request = CreateReportRequest(
                targetType: .user,
                targetId: userId,
                reason: reason,
                description: description
            )
            try await CommunityService.shared.moderationService.createReport(request, reporterId: currentId)
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Send message request
    func sendMessageRequest(message: String?) async {
        guard let currentId = currentUserId else { return }
        
        do {
            try await CommunityService.shared.messagingService.sendMessageRequest(
                from: currentId,
                to: userId,
                message: message
            )
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
}

