//
//  ConversationSidebar.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Sidebar Navigation
//

import SwiftUI

/// Sidebar for navigating between conversations
struct ConversationSidebar: View {
    @ObservedObject var viewModel: TRCAIChatViewModel
    @ObservedObject private var storageService = ChatStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var searchQuery: String = ""
    @State private var showingArchive: Bool = false
    @State private var showingSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader
            
            Divider()
            
            // Search
            searchBar
            
            // Conversations List
            ScrollView {
                LazyVStack(spacing: 4) {
                    if filteredGroups.isEmpty && searchQuery.isEmpty {
                        emptyState
                    } else if filteredGroups.isEmpty {
                        noSearchResults
                    } else {
                        ForEach(filteredGroups, id: \.title) { group in
                            conversationGroup(group)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            
            Divider()
            
            // Footer
            sidebarFooter
        }
        .background(themeManager.backgroundColor)
        .sheet(isPresented: $showingArchive) {
            ArchivedConversationsView()
        }
        .sheet(isPresented: $showingSettings) {
            AIPreferencesView()
        }
    }
    
    // MARK: - Header
    
    /// Check if current conversation is empty (no messages yet)
    private var isCurrentConversationEmpty: Bool {
        guard let current = storageService.currentConversation else { return true }
        return current.messages.isEmpty
    }
    
    private var sidebarHeader: some View {
        HStack {
            Text("Conversations")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
            
            Button {
                viewModel.startNewConversation()
                HapticManager.shared.lightImpact()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.body)
                    .foregroundColor(canStartNewConversation ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
            .buttonStyle(.plain)
            .disabled(!canStartNewConversation)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    /// Can only start new conversation if not loading/streaming AND current conversation has messages
    private var canStartNewConversation: Bool {
        !viewModel.isLoading && !viewModel.isStreaming && !isCurrentConversationEmpty
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField("Search conversations...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Conversation Groups
    
    private func conversationGroup(_ group: (title: String, conversations: [ChatConversation])) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.title)
                .font(.caption.weight(.semibold))
                .foregroundColor(themeManager.secondaryTextColor)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            ForEach(group.conversations) { conversation in
                ConversationRow(
                    conversation: conversation,
                    isSelected: conversation.id == viewModel.conversationId,
                    onTap: {
                        viewModel.loadConversation(conversation)
                    },
                    onArchive: {
                        viewModel.archiveConversation(conversation.id)
                    },
                    onDelete: {
                        viewModel.deleteConversation(conversation.id)
                    }
                )
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 4) {
                Text("No conversations yet")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(themeManager.textColor)
                
                Text("Start a new chat to begin")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Button {
                viewModel.startNewConversation()
                HapticManager.shared.success()
            } label: {
                Label("New Chat", systemImage: "plus.bubble")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(themeManager.accentColor)
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var noSearchResults: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text("No results for \"\(searchQuery)\"")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Footer
    
    private var sidebarFooter: some View {
        HStack(spacing: 16) {
            Button {
                showingArchive = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "archivebox")
                        .font(.caption)
                    Text("Archive")
                        .font(.caption)
                    
                    if storageService.archivedCount > 0 {
                        Text("\(storageService.archivedCount)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeManager.secondaryTextColor)
                            .cornerRadius(10)
                    }
                }
                .foregroundColor(themeManager.secondaryTextColor)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Filtering
    
    private var filteredGroups: [(title: String, conversations: [ChatConversation])] {
        if searchQuery.isEmpty {
            return storageService.groupedActiveConversations
        }
        
        let filtered = storageService.searchConversations(query: searchQuery, includeArchived: false)
        if filtered.isEmpty {
            return []
        }
        return [("Search Results", filtered)]
    }
}

// MARK: - Preview

#Preview {
    ConversationSidebar(viewModel: TRCAIChatViewModel())
        .frame(width: 280)
}

