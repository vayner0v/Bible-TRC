//
//  FeedViewModel.swift
//  Bible v1
//
//  Community Tab - Feed View Model
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published var error: CommunityError?
    
    // MARK: - Properties
    
    let feedType: FeedType
    let mode: FeedMode?
    
    private var feedService: FeedService { CommunityService.shared.feedService }
    private var offset = 0
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(feedType: FeedType = .forYou, mode: FeedMode? = nil) {
        self.feedType = feedType
        self.mode = mode
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Load initial feed
    func load() async {
        guard !isLoading else { return }
        
        isLoading = true
        offset = 0
        hasMore = true
        
        defer { isLoading = false }
        
        do {
            if let mode = mode {
                // Load mode-specific feed
                posts = try await feedService.loadPosts(mode: mode, offset: 0, limit: pageSize)
            } else {
                // Use cached feeds
                switch feedType {
                case .forYou:
                    await feedService.loadForYouFeed(refresh: true)
                    posts = feedService.forYouPosts
                case .following:
                    await feedService.loadFollowingFeed(refresh: true)
                    posts = feedService.followingPosts
                }
            }
            
            hasMore = posts.count >= pageSize
            offset = posts.count
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Refresh feed
    func refresh() async {
        await load()
    }
    
    /// Load more posts
    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let newPosts: [Post]
            
            if let mode = mode {
                newPosts = try await feedService.loadPosts(mode: mode, offset: offset, limit: pageSize)
            } else {
                switch feedType {
                case .forYou:
                    await feedService.loadForYouFeed()
                    newPosts = Array(feedService.forYouPosts.suffix(from: offset))
                case .following:
                    await feedService.loadFollowingFeed()
                    newPosts = Array(feedService.followingPosts.suffix(from: offset))
                }
            }
            
            posts.append(contentsOf: newPosts)
            offset = posts.count
            hasMore = newPosts.count >= pageSize
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
        }
    }
    
    /// Check if should load more when post appears
    func onPostAppear(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        // Load more when near the end
        if index >= posts.count - 5 {
            Task {
                await loadMore()
            }
        }
    }
    
    /// Remove a post from feed
    func removePost(_ postId: UUID) {
        posts.removeAll { $0.id == postId }
    }
    
    /// Update a post in feed
    func updatePost(_ post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind to feed service for real-time updates
        switch feedType {
        case .forYou:
            feedService.$forYouPosts
                .receive(on: DispatchQueue.main)
                .sink { [weak self] posts in
                    guard self?.mode == nil else { return }
                    self?.posts = posts
                }
                .store(in: &cancellables)
        case .following:
            feedService.$followingPosts
                .receive(on: DispatchQueue.main)
                .sink { [weak self] posts in
                    guard self?.mode == nil else { return }
                    self?.posts = posts
                }
                .store(in: &cancellables)
        }
    }
}

