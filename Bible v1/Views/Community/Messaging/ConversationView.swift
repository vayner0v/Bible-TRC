//
//  ConversationView.swift
//  Bible v1
//
//  Community Tab - Conversation View (Direct Messages)
//

import SwiftUI

struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isMessageFocused: Bool
    
    init(conversationId: UUID) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(conversationId: conversationId))
    }
    
    init(conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(conversation: conversation))
    }
    
    init(recipientId: UUID) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(recipientId: recipientId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesScrollView
            
            // Input Bar
            messageInputBar
        }
        .background(themeManager.backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                conversationHeader
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.showProfile = true
                    } label: {
                        Label("View Profile", systemImage: "person.circle")
                    }
                    
                    Button {
                        viewModel.muteConversation()
                    } label: {
                        Label(
                            viewModel.isMuted ? "Unmute" : "Mute",
                            systemImage: viewModel.isMuted ? "bell" : "bell.slash"
                        )
                    }
                    
                    Button(role: .destructive) {
                        viewModel.showBlockConfirmation = true
                    } label: {
                        Label("Block User", systemImage: "hand.raised")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Label("Delete Conversation", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.textColor)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $viewModel.showProfile) {
            if let recipient = viewModel.recipient {
                NavigationStack {
                    CommunityProfileView(userId: recipient.id)
                }
            }
        }
        .alert("Block User", isPresented: $viewModel.showBlockConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                Task { await viewModel.blockUser() }
            }
        } message: {
            Text("Are you sure you want to block this user? You won't be able to message each other.")
        }
        .alert("Delete Conversation", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteConversation() }
            }
        } message: {
            Text("Are you sure you want to delete this conversation? This cannot be undone.")
        }
    }
    
    // MARK: - Conversation Header
    
    private var conversationHeader: some View {
        Group {
            if let recipient = viewModel.recipient {
                HStack(spacing: 8) {
                    UserAvatarView(profile: recipient, size: 32)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text(recipient.displayName)
                                .font(.system(size: 15, weight: .semibold))
                            
                            if recipient.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if viewModel.isOnline {
                            Text("Online")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        } else if let lastSeen = viewModel.lastSeenText {
                            Text(lastSeen)
                                .font(.system(size: 11))
                                .foregroundColor(themeManager.textColor.opacity(0.5))
                        }
                    }
                }
                .foregroundColor(themeManager.textColor)
            } else {
                Text("Conversation")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
    }
    
    // MARK: - Messages Scroll View
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    ForEach(viewModel.groupedMessages) { group in
                        // Date Header
                        Text(group.dateString)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager.textColor.opacity(0.5))
                            .padding(.vertical, 8)
                        
                        ForEach(group.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == viewModel.currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    
                    // Typing Indicator
                    if viewModel.isRecipientTyping {
                        HStack {
                            TypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) {
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Input Bar
    
    private var messageInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Attachment Button
                Button {
                    viewModel.showAttachmentOptions = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(themeManager.accentColor)
                }
                .confirmationDialog("Add Attachment", isPresented: $viewModel.showAttachmentOptions) {
                    Button("Photo") { viewModel.attachPhoto() }
                    Button("Verse") { viewModel.attachVerse() }
                }
                
                // Text Input
                HStack {
                    TextField("Message...", text: $viewModel.messageText, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(5)
                        .focused($isMessageFocused)
                        .onChange(of: viewModel.messageText) {
                            viewModel.updateTypingStatus()
                        }
                    
                    if viewModel.messageText.isEmpty {
                        // Emoji Button
                        Button {
                            // Show emoji picker
                        } label: {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.textColor.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(themeManager.backgroundColor.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Send Button
                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    if viewModel.isSending {
                        ProgressView()
                            .tint(themeManager.accentColor)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(
                                viewModel.messageText.isEmpty
                                    ? themeManager.textColor.opacity(0.3)
                                    : themeManager.accentColor
                            )
                    }
                }
                .disabled(viewModel.messageText.isEmpty || viewModel.isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(themeManager.backgroundColor)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message Content
                VStack(alignment: .leading, spacing: 4) {
                    // Verse attachment (if any)
                    if let verseRef = message.verseRef {
                        HStack(spacing: 6) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 11))
                            Text(verseRef.shortReference)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(isFromCurrentUser ? .white.opacity(0.8) : themeManager.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            isFromCurrentUser
                                ? Color.white.opacity(0.2)
                                : themeManager.accentColor.opacity(0.1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Text
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(isFromCurrentUser ? .white : themeManager.textColor)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isFromCurrentUser
                        ? themeManager.accentColor
                        : themeManager.backgroundColor.opacity(0.3)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
                
                // Time
                Text(formatTime(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.textColor.opacity(0.4))
            }
            
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(themeManager.textColor.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == Double(index) ? 1.3 : 1.0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animationAmount = 2
            }
        }
    }
}

// MARK: - Supporting Types

struct MessageGroup: Identifiable {
    let id = UUID()
    let date: Date
    let messages: [Message]
    
    var dateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// Note: verseRef is already a property on Message struct

#Preview {
    NavigationStack {
        ConversationView(conversationId: UUID())
    }
    .environmentObject(ThemeManager.shared)
}

