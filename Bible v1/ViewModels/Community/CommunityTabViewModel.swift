//
//  CommunityTabViewModel.swift
//  Bible v1
//
//  Community Tab - Main Tab View Model
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CommunityTabViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var selectedMode: FeedMode = .inspire
    @Published var selectedFeedType: FeedType = .forYou
    @Published var isLoading = false
    @Published var error: CommunityError?
    @Published var showComposer = false
    @Published var showSearch = false
    @Published var showNotifications = false
    @Published var unreadNotificationCount = 0
    
    // MARK: - Navigation
    
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Properties
    
    private var communityService: CommunityService { CommunityService.shared }
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Initialize the community tab
    func initialize() async {
        guard !communityService.isInitialized else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await communityService.initialize()
        
        if let error = communityService.error {
            self.error = error
        }
    }
    
    /// Refresh current feed
    func refresh() async {
        await communityService.feedService.loadInitialFeeds()
    }
    
    /// Load more content
    func loadMore() async {
        switch selectedFeedType {
        case .forYou:
            await communityService.feedService.loadForYouFeed()
        case .following:
            await communityService.feedService.loadFollowingFeed()
        }
    }
    
    /// Navigate to post detail
    func navigateToPost(_ post: Post) {
        navigationPath.append(CommunityDestination.postDetail(post.id))
    }
    
    /// Navigate to profile
    func navigateToProfile(_ userId: UUID) {
        navigationPath.append(CommunityDestination.profile(userId))
    }
    
    /// Navigate to group
    func navigateToGroup(_ groupId: UUID) {
        navigationPath.append(CommunityDestination.group(groupId))
    }
    
    /// Navigate to verse hub
    func navigateToVerseHub(book: String, chapter: Int, verse: Int) {
        navigationPath.append(CommunityDestination.verseHub(book, chapter, verse))
    }
    
    /// Show post composer
    func showPostComposer(type: PostType? = nil) {
        showComposer = true
    }
    
    /// Clear error
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind to community service state
        communityService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
        
        communityService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.isLoading = loading
            }
            .store(in: &cancellables)
    }
}

// MARK: - Supporting Types

enum FeedType: String, CaseIterable, Identifiable {
    case forYou = "for_you"
    case following = "following"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .forYou: return "For You"
        case .following: return "Following"
        }
    }
}

enum CommunityDestination: Hashable {
    case postDetail(UUID)
    case profile(UUID)
    case group(UUID)
    case verseHub(String, Int, Int)
    case liveRoom(UUID)
    case conversation(UUID)
    case search(String)
    case tag(String)
}

