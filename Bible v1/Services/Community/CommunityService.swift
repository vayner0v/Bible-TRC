//
//  CommunityService.swift
//  Bible v1
//
//  Community Tab - Main Service Coordinator
//

import Foundation
import Supabase
import Combine

/// Main coordinator service for Community features
@MainActor
final class CommunityService: ObservableObject {
    static let shared = CommunityService()
    
    // MARK: - Published State
    
    @Published private(set) var currentProfile: CommunityProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var error: CommunityError?
    @Published private(set) var isInitialized = false
    
    // MARK: - Sub-services
    
    let profileService: ProfileService
    let feedService: FeedService
    let postService: PostService
    let reactionService: ReactionService
    let followService: FollowService
    let groupService: GroupService
    let messagingService: MessagingService
    let prayerService: PrayerService
    let liveRoomService: LiveRoomService
    let verseHubService: VerseHubService
    let discoveryService: DiscoveryService
    let moderationService: CommunityModerationService
    
    // MARK: - Private
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize sub-services
        self.profileService = ProfileService()
        self.feedService = FeedService()
        self.postService = PostService()
        self.reactionService = ReactionService()
        self.followService = FollowService()
        self.groupService = GroupService()
        self.messagingService = MessagingService()
        self.prayerService = PrayerService()
        self.liveRoomService = LiveRoomService()
        self.verseHubService = VerseHubService()
        self.discoveryService = DiscoveryService()
        self.moderationService = CommunityModerationService()
        
        // Listen to auth changes
        setupAuthListener()
    }
    
    // MARK: - Public Methods
    
    /// Initialize community for current user
    func initialize() async {
        guard SupabaseService.shared.isConfigured else {
            error = .notConfigured
            return
        }
        
        guard !isInitialized else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check if user is authenticated
            let session = try await supabase.auth.session
            
            // Load or create community profile
            currentProfile = try await profileService.getOrCreateProfile(for: session.user.id)
            
            // Initialize sub-services
            await feedService.initialize(userId: session.user.id)
            
            isInitialized = true
            error = nil
            
            print("✅ Community: Initialized for user \(session.user.id)")
        } catch {
            self.error = .initialization(error.localizedDescription)
            print("❌ Community: Initialization failed - \(error.localizedDescription)")
        }
    }
    
    /// Reset community state (on sign out)
    func reset() {
        currentProfile = nil
        isInitialized = false
        error = nil
        feedService.reset()
    }
    
    /// Check if community is available
    var isAvailable: Bool {
        SupabaseService.shared.isConfigured && AuthService.shared.authState.isAuthenticated
    }
    
    // MARK: - Quick Actions
    
    /// Create a new post
    func createPost(_ request: CreatePostRequest) async throws -> Post {
        guard isInitialized, let profile = currentProfile else {
            throw CommunityError.notInitialized
        }
        
        return try await postService.createPost(request, authorId: profile.id)
    }
    
    /// Toggle reaction on a post
    func toggleReaction(on postId: UUID, type: ReactionType) async throws {
        guard isInitialized, let profile = currentProfile else {
            throw CommunityError.notInitialized
        }
        
        try await reactionService.toggleReaction(
            userId: profile.id,
            targetType: .post,
            targetId: postId,
            reactionType: type
        )
    }
    
    /// Follow a user
    func followUser(_ userId: UUID) async throws {
        guard isInitialized, let profile = currentProfile else {
            throw CommunityError.notInitialized
        }
        
        try await followService.follow(followerId: profile.id, followeeId: userId)
    }
    
    /// Unfollow a user
    func unfollowUser(_ userId: UUID) async throws {
        guard isInitialized, let profile = currentProfile else {
            throw CommunityError.notInitialized
        }
        
        try await followService.unfollow(followerId: profile.id, followeeId: userId)
    }
    
    /// Join a group
    func joinGroup(_ groupId: UUID, answers: [String: String]? = nil) async throws {
        guard isInitialized, let profile = currentProfile else {
            throw CommunityError.notInitialized
        }
        
        try await groupService.joinGroup(groupId: groupId, userId: profile.id, answers: answers)
    }
    
    /// Report content
    func reportContent(_ request: CreateReportRequest) async throws {
        guard isInitialized, let profile = currentProfile else {
            throw CommunityError.notInitialized
        }
        
        try await moderationService.createReport(request, reporterId: profile.id)
    }
    
    /// Block a user
    func blockUser(_ userId: UUID) async throws {
        guard isInitialized, let profile = currentProfile else {
            throw CommunityError.notInitialized
        }
        
        try await followService.blockUser(blockerId: profile.id, blockedId: userId)
    }
    
    /// Send a message request
    func sendMessageRequest(to userId: UUID, message: String?) async throws {
        guard isInitialized, let profile = currentProfile else {
            throw CommunityError.notInitialized
        }
        
        try await messagingService.sendMessageRequest(
            from: profile.id,
            to: userId,
            message: message
        )
    }
    
    // MARK: - Private Methods
    
    private func setupAuthListener() {
        // Listen to auth state changes
        AuthService.shared.$authState
            .sink { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .signedIn:
                        await self?.initialize()
                    case .signedOut, .localOnly:
                        self?.reset()
                    case .loading:
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Community Errors

enum CommunityError: LocalizedError {
    case notConfigured
    case notInitialized
    case notAuthenticated
    case initialization(String)
    case network(String)
    case database(String)
    case validation(String)
    case notFound
    case permissionDenied
    case rateLimited
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Community features are not configured"
        case .notInitialized:
            return "Community not initialized. Please sign in."
        case .notAuthenticated:
            return "You must be signed in to use community features"
        case .initialization(let message):
            return "Failed to initialize community: \(message)"
        case .network(let message):
            return "Network error: \(message)"
        case .database(let message):
            return "Database error: \(message)"
        case .validation(let message):
            return message
        case .notFound:
            return "The requested content was not found"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .rateLimited:
            return "You're doing that too fast. Please wait a moment."
        case .unknown(let message):
            return message
        }
    }
}

