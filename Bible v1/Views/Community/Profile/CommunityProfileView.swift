//
//  CommunityProfileView.swift
//  Bible v1
//
//  Community Tab - Profile View
//

import SwiftUI

struct CommunityProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    init(userId: UUID) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                profileHeader
                
                // Stats
                statsSection
                
                // Bio & Info
                if let profile = viewModel.profile {
                    bioSection(profile)
                }
                
                Divider()
                    .padding(.vertical)
                
                // Posts
                postsSection
            }
        }
        .background(themeManager.backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            if let profile = viewModel.profile {
                UserAvatarView(
                    profile: CommunityProfileSummary(from: profile),
                    size: 100
                )
            } else {
                Circle()
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .shimmering()
            }
            
            // Name & Username
            VStack(spacing: 4) {
                if let profile = viewModel.profile {
                    HStack(spacing: 6) {
                        Text(profile.displayName)
                            .font(.system(size: 22, weight: .bold))
                        
                        if profile.isVerified, let type = profile.verificationType {
                            Image(systemName: type.icon)
                                .font(.system(size: 16))
                                .foregroundColor(type.badgeColor)
                        }
                    }
                    
                    if let username = profile.username {
                        Text("@\(username)")
                            .font(.system(size: 15))
                            .foregroundColor(themeManager.textColor.opacity(0.6))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.backgroundColor.opacity(0.3))
                        .frame(width: 150, height: 22)
                        .shimmering()
                }
            }
            .foregroundColor(themeManager.textColor)
            
            // Action Buttons
            if !viewModel.isCurrentUser {
                HStack(spacing: 12) {
                    FollowButton(
                        isFollowing: viewModel.followStatus.isFollowing,
                        isLoading: viewModel.isFollowLoading
                    ) {
                        Task { await viewModel.toggleFollow() }
                    }
                    
                    Button {
                        // Send message
                    } label: {
                        Image(systemName: "envelope")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.textColor)
                            .frame(width: 44, height: 36)
                            .background(themeManager.backgroundColor.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Menu {
                        Button("Report") {
                            viewModel.showReportSheet = true
                        }
                        Button("Block", role: .destructive) {
                            viewModel.showBlockConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.textColor)
                            .frame(width: 44, height: 36)
                            .background(themeManager.backgroundColor.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else {
                Button {
                    viewModel.showEditProfile = true
                } label: {
                    Text("Edit Profile")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(themeManager.backgroundColor.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(
                value: viewModel.profile?.postCount ?? 0,
                label: "Posts"
            )
            
            Divider()
                .frame(height: 30)
            
            NavigationLink(value: CommunityDestination.profile(viewModel.userId)) {
                statItem(
                    value: viewModel.profile?.followerCount ?? 0,
                    label: "Followers"
                )
            }
            
            Divider()
                .frame(height: 30)
            
            NavigationLink(value: CommunityDestination.profile(viewModel.userId)) {
                statItem(
                    value: viewModel.profile?.followingCount ?? 0,
                    label: "Following"
                )
            }
            
            Divider()
                .frame(height: 30)
            
            statItem(
                value: viewModel.profile?.prayerCount ?? 0,
                label: "Prayers"
            )
        }
        .padding(.vertical, 16)
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeManager.textColor)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(themeManager.textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Bio Section
    
    private func bioSection(_ profile: CommunityProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 15))
                    .foregroundColor(themeManager.textColor)
            }
            
            // Info chips
            VStack(alignment: .leading, spacing: 8) {
                if let church = profile.churchName {
                    infoChip(icon: "building.columns", text: church)
                }
                
                if let denomination = profile.denomination {
                    infoChip(icon: "cross", text: denomination)
                }
                
                if let location = profile.locationCity {
                    infoChip(icon: "location", text: location)
                }
                
                if let favoriteVerse = profile.favoriteVerseRef {
                    infoChip(icon: "book", text: "\(favoriteVerse.book) \(favoriteVerse.chapter):\(favoriteVerse.verse)")
                }
            }
            
            // Badges
            if !profile.badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(profile.badges) { badge in
                            HStack(spacing: 4) {
                                Image(systemName: badge.icon)
                                Text(badge.displayName)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(badge.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(badge.color.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(themeManager.accentColor)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(themeManager.textColor.opacity(0.8))
        }
    }
    
    // MARK: - Posts Section
    
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Posts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
                .padding(.horizontal)
            
            if viewModel.isLoadingPosts {
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        PostCardSkeleton()
                    }
                }
                .padding(.horizontal)
            } else if viewModel.posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.textColor.opacity(0.3))
                    
                    Text("No posts yet")
                        .font(.system(size: 15))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        PostCardView(post: post)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CommunityProfileView(userId: UUID())
    }
    .environmentObject(ThemeManager.shared)
}

