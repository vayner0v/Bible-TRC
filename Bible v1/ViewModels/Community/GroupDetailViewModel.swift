//
//  GroupDetailViewModel.swift
//  Bible v1
//
//  Community Tab - Group Detail View Model
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class GroupDetailViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var group: CommunityGroup?
    @Published var posts: [Post] = []
    @Published var members: [GroupMember] = []
    @Published var events: [GroupEvent] = []
    
    @Published var selectedTab: GroupTab = .posts
    @Published var isLoading = false
    @Published var isLoadingPosts = false
    @Published var isLoadingMembers = false
    @Published var isJoining = false
    
    // Sheets
    @Published var showSettings = false
    @Published var showMemberManagement = false
    @Published var showComposer = false
    @Published var showInvite = false
    @Published var showLeaveConfirmation = false
    @Published var showReportSheet = false
    
    // MARK: - Properties
    
    private let groupId: UUID
    private var groupService: GroupService { CommunityService.shared.groupService }
    private var feedService: FeedService { CommunityService.shared.feedService }
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(groupId: UUID) {
        self.groupId = groupId
    }
    
    init(group: CommunityGroup) {
        self.groupId = group.id
        self.group = group
    }
    
    // MARK: - Public Methods
    
    func load() async {
        await loadGroup()
        await loadPosts()
        await loadMembers()
        await loadEvents()
    }
    
    func loadGroup() async {
        guard group == nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            group = try await groupService.getGroup(id: groupId)
        } catch {
            print("❌ Group: Failed to load - \(error.localizedDescription)")
        }
    }
    
    func loadPosts() async {
        isLoadingPosts = true
        defer { isLoadingPosts = false }
        
        do {
            posts = try await feedService.loadGroupPosts(groupId: groupId)
        } catch {
            print("❌ Group: Failed to load posts - \(error.localizedDescription)")
        }
    }
    
    func loadMembers() async {
        isLoadingMembers = true
        defer { isLoadingMembers = false }
        
        do {
            members = try await groupService.getMembers(groupId: groupId)
        } catch {
            print("❌ Group: Failed to load members - \(error.localizedDescription)")
        }
    }
    
    func loadEvents() async {
        do {
            events = try await groupService.getEvents(groupId: groupId)
        } catch {
            print("❌ Group: Failed to load events - \(error.localizedDescription)")
        }
    }
    
    func joinGroup() async {
        guard let userId = CommunityService.shared.currentProfile?.id else { return }
        
        isJoining = true
        defer { isJoining = false }
        
        do {
            try await groupService.joinGroup(groupId: groupId, userId: userId)
            
            // Reload group to update membership status
            group = try await groupService.getGroup(id: groupId)
        } catch {
            print("❌ Group: Failed to join - \(error.localizedDescription)")
        }
    }
    
    func leaveGroup() async {
        guard let userId = CommunityService.shared.currentProfile?.id else { return }
        
        do {
            try await groupService.leaveGroup(groupId: groupId, userId: userId)
            
            // Reload group to update membership status
            group = try await groupService.getGroup(id: groupId)
        } catch {
            print("❌ Group: Failed to leave - \(error.localizedDescription)")
        }
    }
    
    func shareGroup() {
        // Share group link
        guard let group = group else { return }
        _ = "Join '\(group.name)' on Bible App Community!"
        // TODO: Implement share sheet
    }
}

