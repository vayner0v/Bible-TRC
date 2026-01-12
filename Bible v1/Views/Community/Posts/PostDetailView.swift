//
//  PostDetailView.swift
//  Bible v1
//
//  Community Tab - Post Detail View
//

import SwiftUI

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isCommentFocused: Bool
    
    init(postId: UUID) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(postId: postId))
    }
    
    init(post: Post) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Post Content
                    if let post = viewModel.post {
                        postContent(post)
                    } else if viewModel.isLoading {
                        PostCardSkeleton()
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Comments
                    commentsSection
                }
                .padding(.bottom, 100)
            }
            
            // Comment Input
            commentInputBar
        }
        .background(themeManager.backgroundColor)
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
    
    // MARK: - Post Content
    
    private func postContent(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                if post.isAnonymous {
                    anonymousAvatar
                } else if let author = post.author {
                    NavigationLink(value: CommunityDestination.profile(author.id)) {
                        UserAvatarView(profile: author, size: 44)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if post.isAnonymous {
                            Text("Anonymous")
                                .font(.system(size: 16, weight: .semibold))
                        } else if let author = post.author {
                            Text(author.displayName)
                                .font(.system(size: 16, weight: .semibold))
                            
                            if author.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(author.verificationType?.badgeColor ?? .blue)
                            }
                        }
                    }
                    .foregroundColor(themeManager.textColor)
                    
                    HStack(spacing: 4) {
                        Text(post.type.displayName)
                            .foregroundColor(post.type.color)
                        Text("•")
                            .foregroundColor(themeManager.textColor.opacity(0.4))
                        Text(formatDate(post.createdAt))
                            .foregroundColor(themeManager.textColor.opacity(0.5))
                    }
                    .font(.system(size: 13))
                }
                
                Spacer()
                
                Menu {
                    if viewModel.isAuthor {
                        Button("Edit") { }
                        Button("Delete", role: .destructive) {
                            viewModel.showDeleteConfirmation = true
                        }
                    } else {
                        Button("Report") {
                            viewModel.showReportSheet = true
                        }
                    }
                    Button("Share") { }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                        .padding(8)
                }
            }
            
            // Verse Attachment
            if let verseRef = post.verseRef {
                NavigationLink(value: CommunityDestination.verseHub(verseRef.book, verseRef.chapter, verseRef.startVerse)) {
                    HStack {
                        Rectangle()
                            .fill(themeManager.accentColor)
                            .frame(width: 3)
                        
                        Text(verseRef.fullReference)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.accentColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.accentColor.opacity(0.5))
                    }
                    .padding(14)
                    .background(themeManager.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Content
            Text(post.content)
                .font(.system(size: 16))
                .foregroundColor(themeManager.textColor)
                .lineSpacing(4)
            
            // Tags
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.tags, id: \.self) { tag in
                            NavigationLink(value: CommunityDestination.tag(tag)) {
                                Text("#\(tag)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeManager.accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(themeManager.accentColor.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            // Reactions
            ReactionBarView(post: post)
        }
        .padding()
    }
    
    private var anonymousAvatar: some View {
        Circle()
            .fill(themeManager.accentColor.opacity(0.2))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accentColor)
            )
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments (\(viewModel.comments.count))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.textColor)
                .padding(.horizontal)
            
            if viewModel.isLoadingComments {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.commentThreads.isEmpty {
                Text("No comments yet. Be the first to comment!")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.commentThreads) { thread in
                        CommentRow(
                            comment: thread.rootComment,
                            replies: thread.replies,
                            onReply: { viewModel.startReply(to: thread.rootComment) },
                            onReact: { type in
                                Task { await viewModel.toggleCommentReaction(thread.rootComment.id, type: type) }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Comment Input
    
    private var commentInputBar: some View {
        VStack(spacing: 8) {
            // Replying indicator
            if let replyingTo = viewModel.replyingTo {
                HStack {
                    Text("Replying to \(replyingTo.author?.displayName ?? "comment")")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.6))
                    
                    Spacer()
                    
                    Button {
                        viewModel.cancelReply()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.textColor.opacity(0.4))
                    }
                }
                .padding(.horizontal)
            }
            
            // Input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $viewModel.newCommentText, axis: .vertical)
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(themeManager.backgroundColor.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(4)
                    .focused($isCommentFocused)
                
                Button {
                    Task { await viewModel.sendComment() }
                } label: {
                    if viewModel.isSendingComment {
                        ProgressView()
                            .tint(themeManager.accentColor)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.newCommentText.isEmpty ? themeManager.textColor.opacity(0.3) : themeManager.accentColor)
                    }
                }
                .disabled(viewModel.newCommentText.isEmpty || viewModel.isSendingComment)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(themeManager.backgroundColor)
        .overlay(
            Rectangle()
                .fill(themeManager.textColor.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: Comment
    let replies: [Comment]
    let onReply: () -> Void
    let onReact: (ReactionType) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showReplies = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main comment
            commentContent(comment, indent: 0)
            
            // Replies
            if !replies.isEmpty {
                Button {
                    showReplies.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showReplies ? "chevron.up" : "chevron.down")
                        Text("\(replies.count) replies")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.accentColor)
                    .padding(.leading, 52)
                }
                
                if showReplies {
                    ForEach(replies) { reply in
                        commentContent(reply, indent: 1)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func commentContent(_ comment: Comment, indent: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar
            if let author = comment.author {
                UserAvatarView(profile: author, size: 32, showBadge: false)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Author & time
                HStack(spacing: 6) {
                    if let author = comment.author {
                        Text(author.displayName)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(comment.relativeTime)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                    
                    if comment.isBestAnswer {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Best Answer")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                // Content
                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor)
                
                // Actions
                HStack(spacing: 16) {
                    Button("Reply") {
                        onReply()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.textColor.opacity(0.6))
                    
                    Button {
                        onReact(.amen)
                    } label: {
                        HStack(spacing: 4) {
                            Text("🙌")
                            if comment.engagement.amen > 0 {
                                Text("\(comment.engagement.amen)")
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.6))
                    }
                }
            }
        }
        .padding(.leading, CGFloat(indent * 42))
    }
}

// MARK: - Tag Feed View

struct TagFeedView: View {
    let tag: String
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    PostCardView(post: post)
                }
            }
            .padding()
        }
        .navigationTitle("#\(tag)")
        .task {
            // Load posts with this tag
            await viewModel.load()
        }
    }
}

#Preview {
    NavigationStack {
        PostDetailView(postId: UUID())
    }
    .environmentObject(ThemeManager.shared)
}

