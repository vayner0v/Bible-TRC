//
//  TRCAIChatViewModel.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Chat ViewModel with Retry Support
//

import Foundation
import SwiftUI
import Combine

/// Main ViewModel for the TRC AI Chat interface
@MainActor
class TRCAIChatViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var messages: [ChatMessage] = []
    @Published var currentMode: AIMode = .study
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var isStreaming: Bool = false
    @Published var streamingContent: String = ""
    
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    @Published var showUpgradePrompt: Bool = false
    @Published var showConversationList: Bool = false
    @Published var showModeSelector: Bool = false
    @Published var showArchivedConversations: Bool = false
    @Published var showSettings: Bool = false
    
    // MARK: - Retry State
    
    @Published var isRetrying: Bool = false
    @Published var currentRetryAttempt: Int = 0
    @Published var maxRetryAttempts: Int = 5
    @Published var retryStatusMessage: String = ""
    
    // MARK: - Streaming Performance State
    
    /// Tracks if first token has been received for haptic feedback
    private var hasReceivedFirstToken: Bool = false
    
    /// Estimated response time based on question complexity
    @Published var estimatedResponseTime: TimeInterval?
    
    /// Time when request started (for elapsed time tracking)
    private var requestStartTime: Date?
    
    /// Timer for updating elapsed time display
    private var elapsedTimeTimer: Timer?
    
    // MARK: - Navigation State
    
    @Published var navigateToVerse: VerseReference?
    @Published var saveToJournalContent: String?
    @Published var saveToJournalCitations: [AICitation] = []
    
    // MARK: - Image Attachments
    
    @Published var pendingImageAttachments: [ChatImageAttachment] = []
    @Published var showImageViewer: Bool = false
    @Published var selectedImageForViewer: ChatImageAttachment?
    
    // MARK: - Memory
    
    @Published var showMemoryConsent: Bool = false
    
    // MARK: - Background Processing
    
    @Published var isViewActive: Bool = true
    private var loadingTimeoutTask: Task<Void, Never>?
    private let loadingTimeoutSeconds: Double = 60 // 60 second timeout
    
    // MARK: - Dependencies
    
    private let aiService = TRCAIService.shared
    private let storageService = ChatStorageService.shared
    private let usageManager = AIUsageManager.shared
    private let verseRepository = VerseRepository.shared
    private let memoryService = AIMemoryService.shared
    private let preferencesService = AIPreferencesService.shared
    private let backgroundNotificationService = AIBackgroundNotificationService.shared
    private let liveActivityService = LiveActivityService.shared
    
    // MARK: - Current Conversation
    
    /// Cached conversation ID to prevent accidental changes
    private var _cachedConversationId: UUID?
    
    private var currentConversation: ChatConversation {
        get {
            let conversation = storageService.getOrCreateCurrentConversation(translationId: translationId)
            // Cache the ID on first access
            if _cachedConversationId == nil {
                _cachedConversationId = conversation.id
            }
            return conversation
        }
        set {
            storageService.updateConversation(newValue)
        }
    }
    
    var conversationId: UUID {
        // Use cached ID if available to prevent ID changes mid-conversation
        if let cached = _cachedConversationId {
            return cached
        }
        let id = currentConversation.id
        _cachedConversationId = id
        return id
    }
    
    // MARK: - Configuration
    
    var translationId: String = "engKJV"
    
    // MARK: - Usage State (forwarded from UsageManager)
    
    var canSendMessage: Bool { usageManager.canSendMessage }
    var messagesRemaining: Int { usageManager.messagesRemaining }
    var usageStatusMessage: String { usageManager.usageStatusMessage }
    var isPremium: Bool { usageManager.isPremium }
    
    // MARK: - Initialization
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadCurrentConversation()
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe usage manager changes
        usageManager.$messagesRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe AI service retry state
        aiService.$currentRetryAttempt
            .receive(on: DispatchQueue.main)
            .sink { [weak self] attempt in
                guard let self = self else { return }
                self.currentRetryAttempt = attempt
                if attempt > 1 {
                    self.isRetrying = true
                    self.retryStatusMessage = "Retrying... attempt \(attempt)/\(self.maxRetryAttempts)"
                }
            }
            .store(in: &cancellables)
        
        // Observe storage changes (for background completion when ViewModel was deallocated)
        storageService.$conversations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncWithStorage()
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentConversation() {
        let conversation = currentConversation
        messages = conversation.messages
        currentMode = conversation.currentMode
        print("DEBUG: Loaded conversation \(conversation.id) with \(messages.count) messages")
    }
    
    /// Reload messages from storage (useful if storage was updated elsewhere)
    func reloadFromStorage() {
        let storedMessages = storageService.getOrCreateCurrentConversation(translationId: translationId).messages
        if storedMessages.count != messages.count {
            print("DEBUG: Reloading - storage has \(storedMessages.count) messages, local has \(messages.count)")
            messages = storedMessages
        }
    }
    
    /// Sync with storage when it changes (handles background completion)
    private func syncWithStorage() {
        guard let storedConversation = storageService.currentConversation,
              storedConversation.id == conversationId else { return }
        
        let storedMessages = storedConversation.messages
        
        // Check if storage has updates we don't have:
        // 1. More messages than local
        // 2. Last message is finalized in storage but streaming locally
        // 3. Last message has follow-ups in storage but not locally
        let shouldSync: Bool
        
        if storedMessages.count > messages.count {
            shouldSync = true
            print("DEBUG: syncWithStorage - storage has more messages (\(storedMessages.count) vs \(messages.count))")
        } else if let storedLast = storedMessages.last,
                  let localLast = messages.last,
                  storedLast.id == localLast.id {
            // Same last message - check if storage has more complete version
            if localLast.isStreaming && !storedLast.isStreaming {
                shouldSync = true
                print("DEBUG: syncWithStorage - storage has finalized message that's still streaming locally")
            } else if localLast.followUps.isEmpty && !storedLast.followUps.isEmpty {
                shouldSync = true
                print("DEBUG: syncWithStorage - storage has follow-ups that local doesn't")
            } else {
                shouldSync = false
            }
        } else {
            shouldSync = false
        }
        
        if shouldSync {
            messages = storedMessages
            
            // Also clear loading state if the response is complete
            if let lastMessage = messages.last, !lastMessage.isStreaming && lastMessage.role == .assistant {
                isLoading = false
                isStreaming = false
                stopElapsedTimeTimer()
            }
            
            print("DEBUG: syncWithStorage - synced \(messages.count) messages from storage")
        }
    }
    
    // MARK: - Message Sending
    
    /// Send a message to the AI
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || !pendingImageAttachments.isEmpty else { return }
        guard !isLoading && !isStreaming else { return }
        
        // Check usage limits
        guard canSendMessage else {
            showUpgradePrompt = true
            return
        }
        
        // Clear input immediately
        inputText = ""
        let attachments = pendingImageAttachments
        pendingImageAttachments = []
        
        // Create user message with optional images
        let userMessage = attachments.isEmpty 
            ? ChatMessage.user(text) 
            : ChatMessage.user(text, images: attachments)
        addMessage(userMessage)
        
        // Record usage
        usageManager.recordUsage()
        
        // Check if this is a vision request
        if !attachments.isEmpty {
            startVisionRequest(for: text, images: attachments)
        } else {
            startStreaming(for: text, requestType: .normal)
        }
    }
    
    /// Add images to pending attachments
    func addImageAttachments(_ images: [UIImage]) {
        let attachments = images.map { ChatImageAttachment.from($0) }
        pendingImageAttachments.append(contentsOf: attachments)
    }
    
    /// Remove a pending image attachment
    func removeImageAttachment(_ attachment: ChatImageAttachment) {
        pendingImageAttachments.removeAll { $0.id == attachment.id }
    }
    
    /// Start a vision request with images
    private func startVisionRequest(for text: String, images: [ChatImageAttachment]) {
        let streamingMessage = ChatMessage.assistantStreaming()
        addMessage(streamingMessage)
        
        isStreaming = true
        isLoading = true
        startLoadingTimeout()
        
        // Convert attachments to UIImages
        let uiImages = images.compactMap { $0.fullImage }
        
        AIVisionService.shared.analyzeImages(uiImages, prompt: text, mode: currentMode) { [weak self] result in
            guard let self = self else { return }
            
            self.isStreaming = false
            self.isLoading = false
            self.cancelLoadingTimeout()
            
            switch result {
            case .success(let response):
                // Update streaming message with response
                if let index = self.messages.firstIndex(where: { $0.id == streamingMessage.id }) {
                    let finalMessage = ChatMessage(
                        id: streamingMessage.id,
                        role: .assistant,
                        content: response,
                        timestamp: Date(),
                        mode: self.currentMode,
                        isStreaming: false
                    )
                    self.messages[index] = finalMessage
                    self.storageService.updateMessage(finalMessage, in: self.conversationId)
                    HapticManager.shared.success()
                    
                    // Notify if in background
                    if !self.isViewActive {
                        self.backgroundNotificationService.completeBackgroundProcessing(
                            conversationId: self.conversationId,
                            title: "TRC AI responded",
                            preview: response
                        )
                    }
                }
                
            case .failure(let error):
                self.messages.removeAll { $0.id == streamingMessage.id }
                self.errorMessage = error.localizedDescription
                self.showError = true
                HapticManager.shared.error()
            }
        }
    }
    
    /// Send a follow-up question
    func sendFollowUp(_ question: String) {
        inputText = question
        sendMessage()
    }
    
    /// Request a shorter version of the last response with full context
    func requestShorter() {
        guard let lastAssistant = messages.last(where: { $0.role == .assistant && !$0.isStreaming }) else {
            errorMessage = "No previous response to shorten"
            showError = true
            return
        }
        guard canSendMessage else {
            showUpgradePrompt = true
            return
        }
        guard !isLoading && !isStreaming else { return }
        
        usageManager.recordUsage()
        
        let streamingMessage = ChatMessage.assistantStreaming()
        addMessage(streamingMessage)
        
        isStreaming = true
        isLoading = true
        startLoadingTimeout()
        streamingContent = ""
        isRetrying = false
        retryStatusMessage = ""
        
        // Pass full context to the service
        let shorterQuestion = "Make this response shorter"
        aiService.requestShorter(
            previousContent: lastAssistant.content,
            previousCitations: lastAssistant.citations,
            mode: currentMode,
            conversation: currentConversation,
            translationId: translationId,
            onToken: { [weak self] token in
                self?.handleStreamToken(token)
            },
            onRetry: { [weak self] attempt, maxAttempts in
                self?.handleRetry(attempt: attempt, maxAttempts: maxAttempts)
            },
            onComplete: { [weak self] result in
                self?.handleStreamComplete(result, messageId: streamingMessage.id, originalQuestion: shorterQuestion)
            }
        )
    }
    
    /// Request a deeper exploration with full context
    func requestDeeper() {
        guard let lastAssistant = messages.last(where: { $0.role == .assistant && !$0.isStreaming }) else {
            errorMessage = "No previous response to expand"
            showError = true
            return
        }
        guard canSendMessage else {
            showUpgradePrompt = true
            return
        }
        guard !isLoading && !isStreaming else { return }
        
        usageManager.recordUsage()
        
        let streamingMessage = ChatMessage.assistantStreaming()
        addMessage(streamingMessage)
        
        isStreaming = true
        isLoading = true
        startLoadingTimeout()
        streamingContent = ""
        isRetrying = false
        retryStatusMessage = ""
        
        // Pass full context to the service
        let deeperQuestion = "Go deeper on this topic"
        aiService.requestDeeper(
            previousContent: lastAssistant.content,
            previousCitations: lastAssistant.citations,
            mode: currentMode,
            conversation: currentConversation,
            translationId: translationId,
            onToken: { [weak self] token in
                self?.handleStreamToken(token)
            },
            onRetry: { [weak self] attempt, maxAttempts in
                self?.handleRetry(attempt: attempt, maxAttempts: maxAttempts)
            },
            onComplete: { [weak self] result in
                self?.handleStreamComplete(result, messageId: streamingMessage.id, originalQuestion: deeperQuestion)
            }
        )
    }
    
    // MARK: - Streaming
    
    /// Tracks the current user question for follow-up generation
    private var currentUserQuestion: String = ""
    
    private func startStreaming(for text: String, requestType: AIRequestType) {
        let streamingMessage = ChatMessage.assistantStreaming()
        addMessage(streamingMessage)
        
        // Store the question for follow-up generation
        currentUserQuestion = text
        
        isStreaming = true
        isLoading = true
        streamingContent = ""
        isRetrying = false
        retryStatusMessage = ""
        
        // Reset first token tracking for haptic feedback
        hasReceivedFirstToken = false
        
        // Reset continuation attempts for new message
        continuationAttempts = 0
        
        // Calculate and show estimated response time
        estimatedResponseTime = calculateEstimatedResponseTime(for: text, mode: currentMode)
        requestStartTime = Date()
        startElapsedTimeTimer()
        
        print("DEBUG: ETA set to \(estimatedResponseTime ?? 0) seconds")
        
        // Mark background processing started
        backgroundNotificationService.startBackgroundProcessing(conversationId: conversationId)
        
        // Start Live Activity for Dynamic Island
        liveActivityService.startAIGeneration(
            conversationId: conversationId,
            mode: currentMode.rawValue,
            modeDisplayName: currentMode.displayName
        )
        
        // Note: Keep-alive is now managed by TRCAIService for background generation
        aiService.sendMessage(
            text,
            mode: currentMode,
            conversation: currentConversation,
            translationId: translationId,
            requestType: requestType,
            streamingMessageId: streamingMessage.id,
            onToken: { [weak self] token in
                self?.handleStreamToken(token)
            },
            onRetry: { [weak self] attempt, maxAttempts in
                self?.handleRetry(attempt: attempt, maxAttempts: maxAttempts)
            },
            onComplete: { [weak self] result in
                self?.handleStreamComplete(result, messageId: streamingMessage.id, originalQuestion: text)
            }
        )
    }
    
    private func handleStreamToken(_ token: String) {
        // Haptic feedback on first token to confirm AI is responding
        if !hasReceivedFirstToken {
            hasReceivedFirstToken = true
            HapticManager.shared.lightImpact()
            estimatedResponseTime = nil // Clear estimate since we're now streaming
        }
        
        streamingContent += token
        
        // Clear retry state once we start receiving tokens
        if isRetrying {
            isRetrying = false
            retryStatusMessage = ""
        }
        
        // Update the streaming message in place
        if let index = messages.lastIndex(where: { $0.isStreaming }) {
            let message = messages[index]
            messages[index] = ChatMessage(
                id: message.id,
                role: .assistant,
                content: streamingContent,
                timestamp: message.timestamp,
                isStreaming: true
            )
        }
        
        // Update Live Activity with streaming progress
        // Estimate progress based on content length (assume avg response ~1000 chars)
        let estimatedProgress = min(Double(streamingContent.count) / 1000.0, 0.95)
        liveActivityService.updateAIProgress(
            preview: streamingContent,
            estimatedProgress: estimatedProgress
        )
    }
    
    private func handleRetry(attempt: Int, maxAttempts: Int) {
        isRetrying = true
        currentRetryAttempt = attempt
        maxRetryAttempts = maxAttempts
        retryStatusMessage = "Connection issue. Retrying... (\(attempt)/\(maxAttempts))"
        
        // Clear streaming content for retry
        streamingContent = ""
        
        // Update streaming message to show retry state
        if let index = messages.lastIndex(where: { $0.isStreaming }) {
            let message = messages[index]
            messages[index] = ChatMessage(
                id: message.id,
                role: .assistant,
                content: "",
                timestamp: message.timestamp,
                isStreaming: true
            )
        }
        
        // Haptic feedback for retry
        HapticManager.shared.warning()
    }
    
    private func handleStreamComplete(_ result: Result<AIResponse, AIResponseError>, messageId: UUID, originalQuestion: String? = nil) {
        isStreaming = false
        isLoading = false
        cancelLoadingTimeout()
        stopElapsedTimeTimer()
        isRetrying = false
        retryStatusMessage = ""
        currentRetryAttempt = 0
        
        // Note: Keep-alive is now managed by TRCAIService
        
        switch result {
        case .success(let response):
            // Check for truncated response and auto-retry if needed
            let question = originalQuestion ?? currentUserQuestion
            if detectTruncatedResponse(response.answerMarkdown) && !isRetrying {
                // Response was cut off - attempt to continue
                continuetruncatedResponse(
                    originalQuestion: question,
                    truncatedContent: response.answerMarkdown,
                    messageId: messageId
                )
                return
            }
            
            // Complete Live Activity
            liveActivityService.completeAIGeneration(
                title: response.title,
                preview: response.answerMarkdown
            )
            
            // Resolve citations and generate follow-ups
            Task {
                let rawCitations = response.citations.map { raw in
                    AICitation(reference: raw.reference, translationId: raw.translationId)
                }
                let resolvedCitations = await verseRepository.resolveCitations(rawCitations, translationId: translationId)
                
                // Finalize the message (without follow-ups initially)
                if let index = messages.firstIndex(where: { $0.id == messageId }) {
                    let finalMessage = messages[index].finalized(with: response, resolvedCitations: resolvedCitations)
                    messages[index] = finalMessage
                    
                    // Update storage
                    storageService.updateMessage(finalMessage, in: conversationId)
                    
                    // Success haptic
                    HapticManager.shared.success()
                    
                    // Send background notification if view is not active
                    if !self.isViewActive {
                        self.backgroundNotificationService.completeBackgroundProcessing(
                            conversationId: self.conversationId,
                            title: response.title,
                            preview: response.answerMarkdown
                        )
                    } else {
                        self.backgroundNotificationService.cancelBackgroundProcessing()
                    }
                    
                    // Auto-extract memories from the conversation (if enabled)
                    if preferencesService.isMemoryEnabled {
                        Task {
                            await MemoryExtractor.shared.processConversationTurn(
                                userMessage: question,
                                aiResponse: response.answerMarkdown,
                                messageId: messageId,
                                conversationId: self.conversationId,
                                autoSave: true
                            )
                        }
                    }
                    
                    // Now generate smart follow-ups asynchronously
                    let questionForFollowUp = originalQuestion ?? currentUserQuestion
                    let responseContent = response.answerMarkdown
                    let mode = currentMode
                    let msgId = messageId
                    let convId = conversationId
                    
                    print("DEBUG: Starting follow-up generation task for message \(msgId)")
                    print("DEBUG: Question: \(questionForFollowUp.prefix(50))...")
                    print("DEBUG: Response length: \(responseContent.count) chars")
                    
                    // Generate follow-ups in a separate task to avoid blocking
                    Task { @MainActor [weak self] in
                        guard let self = self else {
                            print("DEBUG: Self was nil in follow-up task")
                            return
                        }
                        
                        print("DEBUG: Follow-up task executing...")
                        
                        // Use async/await pattern for cleaner MainActor handling
                        let followUps = await self.fetchFollowUpsAsync(
                            responseContent: responseContent,
                            originalQuestion: questionForFollowUp,
                            mode: mode
                        )
                        
                        print("DEBUG: Got \(followUps.count) follow-ups, updating message...")
                        
                        // Update the message with follow-ups
                        self.updateMessageWithFollowUps(messageId: msgId, followUps: followUps, conversationId: convId)
                    }
                }
            }
            
        case .failure(let error):
            handleError(error, messageId: messageId)
        }
        
        streamingContent = ""
    }
    
    private func handleError(_ error: AIResponseError, messageId: UUID) {
        // Remove only the streaming message that failed
        let beforeCount = messages.count
        messages.removeAll { $0.id == messageId }
        print("DEBUG: Error handler removed \(beforeCount - messages.count) message(s), remaining: \(messages.count)")
        
        // Only remove from storage if we actually removed a message locally
        if beforeCount > messages.count {
            storageService.removeLastMessage(from: conversationId)
        }
        
        // Cancel Live Activity
        liveActivityService.cancelAIGeneration()
        
        // Note: Keep-alive is now managed by TRCAIService
        
        // Error haptic
        HapticManager.shared.error()
        
        switch error {
        case .safetyTriggered(let safetyResponse):
            // Add safety response as a message
            let safetyMessage = ChatMessage.safety(safetyResponse)
            addMessage(safetyMessage)
            
        case .usageLimitExceeded:
            showUpgradePrompt = true
            
        case .rateLimited:
            errorMessage = "Too many requests. Please wait a moment and try again."
            showError = true
            
        case .networkError(let underlyingError):
            let nsError = underlyingError as NSError
            if nsError.code == -999 {
                // Request was cancelled, don't show error
                return
            }
            errorMessage = "Connection failed after multiple attempts. Please check your internet and try again."
            showError = true
            
        default:
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Message Management
    
    private func addMessage(_ message: ChatMessage) {
        messages.append(message)
        let convId = conversationId // Capture conversation ID
        storageService.addMessage(message, to: convId)
        print("DEBUG: Added message to conversation \(convId), total messages: \(messages.count)")
    }
    
    // MARK: - Follow-up Generation
    
    /// Async wrapper for fetching follow-ups with proper error handling
    private func fetchFollowUpsAsync(
        responseContent: String,
        originalQuestion: String,
        mode: AIMode
    ) async -> [String] {
        print("DEBUG: fetchFollowUpsAsync starting for question: \(originalQuestion.prefix(50))...")
        
        let followUps = await withCheckedContinuation { continuation in
            aiService.generateFollowUps(
                for: responseContent,
                originalQuestion: originalQuestion,
                mode: mode
            ) { followUps in
                print("DEBUG: generateFollowUps callback received \(followUps.count) follow-ups")
                continuation.resume(returning: followUps)
            }
        }
        
        print("DEBUG: fetchFollowUpsAsync returning \(followUps.count) follow-ups")
        return followUps
    }
    
    /// Update a message with generated follow-ups and trigger UI refresh
    private func updateMessageWithFollowUps(messageId: UUID, followUps: [String], conversationId: UUID) {
        print("DEBUG: updateMessageWithFollowUps called with \(followUps.count) follow-ups for message \(messageId)")
        
        guard !followUps.isEmpty else {
            print("DEBUG: No follow-ups to add")
            return
        }
        
        guard let msgIndex = messages.firstIndex(where: { $0.id == messageId }) else {
            print("DEBUG: Could not find message \(messageId) in \(messages.count) messages")
            return
        }
        
        let existingMessage = messages[msgIndex]
        print("DEBUG: Found message at index \(msgIndex), current followUps: \(existingMessage.followUps.count)")
        
        let updatedMessage = ChatMessage(
            id: existingMessage.id,
            role: existingMessage.role,
            content: existingMessage.content,
            timestamp: existingMessage.timestamp,
            title: existingMessage.title,
            citations: existingMessage.citations,
            followUps: followUps,
            actions: existingMessage.actions,
            mode: existingMessage.mode,
            isSafetyResponse: existingMessage.isSafetyResponse,
            safetyResources: existingMessage.safetyResources,
            imageAttachments: existingMessage.imageAttachments,
            isStreaming: false
        )
        
        // Update the local array - this triggers @Published
        messages[msgIndex] = updatedMessage
        
        // Explicitly notify observers to ensure UI updates
        objectWillChange.send()
        
        // Persist to storage
        storageService.updateMessage(updatedMessage, in: conversationId)
        
        print("DEBUG: Successfully updated message with \(followUps.count) follow-ups: \(followUps)")
    }
    
    // MARK: - Response Time Estimation
    
    /// Calculate estimated response time based on question complexity
    private func calculateEstimatedResponseTime(for message: String, mode: AIMode) -> TimeInterval {
        let wordCount = message.split(separator: " ").count
        
        // Base time depends on mode (Study is more complex)
        let baseTime: TimeInterval
        switch mode {
        case .study:
            baseTime = 8.0
        case .devotional:
            baseTime = 6.0
        case .prayer:
            baseTime = 5.0
        }
        
        // Complexity multiplier based on question length
        let complexityMultiplier = min(1.0 + Double(wordCount) / 50.0, 2.0)
        
        // Additional time if conversation has context
        let contextBonus: TimeInterval = messages.count > 4 ? 2.0 : 0.0
        
        return baseTime * complexityMultiplier + contextBonus
    }
    
    // MARK: - Truncation Detection and Auto-Retry
    
    /// Check if the response appears to be truncated (ends mid-sentence)
    private func detectTruncatedResponse(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Short responses are likely complete
        guard trimmed.count > 100 else { return false }
        
        // Check for proper sentence endings - these are NOT truncated
        let properEndings = CharacterSet(charactersIn: ".!?\"')*")
        if let lastChar = trimmed.unicodeScalars.last,
           properEndings.contains(lastChar) {
            return false
        }
        
        // Check for valid markdown endings - NOT truncated
        if trimmed.hasSuffix("```") || trimmed.hasSuffix("---") {
            return false
        }
        
        // Check for list endings - NOT truncated
        if trimmed.hasSuffix("\n") {
            return false
        }
        
        // Check if it ends mid-word (very likely truncated)
        let lastWord = trimmed.split(separator: " ").last.map(String.init) ?? ""
        
        // If the last "word" looks like it was cut off mid-word
        // (no punctuation, very short, not a common short word)
        let commonShortWords = Set(["i", "a", "an", "the", "to", "is", "it", "or", "on", "in", "of", "be", "as", "at", "by", "we", "so", "no", "do", "my", "he", "up", "if"])
        
        if lastWord.count <= 2 && !commonShortWords.contains(lastWord.lowercased()) && !lastWord.isEmpty {
            // Possibly cut off, but not definite
            return true
        }
        
        // Check for dangling colons/dashes that suggest more content was coming
        if trimmed.hasSuffix(":") || trimmed.hasSuffix("-") {
            return true
        }
        
        // Default: assume NOT truncated (don't retry unnecessarily)
        return false
    }
    
    /// Track continuation attempts to avoid infinite loops
    private var continuationAttempts = 0
    private let maxContinuationAttempts = 1
    
    /// Attempt to continue a truncated response
    private func continuetruncatedResponse(originalQuestion: String, truncatedContent: String, messageId: UUID) {
        // Only attempt once to avoid infinite loops
        guard !isRetrying && continuationAttempts < maxContinuationAttempts else { 
            continuationAttempts = 0
            return 
        }
        
        continuationAttempts += 1
        
        isRetrying = true
        retryStatusMessage = "Response was cut off, continuing..."
        
        let continuationPrompt = "Please continue and complete your previous response about: \(originalQuestion)"
        
        Task {
            // Small delay before retrying
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            aiService.sendMessage(
                continuationPrompt,
                mode: currentMode,
                conversation: currentConversation,
                translationId: translationId,
                requestType: .continuation,
                streamingMessageId: messageId,
                onToken: { [weak self] token in
                    guard let self = self else { return }
                    self.streamingContent = truncatedContent + " " + token
                    if let index = self.messages.lastIndex(where: { $0.id == messageId }) {
                        self.messages[index] = ChatMessage(
                            id: messageId,
                            role: .assistant,
                            content: self.streamingContent,
                            timestamp: Date(),
                            isStreaming: true
                        )
                    }
                },
                onRetry: { [weak self] attempt, maxAttempts in
                    self?.handleRetry(attempt: attempt, maxAttempts: maxAttempts)
                },
                onComplete: { [weak self] result in
                    self?.isRetrying = false
                    self?.retryStatusMessage = ""
                    self?.handleStreamComplete(result, messageId: messageId, originalQuestion: originalQuestion)
                }
            )
        }
    }
    
    // MARK: - Mode Switching
    
    func setMode(_ mode: AIMode) {
        currentMode = mode
        storageService.updateMode(mode, for: conversationId)
        HapticManager.shared.selection()
    }
    
    // MARK: - Conversation Management
    
    func startNewConversation() {
        // Cancel any ongoing request
        cancelRequest()
        
        let newConversation = storageService.startNewConversation(
            mode: currentMode,
            translationId: translationId
        )
        _cachedConversationId = newConversation.id // Update cached ID
        messages = newConversation.messages
        currentMode = newConversation.currentMode
        print("DEBUG: Started new conversation \(newConversation.id)")
        HapticManager.shared.success()
    }
    
    func loadConversation(_ conversation: ChatConversation) {
        // Cancel any ongoing request
        cancelRequest()
        
        _cachedConversationId = conversation.id // Update cached ID
        storageService.setCurrentConversation(conversation.id)
        messages = conversation.messages
        currentMode = conversation.currentMode
        print("DEBUG: Loaded conversation \(conversation.id) with \(messages.count) messages")
    }
    
    func deleteConversation(_ id: UUID) {
        storageService.deleteConversation(id)
        
        // If we deleted the current one, load the new current
        if id == conversationId {
            loadCurrentConversation()
        }
    }
    
    func archiveConversation(_ id: UUID) {
        storageService.archiveConversation(id)
        
        // If we archived the current one, load a new current
        if id == conversationId {
            loadCurrentConversation()
        }
        HapticManager.shared.success()
    }
    
    func unarchiveConversation(_ id: UUID) {
        storageService.unarchiveConversation(id)
        HapticManager.shared.success()
    }
    
    var allConversations: [ChatConversation] {
        storageService.activeConversations
    }
    
    var archivedConversations: [ChatConversation] {
        storageService.archivedConversations
    }
    
    // MARK: - Actions
    
    /// Open a verse in the Bible reader
    func openVerse(_ citation: AICitation) {
        if let verseRef = citation.toVerseReference() {
            navigateToVerse = verseRef
        }
    }
    
    /// Save response to journal
    func saveToJournal(_ message: ChatMessage) {
        saveToJournalContent = message.content
        saveToJournalCitations = message.citations
        HapticManager.shared.success()
    }
    
    /// Share a response
    func shareResponse(_ message: ChatMessage) -> String {
        var text = ""
        
        if let title = message.title {
            text += "\(title)\n\n"
        }
        
        text += message.content
        
        if !message.citations.isEmpty {
            text += "\n\nVerses: \(message.citations.map { $0.reference }.joined(separator: ", "))"
        }
        
        text += "\n\n— TRC AI Bible Assistant"
        
        return text
    }
    
    /// Handle action button tap
    func handleAction(_ action: AIAction) {
        switch action.actionType {
        case .openVerse:
            if let reference = action.reference {
                let citation = AICitation(reference: reference, translationId: translationId)
                openVerse(citation)
            }
        case .openChapter:
            if let reference = action.reference {
                let citation = AICitation(reference: reference, translationId: translationId)
                openVerse(citation)
            }
        case .saveToJournal:
            if let lastMessage = messages.last(where: { $0.role == .assistant && !$0.isStreaming }) {
                saveToJournal(lastMessage)
            }
        case .goDeeper:
            requestDeeper()
        case .makeShorter:
            requestShorter()
        case .shareResponse:
            // Handled by the view with ShareLink
            break
        }
    }
    
    // MARK: - Cancel
    
    func cancelRequest() {
        // Note: aiService.cancel() also handles keep-alive cleanup
        aiService.cancel()
        liveActivityService.cancelAIGeneration()
        resetLoadingState()
    }
    
    /// Reset all loading-related states
    private func resetLoadingState() {
        isStreaming = false
        isLoading = false
        isRetrying = false
        retryStatusMessage = ""
        currentRetryAttempt = 0
        loadingTimeoutTask?.cancel()
        loadingTimeoutTask = nil
        stopElapsedTimeTimer()
        
        // Remove any streaming messages (only incomplete ones)
        let streamingMessages = messages.filter { $0.isStreaming }
        print("DEBUG: resetLoadingState - found \(streamingMessages.count) streaming messages to remove")
        
        for msg in streamingMessages {
            // Only remove empty streaming messages (failed to get response)
            if msg.content.isEmpty {
                storageService.removeLastMessage(from: conversationId)
            }
        }
        messages.removeAll { $0.isStreaming && $0.content.isEmpty }
    }
    
    /// Called when view appears - checks for and fixes stuck loading states
    func onViewAppear() {
        isViewActive = true
        
        // Ensure we're synchronized with storage
        reloadFromStorage()
        
        // Reload messages from storage in case generation completed in background
        reloadMessagesFromStorage()
        
        // Check if we're in a stuck loading state (loading but no active AI task)
        if isLoading && !aiService.isProcessing {
            print("DEBUG: Detected stuck loading state, resetting...")
            resetLoadingState()
        }
    }
    
    /// Reload messages from storage to pick up background completions
    private func reloadMessagesFromStorage() {
        let storedMessages = storageService.conversations
            .first(where: { $0.id == conversationId })?
            .messages ?? []
        
        // Check if there are new completed messages in storage that aren't in our local array
        let localMessageIds = Set(messages.map { $0.id })
        let hasNewMessages = storedMessages.contains { msg in
            !msg.isStreaming && !localMessageIds.contains(msg.id)
        }
        
        // Also check if a streaming message was finalized in storage
        let streamingMessageFinalized = messages.contains { localMsg in
            localMsg.isStreaming && storedMessages.contains { storedMsg in
                storedMsg.id == localMsg.id && !storedMsg.isStreaming
            }
        }
        
        if hasNewMessages || streamingMessageFinalized {
            print("DEBUG: Found background-completed messages, reloading from storage")
            messages = storedMessages
            
            // Clear loading state since we have the response
            if !storedMessages.contains(where: { $0.isStreaming }) {
                isLoading = false
                isStreaming = false
            }
        }
    }
    
    /// Called when view disappears
    func onViewDisappear() {
        isViewActive = false
    }
    
    /// Start a timeout that will reset loading state if it takes too long
    private func startLoadingTimeout() {
        loadingTimeoutTask?.cancel()
        loadingTimeoutTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: UInt64(loadingTimeoutSeconds * 1_000_000_000))
                if isLoading || isStreaming {
                    print("DEBUG: Loading timeout reached, resetting state...")
                    errorMessage = "Request timed out. Please try again."
                    showError = true
                    resetLoadingState()
                }
            } catch {
                // Task was cancelled, that's fine
            }
        }
    }
    
    /// Cancel the loading timeout (called when request completes normally)
    private func cancelLoadingTimeout() {
        loadingTimeoutTask?.cancel()
        loadingTimeoutTask = nil
    }
    
    /// Get the loading status text
    var loadingStatusText: String {
        if isRetrying {
            return retryStatusMessage
        } else if isLoading && streamingContent.isEmpty {
            var text = "Thinking..."
            
            // Show elapsed time
            if let startTime = requestStartTime {
                let elapsed = Int(Date().timeIntervalSince(startTime))
                text = "Thinking... \(elapsed)s"
            }
            
            // Show ETA if available
            if let eta = estimatedResponseTime {
                let seconds = Int(eta)
                text += " (ETA ~\(seconds)s)"
            }
            
            return text
        } else if isStreaming {
            // Show elapsed time while streaming
            if let startTime = requestStartTime {
                let elapsed = Int(Date().timeIntervalSince(startTime))
                return "Responding... \(elapsed)s"
            }
            return "Responding..."
        }
        return ""
    }
    
    // MARK: - Elapsed Time Timer
    
    private func startElapsedTimeTimer() {
        stopElapsedTimeTimer()
        elapsedTimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Trigger UI update every second
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
    
    private func stopElapsedTimeTimer() {
        elapsedTimeTimer?.invalidate()
        elapsedTimeTimer = nil
        requestStartTime = nil
    }
}

// MARK: - Preview Helper

extension TRCAIChatViewModel {
    static var preview: TRCAIChatViewModel {
        let vm = TRCAIChatViewModel()
        vm.messages = [
            ChatMessage.user("What does John 3:16 mean?"),
            ChatMessage(
                role: .assistant,
                content: """
                John 3:16 is often called the "Gospel in a nutshell" because it summarizes the core message of Christianity.
                
                **"For God so loved the world"** - This establishes God's motivation: unconditional love for all humanity.
                
                **"that he gave his only begotten Son"** - The ultimate sacrifice, giving what was most precious.
                
                **"that whosoever believeth in him should not perish, but have everlasting life"** - The promise of salvation through faith.
                """,
                title: "The Gospel in a Nutshell",
                citations: [
                    AICitation(reference: "John 3:16", translationId: "engKJV", text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.")
                ],
                followUps: [
                    "What does the Greek word 'agape' reveal about God's love here?",
                    "How does this verse connect to Jesus' conversation with Nicodemus?",
                    "What practical difference does believing in Jesus make in daily life?"
                ],
                mode: .study
            )
        ]
        return vm
    }
}
