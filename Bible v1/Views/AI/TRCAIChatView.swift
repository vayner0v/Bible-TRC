//
//  TRCAIChatView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Main Chat Interface with Sidebar Navigation
//

import SwiftUI
import PhotosUI

/// Main chat view for the TRC AI Bible Assistant
struct TRCAIChatView: View {
    @StateObject private var viewModel = TRCAIChatViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var preferencesService = AIPreferencesService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @FocusState private var isInputFocused: Bool
    @Namespace private var bottomID
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad / Mac: Use NavigationSplitView with sidebar
                splitViewLayout
            } else {
                // iPhone: Use traditional NavigationStack
                compactLayout
            }
        }
        .sheet(isPresented: $viewModel.showUpgradePrompt) {
            UpgradePromptSheet()
        }
        .sheet(isPresented: $viewModel.showMemoryConsent) {
            MemoryConsentSheet()
        }
        .sheet(isPresented: $viewModel.showImageViewer) {
            if let attachment = viewModel.selectedImageForViewer,
               let image = attachment.fullImage {
                FullImageViewer(image: image)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.navigateToVerse) { _, verse in
            if verse != nil {
                dismiss()
            }
        }
        .onAppear {
            viewModel.onViewAppear()
            
            // Check if we need to show memory consent
            if preferencesService.isMemoryEnabled == false && 
               !preferencesService.hasSeenMemoryConsent {
                // Show consent after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    viewModel.showMemoryConsent = true
                }
            }
        }
        .onDisappear {
            viewModel.onViewDisappear()
        }
    }
    
    // MARK: - Split View Layout (iPad/Mac)
    
    private var splitViewLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ConversationSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
        } detail: {
            chatDetailView
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    // MARK: - Compact Layout (iPhone)
    
    private var compactLayout: some View {
        NavigationStack {
            chatDetailView
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(themeManager.secondaryTextColor)
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                viewModel.startNewConversation()
                            } label: {
                                Label("New Conversation", systemImage: "plus.bubble")
                            }
                            
                            Button {
                                viewModel.showConversationList = true
                            } label: {
                                Label("History", systemImage: "clock.arrow.circlepath")
                            }
                            
                            Divider()
                            
                            Button {
                                viewModel.showSettings = true
                            } label: {
                                Label("AI Settings", systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(themeManager.accentColor)
                        }
                    }
                }
                .sheet(isPresented: $viewModel.showConversationList) {
                    ConversationListSheet(viewModel: viewModel)
                }
                .sheet(isPresented: $viewModel.showSettings) {
                    AIPreferencesView()
                }
        }
    }
    
    // MARK: - Chat Detail View
    
    private var chatDetailView: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Mode Selector
                modeSelectorBar
                
                // Messages
                messagesScrollView
                
                // Loading/Retry Status Bar
                if viewModel.isLoading || viewModel.isStreaming || viewModel.isRetrying {
                    statusBar
                }
                
                // Usage indicator (for free users)
                if !viewModel.isPremium && !viewModel.isLoading {
                    usageIndicator
                }
                
                // Input Bar
                inputBar
            }
        }
        .navigationTitle("TRC AI")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Mode Selector
    
    private var modeSelectorBar: some View {
        HStack(spacing: 8) {
            ForEach(AIMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.setMode(mode)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.caption)
                        Text(mode.displayName)
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(viewModel.currentMode == mode
                                  ? mode.accentColor.opacity(0.2)
                                  : themeManager.cardBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(viewModel.currentMode == mode
                                    ? mode.accentColor
                                    : Color.clear, lineWidth: 1.5)
                    )
                    .foregroundColor(viewModel.currentMode == mode
                                     ? mode.accentColor
                                     : themeManager.secondaryTextColor)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading || viewModel.isStreaming)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
    }
    
    // MARK: - Status Bar (Loading/Retry)
    
    private var statusBar: some View {
        HStack(spacing: 8) {
            if viewModel.isRetrying {
                // Retry indicator
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(viewModel.isRetrying ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.isRetrying)
                
                Text(viewModel.retryStatusMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                // Normal loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
                    .scaleEffect(0.8)
                
                Text(viewModel.loadingStatusText)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Cancel button
            Button {
                viewModel.cancelRequest()
            } label: {
                Text("Cancel")
                    .font(.caption.weight(.medium))
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            viewModel.isRetrying
            ? Color.orange.opacity(0.1)
            : themeManager.cardBackgroundColor
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.isRetrying)
    }
    
    // MARK: - Messages
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.messages.isEmpty {
                        emptyStateView
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else {
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            MessageBubbleView(
                                message: message,
                                mode: viewModel.currentMode,
                                isRetrying: viewModel.isRetrying && message.isStreaming,
                                onCitationTap: { citation in
                                    viewModel.openVerse(citation)
                                },
                                onFollowUpTap: { question in
                                    viewModel.sendFollowUp(question)
                                },
                                onActionTap: { action in
                                    viewModel.handleAction(action)
                                }
                            )
                            .id(message.id)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: message.role == .user ? .trailing : .leading)).combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                )
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.02), value: viewModel.messages.count)
                        }
                    }
                    
                    // Anchor for scrolling
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.streamingContent) { _, _ in
                withAnimation {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.accentColor, viewModel.currentMode.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("TRC AI Bible Assistant")
                    .font(.title2.bold())
                    .foregroundColor(themeManager.textColor)
                
                Text("Ask me anything about Scripture")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Suggested prompts
            VStack(spacing: 12) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                ForEach(suggestedPrompts, id: \.self) { prompt in
                    Button {
                        viewModel.inputText = prompt
                        viewModel.sendMessage()
                    } label: {
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(themeManager.dividerColor, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var suggestedPrompts: [String] {
        switch viewModel.currentMode {
        case .study:
            return [
                "What does John 3:16 mean?",
                "Explain the Sermon on the Mount",
                "Who wrote the book of Hebrews?"
            ]
        case .devotional:
            return [
                "I'm feeling anxious today",
                "Help me understand God's love",
                "A verse for encouragement"
            ]
        case .prayer:
            return [
                "Help me pray for peace",
                "A prayer of thanksgiving",
                "How do I pray for others?"
            ]
        }
    }
    
    // MARK: - Usage Indicator
    
    private var usageIndicator: some View {
        HStack {
            Image(systemName: "sparkle")
                .font(.caption)
            Text(viewModel.usageStatusMessage)
                .font(.caption)
            
            Spacer()
            
            if viewModel.messagesRemaining <= 3 {
                Button("Upgrade") {
                    viewModel.showUpgradePrompt = true
                }
                .font(.caption.bold())
                .foregroundColor(themeManager.accentColor)
            }
        }
        .foregroundColor(themeManager.secondaryTextColor)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(themeManager.cardBackgroundColor)
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            // Image attachments preview
            if !viewModel.pendingImageAttachments.isEmpty {
                ImageAttachmentPreviewView(
                    attachments: viewModel.pendingImageAttachments,
                    onRemove: { viewModel.removeImageAttachment($0) }
                )
            }
            
            Divider()
            
            HStack(alignment: .bottom, spacing: 8) {
                // Photo picker button
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 4,
                    matching: .images
                ) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 36, height: 36)
                }
                .onChange(of: selectedPhotoItems) { _, items in
                    processSelectedPhotos(items)
                }
                .disabled(viewModel.isLoading || viewModel.isStreaming)
                
                // Text input
                TextField("Ask about Scripture...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .disabled(viewModel.isLoading || viewModel.isStreaming)
                
                // Send button
                Button {
                    viewModel.sendMessage()
                    isInputFocused = false
                } label: {
                    Group {
                        if viewModel.isLoading && !viewModel.isStreaming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(
                        (viewModel.inputText.isEmpty && viewModel.pendingImageAttachments.isEmpty) || viewModel.isLoading
                        ? themeManager.secondaryTextColor.opacity(0.3)
                        : viewModel.currentMode.accentColor
                    )
                    .foregroundColor(.white)
                    .clipShape(Circle())
                }
                .disabled((viewModel.inputText.isEmpty && viewModel.pendingImageAttachments.isEmpty) || viewModel.isLoading || viewModel.isStreaming)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(themeManager.backgroundColor)
        }
    }
    
    // MARK: - Photo Processing
    
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                viewModel.addImageAttachments(images)
                selectedPhotoItems = []
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubbleView: View {
    let message: ChatMessage
    let mode: AIMode
    var isRetrying: Bool = false
    let onCitationTap: (AICitation) -> Void
    let onFollowUpTap: (String) -> Void
    let onActionTap: (AIAction) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var typingAnimationPhase: Double = 0
    @State private var cursorOpacity: Double = 1.0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // For user messages, add spacer on the left to push to right
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            if message.role == .assistant {
                // AI Avatar
                aiAvatar
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Image attachments (for user messages with images)
                if message.role == .user && message.hasImages {
                    MessageImagesGridView(
                        attachments: message.imageAttachments,
                        onImageTap: { _ in }  // TODO: Add image viewer
                    )
                }
                
                // Message content
                messageContent
                
                // Citations (for assistant messages)
                if message.role == .assistant && !message.citations.isEmpty && !message.isStreaming {
                    citationsSection
                }
                
                // Follow-ups (for assistant messages, show all 3)
                if message.role == .assistant && !message.followUps.isEmpty && !message.isStreaming {
                    followUpsSection
                }
                
                // Action buttons (for assistant messages)
                if message.role == .assistant && !message.isStreaming {
                    actionButtonsSection
                }
            }
            .frame(maxWidth: message.role == .user ? 280 : .infinity, alignment: message.role == .user ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
    
    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [themeManager.accentColor, mode.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
            
            if isRetrying {
                // Retry icon
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.white)
            } else if message.isStreaming && message.content.isEmpty {
                // Thinking animation
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(0.5 + 0.5 * sin(typingAnimationPhase))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            typingAnimationPhase = .pi
                        }
                    }
            } else {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = message.title, !title.isEmpty, !message.isStreaming {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.textColor)
            }
            
            if message.isStreaming && message.content.isEmpty {
                // Animated typing indicator
                typingIndicator
            } else if message.role == .assistant && message.isStreaming {
                // Streaming text - display directly as it arrives with smooth animation
                Text(LocalizedStringKey(message.content))
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                    .textSelection(.enabled)
                    .animation(.easeOut(duration: 0.1), value: message.content)
                
                // Blinking cursor while streaming
                HStack(spacing: 0) {
                    Text("▍")
                        .font(.body)
                        .foregroundColor(themeManager.accentColor)
                        .opacity(cursorOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                cursorOpacity = 0.3
                            }
                        }
                    Spacer()
                }
            } else {
                // Static text for user messages and completed AI messages
                Text(LocalizedStringKey(message.content))
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : themeManager.textColor)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            message.role == .user
            ? AnyShapeStyle(mode.accentColor)
            : AnyShapeStyle(themeManager.cardBackgroundColor)
        )
        .cornerRadius(20)
        .cornerRadius(message.role == .user ? 20 : 4, corners: message.role == .user ? [.bottomRight] : [.topLeft])
    }
    
    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(isRetrying ? Color.orange : themeManager.secondaryTextColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0 + 0.3 * sin(typingAnimationPhase + Double(i) * 0.5))
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: typingAnimationPhase
                    )
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            typingAnimationPhase = 1
        }
    }
    
    private var citationsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(message.citations) { citation in
                    Button {
                        onCitationTap(citation)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.caption2)
                            Text(citation.reference)
                                .font(.caption)
                            
                            // Verification badge
                            VerificationBadgeView(status: citation.verificationStatus)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(mode.accentColor.opacity(0.1))
                        .foregroundColor(mode.accentColor)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var followUpsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Follow up:")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            // Show all 3 follow-ups (AI-generated contextual questions)
            ForEach(message.followUps.prefix(3), id: \.self) { question in
                Button {
                    onFollowUpTap(question)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.caption2)
                            .foregroundColor(mode.accentColor)
                        
                        Text(question)
                            .font(.caption)
                            .foregroundColor(themeManager.textColor)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themeManager.backgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.dividerColor, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button {
                onActionTap(AIAction(type: "makeShorter", reference: nil, label: nil))
            } label: {
                Label("Shorter", systemImage: "arrow.up.circle")
                    .font(.caption)
            }
            
            Button {
                onActionTap(AIAction(type: "goDeeper", reference: nil, label: nil))
            } label: {
                Label("Deeper", systemImage: "arrow.down.circle")
                    .font(.caption)
            }
            
            Button {
                onActionTap(AIAction(type: "saveToJournal", reference: nil, label: nil))
            } label: {
                Label("Journal", systemImage: "square.and.pencil")
                    .font(.caption)
            }
            
            ShareLink(item: shareableText) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.caption)
            }
        }
        .foregroundColor(themeManager.secondaryTextColor)
        .padding(.top, 4)
    }
    
    /// Generate shareable text from the message
    private var shareableText: String {
        var text = ""
        
        if let title = message.title, !title.isEmpty {
            text += "\(title)\n\n"
        }
        
        text += message.content
        
        if !message.citations.isEmpty {
            text += "\n\n📖 Verses: \(message.citations.map { $0.reference }.joined(separator: ", "))"
        }
        
        text += "\n\n— TRC AI Bible Assistant"
        
        return text
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Conversation List Sheet

struct ConversationListSheet: View {
    @ObservedObject var viewModel: TRCAIChatViewModel
    @ObservedObject private var storageService = ChatStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery: String = ""
    
    private var groupedConversations: [(title: String, conversations: [ChatConversation])] {
        if searchQuery.isEmpty {
            return storageService.groupedActiveConversations
        } else {
            let filtered = storageService.searchConversations(query: searchQuery, includeArchived: false)
            return filtered.isEmpty ? [] : [("Search Results", filtered)]
        }
    }
    
    /// Check if current conversation is empty (no messages yet)
    private var isCurrentConversationEmpty: Bool {
        guard let current = storageService.currentConversation else { return true }
        return current.messages.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                themeManager.backgroundColor.ignoresSafeArea()
                
                if viewModel.allConversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search conversations...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        // Archive button - only show if there are archived conversations
                        if storageService.archivedCount > 0 {
                            Button {
                                viewModel.showArchivedConversations = true
                            } label: {
                                Image(systemName: "archivebox")
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                        
                        // New conversation button - disabled if current is empty
                        Button {
                            viewModel.startNewConversation()
                            dismiss()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(isCurrentConversationEmpty ? themeManager.secondaryTextColor : themeManager.accentColor)
                        }
                        .disabled(isCurrentConversationEmpty)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showArchivedConversations) {
                ArchivedConversationsView()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("No conversations yet")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(themeManager.textColor)
                
                Text("Start a new conversation to begin your journey")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.startNewConversation()
                dismiss()
            } label: {
                Label("New Conversation", systemImage: "plus.bubble")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(themeManager.accentColor)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
        }
        .padding()
    }
    
    // MARK: - Conversation List
    
    private var conversationList: some View {
        List {
            ForEach(groupedConversations, id: \.title) { group in
                Section {
                    ForEach(group.conversations) { conversation in
                        ConversationListRow(
                            conversation: conversation,
                            isSelected: conversation.id == viewModel.conversationId
                        )
                        .listRowBackground(themeManager.cardBackgroundColor)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .onTapGesture {
                            viewModel.loadConversation(conversation)
                            HapticManager.shared.selection()
                            dismiss()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteConversation(conversation.id)
                                HapticManager.shared.warning()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                viewModel.archiveConversation(conversation.id)
                                HapticManager.shared.lightImpact()
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    Text(group.title.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .tracking(0.5)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor)
    }
}

// MARK: - Conversation List Row (for List with swipe actions)

private struct ConversationListRow: View {
    let conversation: ChatConversation
    let isSelected: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Mode indicator
            Circle()
                .fill(conversation.currentMode.accentColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: conversation.currentMode.icon)
                        .font(.system(size: 18))
                        .foregroundColor(conversation.currentMode.accentColor)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textColor)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(conversation.formattedDate)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Text(conversation.previewText)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                
                // Stats row
                HStack(spacing: 12) {
                    Label("\(conversation.messageCount)", systemImage: "bubble.left")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(conversation.currentMode.displayName)
                        .font(.caption2)
                        .foregroundColor(conversation.currentMode.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(conversation.currentMode.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Conversation List Card (legacy, for context menu usage)

private struct ConversationListCard: View {
    let conversation: ChatConversation
    let isSelected: Bool
    let onTap: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingActions: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Mode indicator
                Circle()
                    .fill(conversation.currentMode.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: conversation.currentMode.icon)
                            .font(.system(size: 18))
                            .foregroundColor(conversation.currentMode.accentColor)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textColor)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(conversation.formattedDate)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Text(conversation.previewText)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                    
                    // Stats row
                    HStack(spacing: 12) {
                        Label("\(conversation.messageCount)", systemImage: "bubble.left")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text(conversation.currentMode.displayName)
                            .font(.caption2)
                            .foregroundColor(conversation.currentMode.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(conversation.currentMode.accentColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onArchive()
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Upgrade Prompt Sheet

struct UpgradePromptSheet: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Premium icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Unlock Unlimited TRC AI")
                        .font(.title.bold())
                        .foregroundColor(themeManager.textColor)
                    
                    Text("You've used all your free messages.\nUpgrade to continue your spiritual journey with TRC AI.")
                        .font(.body)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    UpgradeFeatureRow(icon: "infinity", title: "Unlimited TRC AI", description: "No daily message limits")
                    UpgradeFeatureRow(icon: "brain.head.profile", title: "AI Memory", description: "TRC AI remembers your prayers & preferences")
                    UpgradeFeatureRow(icon: "bolt.fill", title: "Priority Responses", description: "Faster AI processing")
                    UpgradeFeatureRow(icon: "waveform.circle.fill", title: "AI Voices", description: "Natural Bible narration")
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(16)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                            Text("Upgrade to Premium")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.accentGradient)
                        .cornerRadius(14)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(themeManager.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    private func UpgradeFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.textColor)
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
    }
}

// MARK: - Verification Badge View

/// Displays the verification status of a citation
struct VerificationBadgeView: View {
    let status: VerificationStatus
    
    var body: some View {
        switch status {
        case .pending:
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 12, height: 12)
        case .verified:
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(status.color)
        case .paraphrased:
            Image(systemName: status.icon)
                .font(.system(size: 10))
                .foregroundColor(status.color)
        case .failed:
            Image(systemName: status.icon)
                .font(.system(size: 10))
                .foregroundColor(status.color)
        }
    }
}

/// Larger verification badge with label for detailed views
struct VerificationBadgeLabelView: View {
    let status: VerificationStatus
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.label)
                .font(.caption2)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Tab View Wrapper

/// Wrapper for TRCAIChatView when used as a tab (removes dismiss functionality)
struct TRCAIChatTabView: View {
    @StateObject private var viewModel = TRCAIChatViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var preferencesService = AIPreferencesService.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @FocusState private var isInputFocused: Bool
    @Namespace private var bottomID
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad / Mac: Use NavigationSplitView with sidebar
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    ConversationSidebar(viewModel: viewModel)
                        .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
                } detail: {
                    tabChatDetailView
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                // iPhone: Use traditional NavigationStack - no dismiss button
                NavigationStack {
                    tabChatDetailView
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Menu {
                                    Button {
                                        viewModel.startNewConversation()
                                    } label: {
                                        Label("New Conversation", systemImage: "plus.bubble")
                                    }
                                    
                                    Button {
                                        viewModel.showConversationList = true
                                    } label: {
                                        Label("History", systemImage: "clock.arrow.circlepath")
                                    }
                                    
                                    Divider()
                                    
                                    Button {
                                        viewModel.showSettings = true
                                    } label: {
                                        Label("AI Settings", systemImage: "gearshape")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(themeManager.accentColor)
                                }
                            }
                        }
                        .sheet(isPresented: $viewModel.showConversationList) {
                            ConversationListSheet(viewModel: viewModel)
                        }
                        .sheet(isPresented: $viewModel.showSettings) {
                            AIPreferencesView()
                        }
                }
            }
        }
        .sheet(isPresented: $viewModel.showUpgradePrompt) {
            UpgradePromptSheet()
        }
        .sheet(isPresented: $viewModel.showMemoryConsent) {
            MemoryConsentSheet()
        }
        .sheet(isPresented: $viewModel.showImageViewer) {
            if let attachment = viewModel.selectedImageForViewer,
               let image = attachment.fullImage {
                FullImageViewer(image: image)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.onViewAppear()
            
            // Check if we need to show memory consent
            if preferencesService.isMemoryEnabled == false && 
               !preferencesService.hasSeenMemoryConsent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    viewModel.showMemoryConsent = true
                }
            }
        }
        .onDisappear {
            viewModel.onViewDisappear()
        }
    }
    
    // MARK: - Tab Chat Detail View (reuses existing components)
    
    private var tabChatDetailView: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Mode Selector
                tabModeSelectorBar
                
                // Messages
                tabMessagesScrollView
                
                // Loading/Retry Status Bar
                if viewModel.isLoading || viewModel.isStreaming || viewModel.isRetrying {
                    tabStatusBar
                }
                
                // Usage indicator (for free users)
                if !viewModel.isPremium && !viewModel.isLoading {
                    tabUsageIndicator
                }
                
                // Input Bar
                tabInputBar
            }
        }
        .navigationTitle("TRC AI")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Mode Selector
    
    private var tabModeSelectorBar: some View {
        HStack(spacing: 8) {
            ForEach(AIMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.setMode(mode)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.caption)
                        Text(mode.displayName)
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(viewModel.currentMode == mode
                                  ? mode.accentColor.opacity(0.2)
                                  : themeManager.cardBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(viewModel.currentMode == mode
                                    ? mode.accentColor
                                    : Color.clear, lineWidth: 1.5)
                    )
                    .foregroundColor(viewModel.currentMode == mode
                                     ? mode.accentColor
                                     : themeManager.secondaryTextColor)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading || viewModel.isStreaming)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
    }
    
    // MARK: - Messages Scroll View
    
    private var tabMessagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.messages.isEmpty && !viewModel.isLoading {
                        tabWelcomeContent
                    } else {
                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            MessageBubbleView(
                                message: message,
                                mode: viewModel.currentMode,
                                isRetrying: viewModel.isRetrying && message.isStreaming,
                                onCitationTap: { citation in
                                    viewModel.openVerse(citation)
                                },
                                onFollowUpTap: { question in
                                    viewModel.sendFollowUp(question)
                                },
                                onActionTap: { action in
                                    viewModel.handleAction(action)
                                }
                            )
                            .id(message.id)
                        }
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.streamingContent) { _, _ in
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }
    
    private var tabWelcomeContent: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            // Icon
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title
            Text("TRC AI")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(themeManager.textColor)
            
            Text("Your Bible study companion")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Status Bar
    
    private var tabStatusBar: some View {
        HStack(spacing: 8) {
            if viewModel.isRetrying {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(viewModel.isRetrying ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.isRetrying)
                Text(viewModel.retryStatusMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                Text(viewModel.loadingStatusText)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Cancel button
            Button {
                viewModel.cancelRequest()
            } label: {
                Text("Cancel")
                    .font(.caption.weight(.medium))
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            viewModel.isRetrying
            ? Color.orange.opacity(0.1)
            : themeManager.cardBackgroundColor
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.isRetrying)
    }
    
    // MARK: - Usage Indicator
    
    private var tabUsageIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption)
            Text(viewModel.usageStatusMessage)
                .font(.caption)
            
            Spacer()
            
            if viewModel.messagesRemaining <= 3 {
                Button("Upgrade") {
                    viewModel.showUpgradePrompt = true
                }
                .font(.caption.bold())
                .foregroundColor(themeManager.accentColor)
            }
        }
        .foregroundColor(themeManager.secondaryTextColor)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(themeManager.cardBackgroundColor)
    }
    
    // MARK: - Input Bar
    
    private var tabInputBar: some View {
        VStack(spacing: 0) {
            // Image attachments preview
            if !viewModel.pendingImageAttachments.isEmpty {
                ImageAttachmentPreviewView(
                    attachments: viewModel.pendingImageAttachments,
                    onRemove: { viewModel.removeImageAttachment($0) }
                )
            }
            
            Divider()
            
            HStack(alignment: .bottom, spacing: 8) {
                // Photo picker button
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 4,
                    matching: .images
                ) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 36, height: 36)
                }
                .onChange(of: selectedPhotoItems) { _, items in
                    processSelectedPhotos(items)
                }
                .disabled(viewModel.isLoading || viewModel.isStreaming)
                
                // Text input
                TextField("Ask about Scripture...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(20)
                    .focused($isInputFocused)
                    .disabled(viewModel.isLoading || viewModel.isStreaming)
                
                // Send button
                Button {
                    viewModel.sendMessage()
                    isInputFocused = false
                } label: {
                    Group {
                        if viewModel.isLoading && !viewModel.isStreaming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(
                        (viewModel.inputText.isEmpty && viewModel.pendingImageAttachments.isEmpty) || viewModel.isLoading
                        ? themeManager.secondaryTextColor.opacity(0.3)
                        : viewModel.currentMode.accentColor
                    )
                    .foregroundColor(.white)
                    .clipShape(Circle())
                }
                .disabled((viewModel.inputText.isEmpty && viewModel.pendingImageAttachments.isEmpty) || viewModel.isLoading || viewModel.isStreaming)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(themeManager.backgroundColor)
        }
    }
    
    // MARK: - Photo Processing
    
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                viewModel.addImageAttachments(images)
                selectedPhotoItems = []
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TRCAIChatView()
}
