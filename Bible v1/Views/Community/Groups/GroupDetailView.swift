//
//  GroupDetailView.swift
//  Bible v1
//
//  Community Tab - Group Detail View
//

import SwiftUI

struct GroupDetailView: View {
    @StateObject private var viewModel: GroupDetailViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    init(groupId: UUID) {
        _viewModel = StateObject(wrappedValue: GroupDetailViewModel(groupId: groupId))
    }
    
    init(group: CommunityGroup) {
        _viewModel = StateObject(wrappedValue: GroupDetailViewModel(group: group))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                groupHeader
                
                // Action Buttons
                actionButtons
                
                // Tab Selector
                tabSelector
                
                // Content
                tabContent
            }
        }
        .background(themeManager.backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let group = viewModel.group {
                    Menu {
                        if group.canModerate {
                            Button {
                                viewModel.showSettings = true
                            } label: {
                                Label("Group Settings", systemImage: "gear")
                            }
                            
                            Button {
                                viewModel.showMemberManagement = true
                            } label: {
                                Label("Manage Members", systemImage: "person.2")
                            }
                        }
                        
                        Button {
                            viewModel.shareGroup()
                        } label: {
                            Label("Share Group", systemImage: "square.and.arrow.up")
                        }
                        
                        if group.isMember && !group.isOwner {
                            Button(role: .destructive) {
                                viewModel.showLeaveConfirmation = true
                            } label: {
                                Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                        
                        if !group.isOwner {
                            Button(role: .destructive) {
                                viewModel.showReportSheet = true
                            } label: {
                                Label("Report Group", systemImage: "flag")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.textColor)
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $viewModel.showSettings) {
            if let group = viewModel.group {
                GroupSettingsView(group: group)
            }
        }
        .sheet(isPresented: $viewModel.showMemberManagement) {
            if let group = viewModel.group {
                GroupMembersView(group: group)
            }
        }
        .alert("Leave Group", isPresented: $viewModel.showLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task { await viewModel.leaveGroup() }
            }
        } message: {
            Text("Are you sure you want to leave this group?")
        }
    }
    
    // MARK: - Group Header
    
    private var groupHeader: some View {
        VStack(spacing: 0) {
            // Cover Image
            ZStack(alignment: .bottom) {
                if let coverUrl = viewModel.group?.coverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        defaultCover
                    }
                    .frame(height: 160)
                    .clipped()
                } else {
                    defaultCover
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, themeManager.backgroundColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
            
            // Group Info
            VStack(spacing: 12) {
                // Avatar
                groupAvatar
                    .offset(y: -40)
                    .padding(.bottom, -40)
                
                // Name & Verification
                HStack(spacing: 8) {
                    Text(viewModel.group?.name ?? "")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.textColor)
                    
                    if viewModel.group?.isVerifiedChurch == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                }
                
                // Type & Privacy
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.group?.type.icon ?? "person.3")
                            .font(.system(size: 12))
                        Text(viewModel.group?.type.displayName ?? "")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(viewModel.group?.type.color ?? .blue)
                    
                    Text("•")
                        .foregroundColor(themeManager.textColor.opacity(0.4))
                    
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.group?.privacy == .public ? "globe" : "lock.fill")
                            .font(.system(size: 11))
                        Text(viewModel.group?.privacy.rawValue.capitalized ?? "")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(themeManager.textColor.opacity(0.6))
                }
                
                // Stats
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("\(viewModel.group?.memberCount ?? 0)")
                            .font(.system(size: 18, weight: .bold))
                        Text("Members")
                            .font(.system(size: 12))
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(viewModel.group?.postCount ?? 0)")
                            .font(.system(size: 18, weight: .bold))
                        Text("Posts")
                            .font(.system(size: 12))
                    }
                }
                .foregroundColor(themeManager.textColor)
                
                // Description
                if let description = viewModel.group?.description {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private var defaultCover: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        (viewModel.group?.type.color ?? .blue).opacity(0.6),
                        (viewModel.group?.type.color ?? .blue).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 160)
    }
    
    private var groupAvatar: some View {
        Group {
            if let avatarUrl = viewModel.group?.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultGroupAvatar
                }
            } else {
                defaultGroupAvatar
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeManager.backgroundColor, lineWidth: 4)
        )
    }
    
    private var defaultGroupAvatar: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(viewModel.group?.type.color.opacity(0.3) ?? .blue.opacity(0.3))
            .overlay(
                Image(systemName: viewModel.group?.type.icon ?? "person.3")
                    .font(.system(size: 30))
                    .foregroundColor(viewModel.group?.type.color ?? .blue)
            )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if let group = viewModel.group {
                if group.isMember {
                    // Create Post Button
                    Button {
                        viewModel.showComposer = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Post")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeManager.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    // Invite Button
                    Button {
                        viewModel.showInvite = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.plus")
                            Text("Invite")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeManager.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                } else {
                    // Join Button
                    Button {
                        Task { await viewModel.joinGroup() }
                    } label: {
                        HStack(spacing: 6) {
                            if viewModel.isJoining {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.badge.plus")
                                Text(group.requiresApproval ? "Request to Join" : "Join Group")
                            }
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeManager.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(viewModel.isJoining)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(GroupTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                            Text(tab.displayName)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(
                            viewModel.selectedTab == tab
                                ? themeManager.accentColor
                                : themeManager.textColor.opacity(0.5)
                        )
                        
                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? themeManager.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .posts:
            groupPosts
        case .about:
            groupAbout
        case .members:
            groupMembers
        case .events:
            groupEvents
        }
    }
    
    private var groupPosts: some View {
        LazyVStack(spacing: 16) {
            if viewModel.isLoadingPosts && viewModel.posts.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    PostCardSkeleton()
                }
            } else if viewModel.posts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.textColor.opacity(0.3))
                    
                    Text("No posts yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.textColor.opacity(0.6))
                    
                    if viewModel.group?.isMember == true {
                        Button("Create the first post") {
                            viewModel.showComposer = true
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                    }
                }
                .padding(.vertical, 60)
            } else {
                ForEach(viewModel.posts) { post in
                    PostCardView(post: post)
                }
            }
        }
        .padding()
    }
    
    private var groupAbout: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            if let description = viewModel.group?.description {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textColor.opacity(0.8))
                }
            }
            
            // Rules
            if let rules = viewModel.group?.rules, !rules.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Group Rules")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                    
                    ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1).")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.accentColor)
                            
                            Text(rule)
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.textColor.opacity(0.8))
                        }
                    }
                }
                .padding()
                .background(themeManager.backgroundColor.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Weekly Prompt
            if let prompt = viewModel.group?.weeklyPrompt {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("This Week's Discussion")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(themeManager.textColor)
                    
                    Text(prompt)
                        .font(.system(size: 15))
                        .foregroundColor(themeManager.textColor.opacity(0.9))
                        .italic()
                }
                .padding()
                .background(themeManager.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Creator
            if let creator = viewModel.group?.creator {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Created by")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                    
                    NavigationLink(value: CommunityDestination.profile(creator.id)) {
                        HStack(spacing: 10) {
                            UserAvatarView(profile: creator, size: 36)
                            
                            Text(creator.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(themeManager.textColor)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.textColor.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private var groupMembers: some View {
        LazyVStack(spacing: 0) {
            if viewModel.isLoadingMembers && viewModel.members.isEmpty {
                ProgressView()
                    .padding()
            } else {
                ForEach(viewModel.members, id: \.userId) { member in
                    if let profile = member.user {
                        NavigationLink(value: CommunityDestination.profile(profile.id)) {
                            HStack(spacing: 12) {
                                UserAvatarView(profile: profile, size: 44)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(profile.displayName)
                                            .font(.system(size: 15, weight: .semibold))
                                        
                                        if profile.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Text(member.role.displayName)
                                        .font(.system(size: 12))
                                        .foregroundColor(member.role.roleColor)
                                }
                                .foregroundColor(themeManager.textColor)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.textColor.opacity(0.3))
                            }
                            .padding()
                        }
                        
                        Divider()
                            .padding(.leading, 70)
                    }
                }
            }
        }
    }
    
    private var groupEvents: some View {
        VStack(spacing: 16) {
            if viewModel.events.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.textColor.opacity(0.3))
                    
                    Text("No upcoming events")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.textColor.opacity(0.6))
                }
                .padding(.vertical, 60)
            } else {
                ForEach(viewModel.events) { event in
                    GroupEventCard(event: event)
                }
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct GroupSettingsView: View {
    let group: CommunityGroup
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    HStack {
                        Text("Group Name")
                        Spacer()
                        Text(group.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Privacy")
                        Spacer()
                        Text(group.privacy.rawValue.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Permissions") {
                    Toggle("Allow Member Posts", isOn: .constant(group.settings.allowMemberPosts))
                    Toggle("Require Post Approval", isOn: .constant(group.settings.requirePostApproval))
                    Toggle("Allow Anonymous Posts", isOn: .constant(group.settings.allowAnonymousPosts))
                }
            }
            .navigationTitle("Group Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct GroupMembersView: View {
    let group: CommunityGroup
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            Text("Member Management")
                .navigationTitle("Members")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct GroupEventCard: View {
    let event: GroupEvent
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                    
                    Text(formatDate(event.scheduledAt))
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textColor.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.textColor.opacity(0.3))
            }
            
            if let description = event.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

enum GroupTab: String, CaseIterable, Identifiable {
    case posts, about, members, events
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .posts: return "doc.text"
        case .about: return "info.circle"
        case .members: return "person.2"
        case .events: return "calendar"
        }
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(groupId: UUID())
    }
    .environmentObject(ThemeManager.shared)
}

