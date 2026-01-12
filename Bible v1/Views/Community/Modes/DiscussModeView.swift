//
//  DiscussModeView.swift
//  Bible v1
//
//  Community Tab - Discuss Mode (Q&A, Threads, Conversations)
//

import SwiftUI

struct DiscussModeView: View {
    @StateObject private var viewModel = FeedViewModel(mode: .discuss)
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Filter Bar
                filterBar
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    loadingView
                } else if viewModel.posts.isEmpty {
                    emptyView
                } else {
                    // Posts
                    ForEach(viewModel.posts) { post in
                        if post.type == .question {
                            QuestionPostCard(post: post)
                        } else {
                            PostCardView(post: post)
                        }
                    }
                    
                    // Loading More
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.load()
            }
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", isSelected: true)
                filterChip("Questions", isSelected: false)
                filterChip("Reflections", isSelected: false)
                filterChip("Unanswered", isSelected: false)
            }
        }
    }
    
    private func filterChip(_ title: String, isSelected: Bool) -> some View {
        Button {
            // Handle filter
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : themeManager.textColor.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? themeManager.accentColor : themeManager.backgroundColor.opacity(0.3))
                .clipShape(Capsule())
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                PostCardSkeleton()
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
            
            Text("No Discussions Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("Start a conversation by asking a question or sharing a reflection!")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

#Preview {
    DiscussModeView()
        .environmentObject(ThemeManager.shared)
}

