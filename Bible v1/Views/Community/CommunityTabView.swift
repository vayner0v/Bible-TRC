//
//  CommunityTabView.swift
//  Bible v1
//
//  Community Tab - Main Tab View
//

import SwiftUI

struct CommunityTabView: View {
    @StateObject private var viewModel = CommunityTabViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            ZStack {
                // Background
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.isLoading && !CommunityService.shared.isInitialized {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .navigationDestination(for: CommunityDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $viewModel.showComposer) {
                PostComposerView()
            }
            .sheet(isPresented: $viewModel.showSearch) {
                CommunitySearchView()
            }
            .sheet(isPresented: $viewModel.showNotifications) {
                CommunityNotificationsView()
            }
        }
        .task {
            await viewModel.initialize()
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Mode Selector
            modeSelector
            
            // Feed
            feedContent
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Community")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(themeManager.textColor)
            
            Spacer()
            
            // Search
            Button {
                viewModel.showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.textColor)
            }
            
            // Notifications
            Button {
                viewModel.showNotifications = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.textColor)
                    
                    if viewModel.unreadNotificationCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }
            
            // Create Post
            Button {
                viewModel.showComposer = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(themeManager.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedMode.allCases) { mode in
                    modeButton(mode)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    private func modeButton(_ mode: FeedMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedMode = mode
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(mode.displayName)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                viewModel.selectedMode == mode
                    ? themeManager.accentColor
                    : themeManager.backgroundColor.opacity(0.3)
            )
            .foregroundColor(
                viewModel.selectedMode == mode
                    ? .white
                    : themeManager.textColor.opacity(0.7)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Feed Content
    
    @ViewBuilder
    private var feedContent: some View {
        switch viewModel.selectedMode {
        case .inspire:
            InspireModeView()
        case .discuss:
            DiscussModeView()
        case .pray:
            PrayModeView()
        case .study:
            StudyModeView()
        case .live:
            LiveModeView()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.accentColor)
            
            Text("Loading Community...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.textColor.opacity(0.7))
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: CommunityError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to Load Community")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text(error.localizedDescription)
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                viewModel.clearError()
                Task { await viewModel.initialize() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(themeManager.accentColor)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Navigation Destinations
    
    @ViewBuilder
    private func destinationView(for destination: CommunityDestination) -> some View {
        switch destination {
        case .postDetail(let postId):
            PostDetailView(postId: postId)
        case .profile(let userId):
            CommunityProfileView(userId: userId)
        case .group(let groupId):
            GroupDetailView(groupId: groupId)
        case .verseHub(let book, let chapter, let verse):
            VerseHubView(book: book, chapter: chapter, verse: verse)
        case .liveRoom(let roomId):
            LiveRoomView(roomId: roomId)
        case .conversation(let conversationId):
            ConversationView(conversationId: conversationId)
        case .search(let query):
            CommunitySearchView(initialQuery: query)
        case .tag(let tag):
            TagFeedView(tag: tag)
        }
    }
}

// MARK: - Preview

#Preview {
    CommunityTabView()
        .environmentObject(ThemeManager.shared)
}

