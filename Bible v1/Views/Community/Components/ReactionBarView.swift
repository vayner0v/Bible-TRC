//
//  ReactionBarView.swift
//  Bible v1
//
//  Community Tab - Reaction Bar Component
//

import SwiftUI

struct ReactionBarView: View {
    let post: Post
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showAllReactions = false
    
    private let suggestedReactions: [ReactionType]
    
    init(post: Post) {
        self.post = post
        self.suggestedReactions = ReactionType.suggested(for: post.type)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Main reactions
            ForEach(suggestedReactions.prefix(4)) { type in
                ReactionButton(
                    type: type,
                    isSelected: post.userReactions?.contains(type) ?? false,
                    count: reactionCount(for: type)
                ) {
                    Task {
                        await toggleReaction(type)
                    }
                }
            }
            
            Spacer()
            
            // Comment
            Button {
                // Navigate to comments
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 16))
                    if post.engagement.comments > 0 {
                        Text("\(post.engagement.comments)")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .foregroundColor(themeManager.textColor.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            // Share
            Button {
                // Share post
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.textColor.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            
            // Bookmark
            BookmarkButton(isBookmarked: post.isBookmarked ?? false) {
                // Toggle bookmark
            }
        }
    }
    
    private func reactionCount(for type: ReactionType) -> Int {
        switch type {
        case .amen: return post.engagement.amen
        case .prayed: return post.engagement.prayed
        case .love: return post.engagement.love
        case .helpful: return post.engagement.helpful
        case .curious: return post.engagement.curious
        case .hug: return post.engagement.hug
        }
    }
    
    private func toggleReaction(_ type: ReactionType) async {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: type.hapticType)
        generator.impactOccurred()
        
        do {
            try await CommunityService.shared.toggleReaction(on: post.id, type: type)
            // Refresh post
            await CommunityService.shared.feedService.refreshPost(post.id)
        } catch {
            print("Error toggling reaction: \(error)")
        }
    }
}

// MARK: - Reaction Button

struct ReactionButton: View {
    let type: ReactionType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }) {
            HStack(spacing: 4) {
                Text(type.emoji)
                    .font(.system(size: 16))
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? type.color : themeManager.textColor.opacity(0.6))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? type.color.opacity(0.15)
                    : themeManager.backgroundColor.opacity(0.3).opacity(0.5)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? type.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.accessibilityLabel)
    }
}

// MARK: - Bookmark Button

struct BookmarkButton: View {
    let isBookmarked: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16))
                .foregroundColor(isBookmarked ? themeManager.accentColor : themeManager.textColor.opacity(0.6))
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Prayed Button (Special for Prayer Requests)

struct PrayedButton: View {
    let count: Int
    let hasPrayed: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.8)) {
                isAnimating = true
            }
            
            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isAnimating = false
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: hasPrayed ? "hands.sparkles.fill" : "hands.sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(hasPrayed ? .purple : themeManager.textColor.opacity(0.7))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .rotationEffect(.degrees(isAnimating ? 10 : 0))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(hasPrayed ? "Prayed" : "I Prayed")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(hasPrayed ? .purple : themeManager.textColor)
                    
                    if count > 0 {
                        Text("\(count) people praying")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.textColor.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(hasPrayed ? Color.purple.opacity(0.1) : themeManager.backgroundColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasPrayed ? Color.purple.opacity(0.3) : themeManager.textColor.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        ReactionBarView(post: Post(
            authorId: UUID(),
            type: .reflection,
            content: "Test post",
            engagement: PostEngagement(amen: 5, prayed: 3, love: 2, helpful: 1, curious: 0, hug: 1, comments: 4, shares: 2)
        ))
        
        PrayedButton(count: 12, hasPrayed: false) { }
        PrayedButton(count: 12, hasPrayed: true) { }
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}

