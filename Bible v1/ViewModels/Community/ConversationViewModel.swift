//
//  ConversationViewModel.swift
//  Bible v1
//
//  Community Tab - Conversation View Model
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var conversation: Conversation?
    @Published var messages: [Message] = []
    @Published var recipient: CommunityProfileSummary?
    @Published var messageText = ""
    
    @Published var isLoading = false
    @Published var isSending = false
    @Published var isRecipientTyping = false
    @Published var isOnline = false
    @Published var isMuted = false
    
    // Sheets
    @Published var showProfile = false
    @Published var showBlockConfirmation = false
    @Published var showDeleteConfirmation = false
    @Published var showAttachmentOptions = false
    
    // MARK: - Computed Properties
    
    var currentUserId: UUID? {
        CommunityService.shared.currentProfile?.id
    }
    
    var lastSeenText: String? {
        guard let lastSeen = recipient?.lastActiveAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Last seen \(formatter.localizedString(for: lastSeen, relativeTo: Date()))"
    }
    
    var groupedMessages: [MessageGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }
        
        return grouped.keys.sorted().map { date in
            MessageGroup(
                date: date,
                messages: grouped[date]!.sorted { $0.createdAt < $1.createdAt }
            )
        }
    }
    
    // MARK: - Properties
    
    private var conversationId: UUID?
    private var recipientId: UUID?
    private var messagingService: MessagingService { CommunityService.shared.messagingService }
    private var typingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(conversationId: UUID) {
        self.conversationId = conversationId
    }
    
    init(conversation: Conversation) {
        self.conversationId = conversation.id
        self.conversation = conversation
    }
    
    init(recipientId: UUID) {
        self.recipientId = recipientId
    }
    
    // MARK: - Public Methods
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // If we have a recipient but no conversation, find or create one
            if let recipientId = recipientId, conversationId == nil {
                conversation = try await messagingService.findOrCreateConversation(
                    with: recipientId,
                    currentUserId: currentUserId!
                )
                conversationId = conversation?.id
            }
            
            // Load conversation details
            if let id = conversationId {
                if conversation == nil {
                    conversation = try await messagingService.getConversation(id: id)
                }
                
                // Load messages
                messages = try await messagingService.getMessages(conversationId: id)
                
                // Load recipient profile
                await loadRecipient()
                
                // Mark messages as read
                await markAsRead()
                
                // Setup realtime subscription
                setupRealtimeSubscription()
            }
        } catch {
            print("❌ Conversation: Failed to load - \(error.localizedDescription)")
        }
    }
    
    func sendMessage() async {
        guard let conversationId = conversationId,
              let userId = currentUserId,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        isSending = true
        defer { isSending = false }
        
        do {
            let newMessage = try await messagingService.sendMessage(
                conversationId: conversationId,
                senderId: userId,
                content: content
            )
            
            messages.append(newMessage)
        } catch {
            // Restore message text on failure
            messageText = content
            print("❌ Conversation: Failed to send message - \(error.localizedDescription)")
        }
    }
    
    func updateTypingStatus() {
        // Debounce typing indicator
        typingTimer?.invalidate()
        
        // Send typing start
        Task {
            // await messagingService.sendTypingIndicator(conversationId: conversationId!, isTyping: true)
        }
        
        // Reset after delay
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                // TODO: Send typing indicator when implemented
            }
        }
    }
    
    func muteConversation() {
        isMuted.toggle()
        // Save mute preference
        // await messagingService.setMuted(conversationId: conversationId!, isMuted: isMuted)
    }
    
    func blockUser() async {
        guard let recipientId = recipient?.id else { return }
        
        do {
            try await CommunityService.shared.blockUser(recipientId)
            // Navigate back
        } catch {
            print("❌ Conversation: Failed to block user - \(error.localizedDescription)")
        }
    }
    
    func deleteConversation() async {
        guard let conversationId = conversationId else { return }
        
        do {
            try await messagingService.deleteConversation(id: conversationId)
            // Navigate back
        } catch {
            print("❌ Conversation: Failed to delete conversation - \(error.localizedDescription)")
        }
    }
    
    func attachPhoto() {
        // Open photo picker
    }
    
    func attachVerse() {
        // Open verse picker
    }
    
    // MARK: - Private Methods
    
    private func loadRecipient() async {
        guard let conversation = conversation,
              let userId = currentUserId else { return }
        
        // Get the other participant
        do {
            let participants = try await messagingService.getParticipants(conversationId: conversation.id)
            if let otherParticipant = participants.first(where: { $0.profileId != userId }) {
                recipient = try await CommunityService.shared.profileService.getProfileSummary(id: otherParticipant.profileId)
            }
        } catch {
            print("❌ Conversation: Failed to load recipient - \(error.localizedDescription)")
        }
    }
    
    private func markAsRead() async {
        guard let conversationId = conversationId,
              let userId = currentUserId else { return }
        
        do {
            try await messagingService.markAsRead(conversationId: conversationId, userId: userId)
        } catch {
            print("❌ Conversation: Failed to mark as read - \(error.localizedDescription)")
        }
    }
    
    private func setupRealtimeSubscription() {
        // Setup Supabase realtime subscription for new messages
        // This would listen for:
        // - New messages
        // - Typing indicators
        // - Read receipts
    }
}

// MARK: - Extensions

extension CommunityProfileSummary {
    var lastActiveAt: Date? {
        // Would need to be fetched from profile
        nil
    }
}

