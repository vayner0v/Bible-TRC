//
//  InspireModeView.swift
//  Bible v1
//
//  Community Tab - Inspire Mode (Testimonies, Verse Cards, Photos)
//

import SwiftUI

struct InspireModeView: View {
    @StateObject private var viewModel = FeedViewModel(mode: .inspire)
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Feed Type Toggle
                feedTypeToggle
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    loadingView
                } else if viewModel.posts.isEmpty {
                    emptyView
                } else {
                    // Posts
                    ForEach(viewModel.posts) { post in
                        PostCardView(post: post)
                            .onAppear {
                                viewModel.onPostAppear(post)
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
    
    private var feedTypeToggle: some View {
        HStack(spacing: 0) {
            ForEach(FeedType.allCases) { type in
                Button {
                    // Switch feed type
                } label: {
                    Text(type.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
            
            Text("No Inspirations Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("Be the first to share a testimony, verse card, or inspiring image!")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

#Preview {
    InspireModeView()
        .environmentObject(ThemeManager.shared)
}

