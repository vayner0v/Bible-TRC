//
//  MessagingService.swift
//  Bible v1
//
//  Community Tab - Messaging Service
//

import Foundation
import Supabase

/// Service for managing direct messages
@MainActor
final class MessagingService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Message Requests
    
    /// Send a message request
    func sendMessageRequest(from: UUID, to: UUID, message: String?) async throws {
        // Check if already have a conversation
        let existingConversation = try await findDirectConversation(between: from, and: to)
        if existingConversation != nil {
            throw CommunityError.validation("You already have a conversation with this user")
        }
        
        // Check if blocked
        let isBlocked = try await CommunityService.shared.followService.isUserBlocked(blockerId: to, blockedId: from)
        if isBlocked {
            throw CommunityError.permissionDenied
        }
        
        // Check if there's already a pending request
        let existingRequest = try await getPendingRequest(from: from, to: to)
        if existingRequest != nil {
            throw CommunityError.validation("You already have a pending request")
        }
        
        let request = MessageRequest(
            fromUserId: from,
            toUserId: to,
            initialMessage: message
        )
        
        try await supabase
            .from("message_requests")
            .insert(request)
            .execute()
    }
    
    /// Get pending message requests for a user
    func getMessageRequests(userId: UUID) async throws -> [MessageRequest] {
        let requests: [MessageRequest] = try await supabase
            .from("message_requests")
            .select("*, from_user:community_profiles!from_user_id(*)")
            .eq("to_user_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return requests
    }
    
    /// Accept a message request
    func acceptMessageRequest(requestId: UUID) async throws -> Conversation {
        // Get the request
        let requests: [MessageRequest] = try await supabase
            .from("message_requests")
            .select()
            .eq("id", value: requestId.uuidString)
            .execute()
            .value
        
        guard let request = requests.first else {
            throw CommunityError.notFound
        }
        
        // Update request status
        try await supabase
            .from("message_requests")
            .update([
                "status": "accepted",
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: requestId.uuidString)
            .execute()
        
        // Create conversation
        let conversation = try await createConversation(
            participantIds: [request.fromUserId, request.toUserId]
        )
        
        // Send initial message if provided
        if let initialMessage = request.initialMessage {
            _ = try await sendMessage(
                conversationId: conversation.id,
                senderId: request.fromUserId,
                content: initialMessage
            )
        }
        
        return conversation
    }
    
    /// Decline a message request
    func declineMessageRequest(requestId: UUID) async throws {
        try await supabase
            .from("message_requests")
            .update([
                "status": "declined",
                "responded_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: requestId.uuidString)
            .execute()
    }
    
    // MARK: - Conversations
    
    /// Create a conversation
    func createConversation(participantIds: [UUID], groupId: UUID? = nil) async throws -> Conversation {
        let conversation = Conversation(
            type: groupId != nil ? .groupChat : .direct,
            participantIds: participantIds,
            groupId: groupId
        )
        
        let created: Conversation = try await supabase
            .from("conversations")
            .insert(conversation)
            .select()
            .single()
            .execute()
            .value
        
        return created
    }
    
    /// Get conversations for a user
    func getConversations(userId: UUID) async throws -> [Conversation] {
        let conversations: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .contains("participant_ids", value: [userId.uuidString])
            .order("last_message_at", ascending: false)
            .execute()
            .value
        
        // Enrich with participants and last message
        var enriched: [Conversation] = []
        
        for var conversation in conversations {
            // Get participants
            let participantIds = conversation.participantIds.filter { $0 != userId }
            let profiles: [CommunityProfile] = try await supabase
                .from("community_profiles")
                .select()
                .in("id", values: participantIds.map { $0.uuidString })
                .execute()
                .value
            
            conversation.participants = profiles.map { CommunityProfileSummary(from: $0) }
            
            // Get last message
            let messages: [Message] = try await supabase
                .from("messages")
                .select()
                .eq("conversation_id", value: conversation.id.uuidString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            conversation.lastMessage = messages.first
            
            // Get unread count
            let unreadMessages: [Message] = try await supabase
                .from("messages")
                .select()
                .eq("conversation_id", value: conversation.id.uuidString)
                .neq("sender_id", value: userId.uuidString)
                .eq("is_read", value: false)
                .execute()
                .value
            
            conversation.unreadCount = unreadMessages.count
            
            enriched.append(conversation)
        }
        
        return enriched
    }
    
    /// Find direct conversation between two users
    func findDirectConversation(between userId1: UUID, and userId2: UUID) async throws -> Conversation? {
        let conversations: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .eq("type", value: "direct")
            .contains("participant_ids", value: [userId1.uuidString])
            .contains("participant_ids", value: [userId2.uuidString])
            .execute()
            .value
        
        return conversations.first
    }
    
    // MARK: - Messages
    
    /// Send a message
    func sendMessage(
        conversationId: UUID,
        senderId: UUID,
        content: String,
        mediaUrl: String? = nil,
        verseRef: PostVerseRef? = nil
    ) async throws -> Message {
        let message = Message(
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            mediaUrl: mediaUrl,
            verseRef: verseRef
        )
        
        let created: Message = try await supabase
            .from("messages")
            .insert(message)
            .select()
            .single()
            .execute()
            .value
        
        // Update conversation's last_message_at
        try await supabase
            .from("conversations")
            .update(["last_message_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: conversationId.uuidString)
            .execute()
        
        return created
    }
    
    /// Get messages in a conversation
    func getMessages(conversationId: UUID, offset: Int = 0, limit: Int = 50) async throws -> [Message] {
        let messages: [Message] = try await supabase
            .from("messages")
            .select("*, sender:community_profiles!sender_id(*)")
            .eq("conversation_id", value: conversationId.uuidString)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return messages.reversed()
    }
    
    /// Mark messages as read
    func markAsRead(conversationId: UUID, userId: UUID) async throws {
        let updates: [String: AnyEncodable] = [
            "is_read": AnyEncodable(true),
            "read_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]
        
        try await supabase
            .from("messages")
            .update(updates)
            .eq("conversation_id", value: conversationId.uuidString)
            .neq("sender_id", value: userId.uuidString)
            .eq("is_read", value: "false")
            .execute()
    }
    
    /// Delete a message
    func deleteMessage(id: UUID) async throws {
        try await supabase
            .from("messages")
            .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    /// Find or create a direct conversation between two users
    func findOrCreateConversation(with recipientId: UUID, currentUserId: UUID) async throws -> Conversation {
        // Try to find existing conversation
        if let existing = try await findDirectConversation(between: currentUserId, and: recipientId) {
            return existing
        }
        
        // Create new conversation
        return try await createConversation(participantIds: [currentUserId, recipientId])
    }
    
    /// Get a single conversation by ID
    func getConversation(id: UUID) async throws -> Conversation? {
        let conversations: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        
        return conversations.first
    }
    
    /// Get participants in a conversation
    func getParticipants(conversationId: UUID) async throws -> [ConversationParticipant] {
        let conversation = try await getConversation(id: conversationId)
        guard let conversation = conversation else {
            return []
        }
        
        return conversation.participantIds.map { ConversationParticipant(conversationId: conversationId, profileId: $0) }
    }
    
    /// Delete a conversation
    func deleteConversation(id: UUID) async throws {
        // Soft delete - just remove from user's view
        try await supabase
            .from("conversations")
            .update(["is_archived": true])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Private Methods
    
    private func getPendingRequest(from: UUID, to: UUID) async throws -> MessageRequest? {
        let requests: [MessageRequest] = try await supabase
            .from("message_requests")
            .select()
            .eq("from_user_id", value: from.uuidString)
            .eq("to_user_id", value: to.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
        
        return requests.first
    }
}

// MARK: - Conversation Participant Helper

struct ConversationParticipant: Identifiable {
    let id = UUID()
    let conversationId: UUID
    let profileId: UUID
}

