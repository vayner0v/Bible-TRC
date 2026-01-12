//
//  ArchivedConversationsView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Archived Conversations View
//

import SwiftUI

/// View for managing archived conversations
struct ArchivedConversationsView: View {
    @ObservedObject var storageService = ChatStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery: String = ""
    @State private var showingDeleteConfirmation: Bool = false
    @State private var conversationToDelete: ChatConversation?
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Archived Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !storageService.archivedConversations.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete All Archived", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "Search archived chats...")
            .alert("Delete All Archived?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllArchived()
                }
            } message: {
                Text("This will permanently delete \(storageService.archivedCount) archived conversations. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 50))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("No Archived Chats")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("Conversations you archive will appear here")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var conversationsList: some View {
        List {
            ForEach(filteredConversations) { conversation in
                ArchivedConversationRow(conversation: conversation)
                    .swipeActions(edge: .leading) {
                        Button {
                            restoreConversation(conversation)
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            conversationToDelete = conversation
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .alert("Delete Conversation?", isPresented: .init(
            get: { conversationToDelete != nil },
            set: { if !$0 { conversationToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                conversationToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let conv = conversationToDelete {
                    storageService.deleteConversation(conv.id)
                    conversationToDelete = nil
                }
            }
        } message: {
            Text("This will permanently delete this conversation. This action cannot be undone.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredConversations: [ChatConversation] {
        if searchQuery.isEmpty {
            return storageService.archivedConversations
        }
        let query = searchQuery.lowercased()
        return storageService.archivedConversations.filter { conversation in
            conversation.title.lowercased().contains(query) ||
            conversation.messages.contains { $0.content.lowercased().contains(query) }
        }
    }
    
    // MARK: - Actions
    
    private func restoreConversation(_ conversation: ChatConversation) {
        storageService.unarchiveConversation(conversation.id)
        HapticManager.shared.success()
    }
    
    private func deleteAllArchived() {
        for conversation in storageService.archivedConversations {
            storageService.deleteConversation(conversation.id)
        }
        HapticManager.shared.success()
    }
}

// MARK: - Archived Conversation Row

struct ArchivedConversationRow: View {
    let conversation: ChatConversation
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: conversation.currentMode.icon)
                    .font(.caption)
                    .foregroundColor(conversation.currentMode.accentColor)
                
                Text(conversation.title)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Text(conversation.previewText)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(2)
            
            HStack {
                if let archiveDate = conversation.formattedArchiveDate {
                    Label("Archived \(archiveDate)", systemImage: "archivebox")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Text("\(conversation.messageCount) messages")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    ArchivedConversationsView()
}




