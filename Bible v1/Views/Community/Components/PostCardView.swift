//
//  PostCardView.swift
//  Bible v1
//
//  Community Tab - Post Card Component
//

import SwiftUI

struct PostCardView: View {
    let post: Post
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerSection
            
            // Verse Attachment (if any)
            if let verseRef = post.verseRef {
                verseAttachment(verseRef)
            }
            
            // Content
            contentSection
            
            // Media (if any)
            if post.hasMedia {
                mediaSection
            }
            
            // Tags
            if !post.tags.isEmpty {
                tagsSection
            }
            
            // Engagement
            engagementSection
            
            // Reactions Bar
            ReactionBarView(post: post)
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            // Navigate to post detail
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 10) {
            // Avatar
            if post.isAnonymous {
                anonymousAvatar
            } else if let author = post.author {
                UserAvatarView(profile: author, size: 40)
            }
            
            // Author Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if post.isAnonymous {
                        Text("Anonymous")
                            .font(.system(size: 15, weight: .semibold))
                    } else if let author = post.author {
                        Text(author.displayName)
                            .font(.system(size: 15, weight: .semibold))
                        
                        if author.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(author.verificationType?.badgeColor ?? .blue)
                        }
                    }
                }
                .foregroundColor(themeManager.textColor)
                
                HStack(spacing: 4) {
                    // Post Type Badge
                    HStack(spacing: 3) {
                        Image(systemName: post.type.icon)
                            .font(.system(size: 10))
                        Text(post.type.displayName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(post.type.color)
                    
                    Text("•")
                        .foregroundColor(themeManager.textColor.opacity(0.4))
                    
                    Text(post.relativeTime)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                }
            }
            
            Spacer()
            
            // More Button
            Button {
                showActions = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.textColor.opacity(0.5))
                    .padding(8)
            }
        }
        .confirmationDialog("Post Actions", isPresented: $showActions) {
            Button("Share") { }
            Button("Save") { }
            Button("Report", role: .destructive) { }
        }
    }
    
    private var anonymousAvatar: some View {
        Circle()
            .fill(themeManager.accentColor.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.accentColor)
            )
    }
    
    // MARK: - Verse Attachment
    
    private func verseAttachment(_ verseRef: PostVerseRef) -> some View {
        HStack {
            Rectangle()
                .fill(themeManager.accentColor)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(verseRef.fullReference)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
            }
            
            Spacer()
            
            Image(systemName: "book.fill")
                .font(.system(size: 14))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
        }
        .padding(12)
        .background(themeManager.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Content
    
    private var contentSection: some View {
        Text(post.content)
            .font(.system(size: 15))
            .foregroundColor(themeManager.textColor)
            .lineLimit(6)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - Media
    
    private var mediaSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(post.mediaUrls, id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(themeManager.backgroundColor.opacity(0.3))
                            .shimmering()
                    }
                    .frame(width: 200, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    // MARK: - Tags
    
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(post.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(themeManager.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Engagement
    
    private var engagementSection: some View {
        HStack(spacing: 16) {
            // Reactions
            if post.engagement.totalReactions > 0 {
                HStack(spacing: -4) {
                    ForEach(Array(topReactions.prefix(3)), id: \.self) { type in
                        Text(type.emoji)
                            .font(.system(size: 14))
                    }
                }
                Text("\(post.engagement.totalReactions)")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.textColor.opacity(0.6))
            }
            
            // Comments
            if post.engagement.comments > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 13))
                    Text("\(post.engagement.comments)")
                        .font(.system(size: 13))
                }
                .foregroundColor(themeManager.textColor.opacity(0.6))
            }
            
            Spacer()
        }
    }
    
    private var topReactions: [ReactionType] {
        var types: [ReactionType] = []
        if post.engagement.amen > 0 { types.append(.amen) }
        if post.engagement.prayed > 0 { types.append(.prayed) }
        if post.engagement.love > 0 { types.append(.love) }
        if post.engagement.helpful > 0 { types.append(.helpful) }
        if post.engagement.curious > 0 { types.append(.curious) }
        if post.engagement.hug > 0 { types.append(.hug) }
        return types
    }
}

// MARK: - Question Post Card

struct QuestionPostCard: View {
    let post: Post
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Badge
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.orange)
                Text("Question")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
                
                Spacer()
                
                // Answered Badge
                if hasAnswer {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Answered")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Author
            if let author = post.author {
                HStack(spacing: 8) {
                    UserAvatarView(profile: author, size: 32)
                    Text(author.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.textColor)
                    Text("•")
                        .foregroundColor(themeManager.textColor.opacity(0.4))
                    Text(post.relativeTime)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                }
            }
            
            // Question Content
            Text(post.content)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.textColor)
                .lineLimit(4)
            
            // Verse Reference
            if let verseRef = post.verseRef {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 12))
                    Text(verseRef.shortReference)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(themeManager.accentColor)
            }
            
            // Stats
            HStack(spacing: 16) {
                Label("\(post.engagement.comments) answers", systemImage: "bubble.right")
                Label("\(post.engagement.totalReactions)", systemImage: "hand.thumbsup")
            }
            .font(.system(size: 13))
            .foregroundColor(themeManager.textColor.opacity(0.6))
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var hasAnswer: Bool {
        // Would check if any comment is marked as best answer
        false
    }
}

// MARK: - Post Card Skeleton

struct PostCardSkeleton: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Circle()
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.backgroundColor.opacity(0.3))
                        .frame(width: 120, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.backgroundColor.opacity(0.3))
                        .frame(width: 80, height: 12)
                }
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(width: 200, height: 14)
            }
            
            // Reactions
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.backgroundColor.opacity(0.3))
                        .frame(width: 40, height: 24)
                }
            }
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shimmering()
    }
}

// MARK: - Shimmer Effect
// Note: ShimmerModifier is defined in WidgetAnimations.swift

#Preview {
    VStack(spacing: 16) {
        PostCardView(post: Post(
            authorId: UUID(),
            type: .reflection,
            content: "This verse really spoke to me today. The Lord's faithfulness is new every morning!",
            verseRef: PostVerseRef(book: "Lamentations", chapter: 3, startVerse: 23, endVerse: nil, translationId: "NIV"),
            tags: ["faith", "morning", "devotion"]
        ))
        
        PostCardSkeleton()
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}

