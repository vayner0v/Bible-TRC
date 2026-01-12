//
//  TRCAIService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Core AI Service with Natural Prose Responses
//

import Foundation
import Combine

// MARK: - Retry Configuration

/// Configuration for aggressive retry behavior
struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let retryableStatusCodes: Set<Int>
    
    static let aggressive = RetryConfiguration(
        maxAttempts: 5,
        baseDelay: 1.0,
        maxDelay: 16.0,
        retryableStatusCodes: [429, 500, 502, 503, 504, 520, 521, 522, 523, 524]
    )
    
    /// Calculate delay for attempt number (exponential backoff)
    func delay(for attempt: Int) -> TimeInterval {
        let delay = baseDelay * pow(2.0, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

/// Request type determines token limits and behavior
enum AIRequestType {
    case normal       // Standard messages: 1500 tokens
    case deeper       // Go deeper: 3000 tokens for comprehensive expansion
    case shorter      // Make shorter: 800 tokens for concise summary
    case followUp     // Follow-up generation: 300 tokens
    case continuation // Continue truncated response: 1000 tokens
    
    var tokenLimit: Int {
        switch self {
        case .normal: return 1500
        case .deeper: return 3000
        case .shorter: return 800
        case .continuation: return 1000
        case .followUp: return 300
        }
    }
}

// MARK: - TRC AI Service

/// Core AI service for the TRC Bible Assistant
/// Handles OpenAI API integration with streaming, natural prose responses, and retry logic
@MainActor
class TRCAIService: ObservableObject {
    static let shared = TRCAIService()
    
    // MARK: - Configuration
    
    // Using GPT-5 mini - fast, cost-effective, 400K context window
    private let model = "gpt-5-mini-2025-08-07"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let retryConfig = RetryConfiguration.aggressive
    
    // MARK: - Dependencies
    
    private let verseRepository = VerseRepository.shared
    private let referenceParser = ReferenceParser.shared
    private let safetyClassifier = SafetyClassifier.shared
    private let preferencesService = AIPreferencesService.shared
    private let memoryService = AIMemoryService.shared
    
    // MARK: - API Key
    
    private var apiKey: String {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path),
           let key = secrets["OPENAI_API_KEY"] as? String {
            return key
        }
        return ""
    }
    
    // MARK: - State
    
    @Published var isProcessing = false
    @Published var lastError: AIResponseError?
    @Published var currentRetryAttempt: Int = 0
    @Published var maxRetryAttempts: Int = 0
    
    private var currentTask: Task<Void, Never>?
    private var isCancelled = false
    private let session: URLSession
    
    // Active generation context for background completion
    // This ensures AI generation saves results even if the view is dismissed
    private var activeGenerationContext: ActiveGenerationContext?
    
    private struct ActiveGenerationContext {
        let conversationId: UUID
        let streamingMessageId: UUID
        let userMessage: String
        let mode: AIMode
        let translationId: String
        var accumulatedContent: String = ""
        
        // Callbacks (may become nil if view is dismissed)
        let onToken: (String) -> Void
        let onRetry: ((Int, Int) -> Void)?
        let onComplete: (Result<AIResponse, AIResponseError>) -> Void
    }
    
    // Reference to storage service for fallback saving
    private let storageService = ChatStorageService.shared
    private let backgroundNotificationService = AIBackgroundNotificationService.shared
    private let keepAliveService = BackgroundKeepAliveService.shared
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Send a message and stream the response with aggressive retry
    /// Generation continues in background even if the initiating view is dismissed
    /// - Parameter skipNotification: When true, skips the completion notification banner (used for inline insights)
    func sendMessage(
        _ message: String,
        mode: AIMode,
        conversation: ChatConversation,
        translationId: String,
        requestType: AIRequestType = .normal,
        streamingMessageId: UUID = UUID(),
        skipNotification: Bool = false,
        onToken: @escaping (String) -> Void,
        onRetry: ((Int, Int) -> Void)? = nil,
        onComplete: @escaping (Result<AIResponse, AIResponseError>) -> Void
    ) {
        // Cancel any existing request
        currentTask?.cancel()
        isCancelled = false
        
        // Store context for background completion
        // This ensures results are saved even if the ViewModel is deallocated
        activeGenerationContext = ActiveGenerationContext(
            conversationId: conversation.id,
            streamingMessageId: streamingMessageId,
            userMessage: message,
            mode: mode,
            translationId: translationId,
            onToken: onToken,
            onRetry: onRetry,
            onComplete: onComplete
        )
        
        // Start keep-alive for background processing
        let requestId = "ai_generation_\(conversation.id.uuidString)"
        keepAliveService.startKeepAlive(requestId: requestId, reason: "AI Generation")
        
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            
            self.isProcessing = true
            self.currentRetryAttempt = 0
            self.maxRetryAttempts = self.retryConfig.maxAttempts
            
            let conversationId = conversation.id
            
            defer {
                Task { @MainActor [weak self] in
                    self?.isProcessing = false
                    self?.currentRetryAttempt = 0
                    self?.activeGenerationContext = nil
                    // Stop keep-alive
                    self?.keepAliveService.stopKeepAlive(requestId: "ai_generation_\(conversationId.uuidString)")
                }
            }
            
            // Safety check first (no retry needed)
            let safetyCheck = safetyClassifier.performSafetyCheck(message)
            if safetyCheck.isTriggered {
                onComplete(.failure(.safetyTriggered(safetyCheck.response!)))
                return
            }
            
            // Check for inappropriate requests
            if safetyClassifier.isInappropriateRequest(message) {
                let refusalResponse = AIResponse(
                    mode: mode.rawValue,
                    title: "Unable to Help",
                    answerMarkdown: safetyClassifier.getRefusalMessage(),
                    citations: [],
                    followUps: ["What topics would you like to explore in Scripture?"],
                    actions: []
                )
                onComplete(.success(refusalResponse))
                return
            }
            
            // Build grounding context (can be cached, no retry needed)
            let groundingContext = await verseRepository.buildGroundingContext(
                from: message,
                translationId: translationId
            )
            
            // Build the prompt - now uses natural prose output
            let systemPrompt = buildSystemPrompt(mode: mode, grounding: groundingContext, requestType: requestType)
            let messages = buildMessages(
                systemPrompt: systemPrompt,
                conversation: conversation,
                userMessage: message
            )
            
            // Execute with retry, accumulating content for fallback saving
            do {
                let response = try await executeWithRetry(
                    requestType: requestType,
                    messages: messages,
                    onToken: { [weak self] token in
                        // Accumulate content for fallback saving
                        self?.activeGenerationContext?.accumulatedContent += token
                        onToken(token)
                    },
                    onRetry: onRetry
                )
                
                // Call the ViewModel's completion handler
                onComplete(.success(response))
                
                // Also save directly to storage as a fallback
                // This ensures the message is saved even if ViewModel was deallocated
                await self.saveResponseToStorageFallback(
                    response: response,
                    conversationId: conversationId
                )
                
                // Complete background processing notification (unless skipped for inline insights)
                if !skipNotification {
                    self.backgroundNotificationService.completeBackgroundProcessing(
                        conversationId: conversationId,
                        title: response.title,
                        preview: String(response.answerMarkdown.prefix(100))
                    )
                }
                
            } catch let error as AIResponseError {
                lastError = error
                onComplete(.failure(error))
            } catch {
                let aiError = AIResponseError.networkError(error)
                lastError = aiError
                onComplete(.failure(aiError))
            }
        }
    }
    
    /// Generate smart follow-up questions for a response (separate API call)
    func generateFollowUps(
        for responseContent: String,
        originalQuestion: String,
        mode: AIMode,
        onComplete: @escaping ([String]) -> Void
    ) {
        print("DEBUG TRCAIService: generateFollowUps called")
        Task {
            do {
                print("DEBUG TRCAIService: Calling fetchFollowUps API...")
                let followUps = try await fetchFollowUps(
                    responseContent: responseContent,
                    originalQuestion: originalQuestion,
                    mode: mode
                )
                print("DEBUG TRCAIService: fetchFollowUps returned \(followUps.count) follow-ups")
                
                // If API returned empty, use local fallback
                if followUps.isEmpty {
                    print("DEBUG TRCAIService: API returned empty, using local fallback")
                    let fallbackFollowUps = generateLocalFollowUps(from: responseContent, mode: mode)
                    print("DEBUG TRCAIService: Fallback generated \(fallbackFollowUps.count) follow-ups")
                    await MainActor.run {
                        onComplete(fallbackFollowUps)
                    }
                } else {
                    await MainActor.run {
                        onComplete(followUps)
                    }
                }
            } catch {
                print("DEBUG TRCAIService: fetchFollowUps failed with error: \(error), using fallback")
                // Fallback to local generation on error
                let fallbackFollowUps = generateLocalFollowUps(from: responseContent, mode: mode)
                print("DEBUG TRCAIService: Fallback generated \(fallbackFollowUps.count) follow-ups")
                await MainActor.run {
                    onComplete(fallbackFollowUps)
                }
            }
        }
    }
    
    /// Cancel the current request and all retry attempts
    func cancel() {
        // Stop keep-alive if active
        if let context = activeGenerationContext {
            keepAliveService.stopKeepAlive(requestId: "ai_generation_\(context.conversationId.uuidString)")
        }
        
        isCancelled = true
        currentTask?.cancel()
        isProcessing = false
        currentRetryAttempt = 0
        activeGenerationContext = nil
    }
    
    // MARK: - Fallback Storage
    
    /// Save response directly to storage as a fallback
    /// This ensures messages are saved even if the ViewModel was deallocated
    private func saveResponseToStorageFallback(
        response: AIResponse,
        conversationId: UUID
    ) async {
        // Check if there's a streaming message that needs to be finalized
        guard let context = activeGenerationContext,
              context.conversationId == conversationId else {
            return
        }
        
        // Check if the message was already saved by the ViewModel
        // by looking for an existing finalized message with the same content
        let existingMessages = storageService.conversations
            .first(where: { $0.id == conversationId })?
            .messages ?? []
        
        let alreadySaved = existingMessages.contains { msg in
            !msg.isStreaming &&
            msg.role == .assistant &&
            msg.content == response.answerMarkdown
        }
        
        if alreadySaved {
            print("TRCAIService: Response already saved by ViewModel")
            return
        }
        
        // Save directly - the ViewModel's callback must have been deallocated
        print("TRCAIService: Saving response via fallback (ViewModel was deallocated)")
        
        // Create finalized message
        let finalMessage = ChatMessage(
            id: context.streamingMessageId,
            role: .assistant,
            content: response.answerMarkdown,
            timestamp: Date(),
            title: response.title,
            citations: response.citations.map {
                AICitation(reference: $0.reference, translationId: $0.translationId)
            },
            followUps: response.followUps,
            mode: context.mode,
            isStreaming: false
        )
        
        // Remove streaming message and add finalized
        storageService.removeLastMessage(from: conversationId)
        storageService.addMessage(finalMessage, to: conversationId)
    }
    
    // MARK: - Follow-up Generation (Separate API Call)
    
    private func fetchFollowUps(
        responseContent: String,
        originalQuestion: String,
        mode: AIMode
    ) async throws -> [String] {
        guard let url = URL(string: baseURL) else {
            throw AIResponseError.invalidJSON
        }
        
        let followUpPrompt = buildFollowUpPrompt(
            responseContent: responseContent,
            originalQuestion: originalQuestion,
            mode: mode
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": followUpPrompt],
                ["role": "user", "content": "Generate 3 follow-up questions."]
            ],
            "max_completion_tokens": 300,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("DEBUG TRCAIService: Follow-up API failed with status \(statusCode)")
            print("DEBUG TRCAIService: Response body: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw AIResponseError.networkError(NSError(domain: "TRCAIService", code: statusCode))
        }
        
        // Parse the response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            print("DEBUG TRCAIService: Follow-up API response content: \(content)")
            return parseFollowUpsFromText(content)
        } else {
            print("DEBUG TRCAIService: Follow-up API response parsing failed")
            print("DEBUG TRCAIService: Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
        }
        
        return []
    }
    
    private func buildFollowUpPrompt(
        responseContent: String,
        originalQuestion: String,
        mode: AIMode
    ) -> String {
        let modeInstructions: String
        switch mode {
        case .study:
            modeInstructions = """
            Generate follow-ups that:
            - Probe deeper into Greek/Hebrew word meanings
            - Explore theological concepts and doctrines
            - Ask about historical context
            - Connect to other Scripture passages
            """
        case .devotional:
            modeInstructions = """
            Generate follow-ups that:
            - Invite personal reflection
            - Suggest practical life application
            - Connect to everyday struggles
            - Prompt prayer or meditation
            """
        case .prayer:
            modeInstructions = """
            Generate follow-ups that:
            - Offer specific prayer topics
            - Suggest verses to pray through
            - Guide intercession
            - Explore prayer practices
            """
        }
        
        return """
        Based on this Bible study conversation, generate exactly 3 specific follow-up questions.
        
        ORIGINAL QUESTION: \(originalQuestion)
        
        RESPONSE GIVEN:
        \(responseContent.prefix(500))...
        
        \(modeInstructions)
        
        RULES:
        - Each question must be specific to THIS conversation
        - Never use generic questions like "Tell me more" or "What else?"
        - Questions should be 10-20 words each
        - Include Scripture references where relevant
        
        Output ONLY the 3 questions, one per line, numbered 1-3.
        """
    }
    
    private func parseFollowUpsFromText(_ text: String) -> [String] {
        print("DEBUG TRCAIService: parseFollowUpsFromText input (\(text.count) chars): \(text.prefix(500))")
        var followUps: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            var cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            guard !cleanedLine.isEmpty else { continue }
            
            // Remove common prefixes using multiple patterns
            let prefixPatterns = [
                #"^\d+[\.\)\:\-]?\s*"#,      // 1. 1) 1: 1-
                #"^[-•\*]\s*"#,               // - • *
                #"^[Qq]\d*[\.\:\)]?\s*"#,     // Q: Q1. Q1)
                #"^\*\*\d+\.\*\*\s*"#,        // **1.**
                #"^>\s*"#                      // > (blockquote)
            ]
            
            for pattern in prefixPatterns {
                if let range = cleanedLine.range(of: pattern, options: .regularExpression) {
                    cleanedLine = String(cleanedLine[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
            }
            
            // Remove markdown bold/italic markers
            cleanedLine = cleanedLine.replacingOccurrences(of: "**", with: "")
            cleanedLine = cleanedLine.replacingOccurrences(of: "*", with: "")
            cleanedLine = cleanedLine.trimmingCharacters(in: .whitespaces)
            
            // Accept lines that look like questions (10+ chars, ends with ?)
            if cleanedLine.count >= 10 && cleanedLine.hasSuffix("?") {
                followUps.append(cleanedLine)
                print("DEBUG TRCAIService: Found question: \(cleanedLine.prefix(50))...")
            }
            // Also accept longer statements (15+ chars) as potential follow-ups
            else if cleanedLine.count >= 15 {
                followUps.append(cleanedLine)
                print("DEBUG TRCAIService: Found statement: \(cleanedLine.prefix(50))...")
            }
            
            if followUps.count >= 3 { break }
        }
        
        print("DEBUG TRCAIService: parseFollowUpsFromText parsed \(followUps.count) follow-ups: \(followUps)")
        return followUps
    }
    
    // MARK: - Retry Logic
    
    private func executeWithRetry(
        requestType: AIRequestType,
        messages: [[String: String]],
        onToken: @escaping (String) -> Void,
        onRetry: ((Int, Int) -> Void)?
    ) async throws -> AIResponse {
        var lastError: Error?
        
        for attempt in 1...retryConfig.maxAttempts {
            // Check for cancellation
            if isCancelled || Task.isCancelled {
                throw AIResponseError.networkError(NSError(domain: "TRCAIService", code: -999, userInfo: [NSLocalizedDescriptionKey: "Request cancelled"]))
            }
            
            currentRetryAttempt = attempt
            
            do {
                let response = try await streamCompletion(
                    messages: messages,
                    tokenLimit: requestType.tokenLimit,
                    onToken: onToken
                )
                
                // Success - return response
                return response
                
            } catch let error as AIResponseError {
                lastError = error
                
                // Check if error is retryable
                if !isRetryableError(error) {
                    throw error
                }
                
                // Don't retry if this was the last attempt
                if attempt >= retryConfig.maxAttempts {
                    throw error
                }
                
                // Calculate backoff delay
                let delay = retryConfig.delay(for: attempt)
                
                // Notify about retry
                await MainActor.run {
                    onRetry?(attempt, retryConfig.maxAttempts)
                }
                
                print("TRCAIService: Retry \(attempt)/\(retryConfig.maxAttempts) after \(delay)s delay. Error: \(error.localizedDescription)")
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                lastError = error
                
                // Network errors are retryable
                if attempt >= retryConfig.maxAttempts {
                    throw AIResponseError.networkError(error)
                }
                
                let delay = retryConfig.delay(for: attempt)
                await MainActor.run {
                    onRetry?(attempt, retryConfig.maxAttempts)
                }
                
                print("TRCAIService: Retry \(attempt)/\(retryConfig.maxAttempts) after \(delay)s delay. Network error: \(error.localizedDescription)")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? AIResponseError.networkError(NSError(domain: "TRCAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error after retries"]))
    }
    
    private func isRetryableError(_ error: AIResponseError) -> Bool {
        switch error {
        case .rateLimited:
            return true
        case .networkError(let underlyingError):
            let nsError = underlyingError as NSError
            if nsError.code == NSURLErrorTimedOut ||
               nsError.code == NSURLErrorNetworkConnectionLost ||
               nsError.code == NSURLErrorNotConnectedToInternet ||
               retryConfig.retryableStatusCodes.contains(nsError.code) {
                return true
            }
            return true // Be aggressive - retry most network errors
        case .invalidJSON:
            return true
        case .safetyTriggered, .usageLimitExceeded, .missingRequiredField:
            return false
        }
    }
    
    // MARK: - System Prompt Building (Natural Prose - No JSON)
    
    private func buildSystemPrompt(mode: AIMode, grounding: GroundingContext, requestType: AIRequestType) -> String {
        var prompt = """
        You are TRC AI, a warm and knowledgeable Bible assistant. Respond naturally and conversationally.
        
        CORE PRINCIPLES:
        1. Be helpful, warm, and pastoral in your responses
        2. Ground your answers in Scripture - cite verses in parentheses like (John 3:16)
        3. Never invent Bible verses - only cite what you're certain exists
        4. When denominations differ, present viewpoints fairly
        5. Keep responses focused and readable
        
        \(mode.systemPromptAddition)
        
        """
        
        // Add user preferences
        prompt += preferencesService.buildPreferencePrompt()
        
        // Add grounding context if available
        if !grounding.isEmpty {
            prompt += """
            
            VERIFIED VERSES FROM USER'S BIBLE:
            \(grounding.formatForPrompt())
            
            You may quote these directly. For other verses, only cite if certain they exist.
            
            """
        }
        
        // Add memory context if enabled
        if preferencesService.isMemoryEnabled {
            let memoryContext = memoryService.memoryContext
            if !memoryContext.isEmpty {
                prompt += memoryContext.formatForPrompt()
            }
        }
        
        // Add reading plan context for premium users
        if AIUsageManager.shared.isPremium {
            prompt += buildReadingPlanContext()
        }
        
        // Add request-type specific instructions
        switch requestType {
        case .deeper:
            prompt += """
            
            GO DEEPER REQUEST:
            Provide a comprehensive exploration including:
            - Additional Scripture passages (3-5 more verses)
            - Historical and cultural context
            - Theological perspectives from different traditions
            - Practical life application
            - Cross-references to related themes
            
            Take your time. This response can be thorough.
            
            """
        case .shorter:
            prompt += """
            
            MAKE SHORTER REQUEST:
            - Distill to 2-3 sentences maximum
            - Keep only the most essential Scripture reference
            - Focus on the single key takeaway
            
            Be extremely concise.
            
            """
        case .normal, .followUp, .continuation:
            break
        }
        
        prompt += """
        
        RESPONSE FORMAT:
        - Write in natural, flowing prose
        - Use **bold** for key points or Scripture quotes
        - Include verse references in parentheses: (John 3:16)
        - Be conversational and encouraging
        - End with a brief thought, prayer, or encouragement when appropriate
        
        Just respond naturally. Do NOT output JSON or any structured format.
        """
        
        return prompt
    }
    
    /// Build reading plan context for premium users
    private func buildReadingPlanContext() -> String {
        let storage = HubStorageService.shared
        
        guard let activeId = storage.activeReadingPlanId,
              let progress = storage.getProgress(for: activeId),
              let plan = ReadingPlan.allPlans.first(where: { $0.id == activeId }) else {
            return ""
        }
        
        let currentDayIndex = progress.currentDay - 1
        guard currentDayIndex >= 0 && currentDayIndex < plan.days.count else {
            return ""
        }
        
        let currentDay = plan.days[currentDayIndex]
        let readings = currentDay.readings.map { $0.displayReference }.joined(separator: ", ")
        
        return """
        
        CURRENT READING PLAN:
        The user is on Day \(progress.currentDay) of "\(plan.name)".
        Today's reading: \(readings)
        Progress: \(progress.completedDays.count)/\(plan.days.count) days completed
        
        When relevant to their question, reference today's reading passages to provide personalized context.
        
        """
    }
    
    /// Get the token limit based on user preferences and request type
    private func getTokenLimit(for requestType: AIRequestType) -> Int {
        // For special request types, use their specific limits
        switch requestType {
        case .deeper:
            return 3000
        case .shorter:
            return 800
        case .followUp:
            return 300
        case .continuation:
            return 1000
        case .normal:
            // Use user's preference for normal requests
            return preferencesService.preferredTokenLimit
        }
    }
    
    private func buildMessages(
        systemPrompt: String,
        conversation: ChatConversation,
        userMessage: String
    ) -> [[String: String]] {
        var messages: [[String: String]] = []
        
        // System message
        messages.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // Conversation history - Premium users get extended context
        let contextLimit = AIUsageManager.shared.isPremium ? 25 : 10
        let contextMessages = conversation.buildContextMessages(limit: contextLimit)
        messages.append(contentsOf: contextMessages)
        
        // Current user message
        messages.append([
            "role": "user",
            "content": userMessage
        ])
        
        return messages
    }
    
    // MARK: - Streaming Implementation (Simplified - Direct Pass-through)
    
    private func streamCompletion(
        messages: [[String: String]],
        tokenLimit: Int,
        onToken: @escaping (String) -> Void
    ) async throws -> AIResponse {
        guard let url = URL(string: baseURL) else {
            throw AIResponseError.invalidJSON
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_completion_tokens": tokenLimit,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (asyncBytes, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIResponseError.networkError(NSError(domain: "TRCAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        // Handle non-success status codes
        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            var errorBody = ""
            for try await line in asyncBytes.lines {
                errorBody += line
            }
            
            var errorMessage = "API error \(httpResponse.statusCode)"
            if let data = errorBody.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                errorMessage = message
            }
            
            switch httpResponse.statusCode {
            case 429:
                throw AIResponseError.rateLimited
            case 401:
                throw AIResponseError.networkError(NSError(domain: "TRCAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key"]))
            default:
                throw AIResponseError.networkError(NSError(domain: "TRCAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
        }
        
        // Stream content directly - no JSON parsing needed
        var fullContent = ""
        var hasReceivedContent = false
        
        for try await line in asyncBytes.lines {
            // Check for cancellation
            if Task.isCancelled || isCancelled { break }
            
            // Parse SSE format
            guard line.hasPrefix("data: ") else { continue }
            
            let data = String(line.dropFirst(6))
            
            // Check for stream end
            if data == "[DONE]" { break }
            
            // Parse the JSON chunk
            guard let jsonData = data.data(using: .utf8),
                  let chunk = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let choices = chunk["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let delta = firstChoice["delta"] as? [String: Any],
                  let content = delta["content"] as? String else {
                continue
            }
            
            hasReceivedContent = true
            fullContent += content
            
            // Stream directly to UI - no JSON extraction needed
            onToken(content)
        }
        
        // Validate we received content
        if !hasReceivedContent || fullContent.isEmpty {
            throw AIResponseError.networkError(NSError(domain: "TRCAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty response from API"]))
        }
        
        // Create response from plain text (follow-ups will be generated separately)
        return createResponse(from: fullContent)
    }
    
    // MARK: - Response Creation
    
    private func createResponse(from content: String) -> AIResponse {
        // Extract citations from the text
        let citations = extractCitationsFromText(content)
        
        // Generate a title from the first sentence
        let title = generateTitle(from: content)
        
        // Follow-ups will be populated later by separate API call
        // For now, return empty - ViewModel will request them
        return AIResponse(
            mode: "study",
            title: title,
            answerMarkdown: content,
            citations: citations,
            followUps: [], // Will be populated by generateFollowUps()
            actions: []
        )
    }
    
    private func extractCitationsFromText(_ content: String) -> [RawCitation] {
        var citations: [RawCitation] = []
        
        // Use the enhanced reference parser to extract citations
        let parsedReferences = referenceParser.parseAll(from: content)
        var seenReferences = Set<String>()
        
        for parsed in parsedReferences {
            let reference = parsed.canonicalReference
            
            // Skip duplicates
            if seenReferences.contains(reference) {
                continue
            }
            
            // Pre-verify the citation to filter out potential hallucinations
            let validationResult = referenceParser.validate(parsed)
            guard validationResult.isValid else {
                if case .invalid(let reason) = validationResult {
                    print("TRCAIService: Filtering citation '\(reference)': \(reason)")
                }
                continue
            }
            
            seenReferences.insert(reference)
            citations.append(RawCitation(reference: reference, translation: nil))
        }
        
        // Also check for inline references not in parentheses using legacy pattern as fallback
        let legacyPattern = #"\((\d?\s*[A-Za-z]+(?:\s+[A-Za-z]+)*\s+\d+:\d+(?:-\d+)?)\)"#
        
        if let regex = try? NSRegularExpression(pattern: legacyPattern, options: []) {
            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: content) {
                    var reference = String(content[range])
                    reference = reference.components(separatedBy: .whitespaces)
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    
                    // Skip if already seen
                    if seenReferences.contains(reference) {
                        continue
                    }
                    
                    // Validate using parser
                    if let parsed = referenceParser.parse(reference) {
                        let validationResult = referenceParser.validate(parsed)
                        if validationResult.isValid {
                            seenReferences.insert(reference)
                            citations.append(RawCitation(reference: parsed.canonicalReference, translation: nil))
                        }
                    }
                }
            }
        }
        
        return citations
    }
    
    private func generateTitle(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to get first sentence
        if let dotIndex = trimmed.firstIndex(of: ".") {
            let firstSentence = String(trimmed[..<dotIndex])
            if firstSentence.count > 5 && firstSentence.count < 60 {
                return firstSentence
            }
        }
        
        // Fallback to first 50 chars
        if trimmed.count > 50 {
            let endIndex = trimmed.index(trimmed.startIndex, offsetBy: 50)
            return String(trimmed[..<endIndex]) + "..."
        }
        
        return trimmed.isEmpty ? "Response" : trimmed
    }
    
    /// Generate follow-ups locally (fallback when API call fails)
    private func generateLocalFollowUps(from content: String, mode: AIMode) -> [String] {
        print("DEBUG TRCAIService: Generating local fallback follow-ups for mode: \(mode)")
        var followUps: [String] = []
        let lowercased = content.lowercased()
        
        // Extract any verse references mentioned for contextual questions
        let verses = ReferenceParser.shared.parseAll(from: content).prefix(2).map { $0.rawInput }
        
        // Mode-specific follow-ups with verse context
        switch mode {
        case .study:
            if let verse = verses.first {
                followUps.append("How does \(verse) connect to other Scripture?")
            }
            if lowercased.contains("jesus") || lowercased.contains("christ") {
                followUps.append("What does this passage reveal about Jesus' character and mission?")
            }
            if lowercased.contains("paul") {
                followUps.append("How does this connect to Paul's other letters?")
            }
            if lowercased.contains("covenant") || lowercased.contains("promise") {
                followUps.append("How does this relate to God's covenant promises throughout Scripture?")
            }
            if lowercased.contains("greek") || lowercased.contains("hebrew") {
                followUps.append("What do other key words in this passage mean?")
            }
            
        case .devotional:
            followUps.append("How can I apply this truth in my life this week?")
            if lowercased.contains("love") || lowercased.contains("forgive") {
                followUps.append("Who in my life needs me to show this kind of love?")
            }
            if lowercased.contains("faith") || lowercased.contains("trust") {
                followUps.append("What area of my life do I need to trust God more?")
            }
            if let verse = verses.first {
                followUps.append("What prayer might help me internalize \(verse)?")
            }
            
        case .prayer:
            followUps.append("Can you help me pray through this passage?")
            if lowercased.contains("thank") || lowercased.contains("praise") {
                followUps.append("What specific things can I thank God for today?")
            }
            if let verse = verses.first {
                followUps.append("How can I pray \(verse) over my situation?")
            }
            followUps.append("How can I intercede for others using this Scripture?")
        }
        
        // Fill to 3 with contextual defaults - always ensure we have 3
        let defaultsByMode: [AIMode: [String]] = [
            .study: [
                "What is the historical context of this passage?",
                "What do the original Greek or Hebrew words reveal?",
                "How have different theologians interpreted this?"
            ],
            .devotional: [
                "What does this teach me about God's character?",
                "How can I meditate on this throughout my day?",
                "Are there similar promises elsewhere in Scripture?"
            ],
            .prayer: [
                "What Scripture can I pray over this situation?",
                "How can I praise God in the midst of this?",
                "What has God promised about this area of life?"
            ]
        ]
        
        let defaults = defaultsByMode[mode] ?? []
        for d in defaults where !followUps.contains(d) && followUps.count < 3 {
            followUps.append(d)
        }
        
        let result = Array(followUps.prefix(3))
        print("DEBUG TRCAIService: Generated \(result.count) local follow-ups: \(result)")
        return result
    }
}

// MARK: - Follow-up Requests

extension TRCAIService {
    
    /// Request a shorter version of the previous response with full context
    func requestShorter(
        previousContent: String,
        previousCitations: [AICitation],
        mode: AIMode,
        conversation: ChatConversation,
        translationId: String,
        onToken: @escaping (String) -> Void,
        onRetry: ((Int, Int) -> Void)? = nil,
        onComplete: @escaping (Result<AIResponse, AIResponseError>) -> Void
    ) {
        let citationsList = previousCitations.map { $0.reference }.joined(separator: ", ")
        
        let prompt = """
        Please provide a much shorter version of your previous response.
        
        PREVIOUS RESPONSE TO CONDENSE:
        \(previousContent)
        
        KEY VERSES TO PRESERVE: \(citationsList.isEmpty ? "None specified" : citationsList)
        
        Requirements:
        - Maximum 2-3 sentences
        - Keep only the single most important Scripture reference
        - Focus on the core takeaway
        - Remove all elaboration
        """
        
        sendMessage(
            prompt,
            mode: mode,
            conversation: conversation,
            translationId: translationId,
            requestType: .shorter,
            onToken: onToken,
            onRetry: onRetry,
            onComplete: onComplete
        )
    }
    
    /// Request a deeper exploration with full context
    func requestDeeper(
        previousContent: String,
        previousCitations: [AICitation],
        mode: AIMode,
        conversation: ChatConversation,
        translationId: String,
        onToken: @escaping (String) -> Void,
        onRetry: ((Int, Int) -> Void)? = nil,
        onComplete: @escaping (Result<AIResponse, AIResponseError>) -> Void
    ) {
        let citationsList = previousCitations.map { $0.reference }.joined(separator: ", ")
        
        let prompt = """
        Please go much deeper on the topic from your previous response.
        
        PREVIOUS RESPONSE TO EXPAND:
        \(previousContent)
        
        VERSES ALREADY MENTIONED: \(citationsList.isEmpty ? "None" : citationsList)
        
        Please provide a comprehensive expansion including:
        1. **Additional Scripture** - 3-5 more relevant passages I should study
        2. **Historical Context** - What was happening when this was written? Who was the audience?
        3. **Greek/Hebrew Insights** - Any significant word meanings in the original languages
        4. **Theological Perspectives** - How do different Christian traditions view this?
        5. **Practical Application** - Specific, actionable ways to apply this today
        6. **Cross-References** - How does this connect to other biblical themes?
        
        Take your time and be thorough.
        """
        
        sendMessage(
            prompt,
            mode: mode,
            conversation: conversation,
            translationId: translationId,
            requestType: .deeper,
            onToken: onToken,
            onRetry: onRetry,
            onComplete: onComplete
        )
    }
    
    // MARK: - Verse Analysis (TRC Insight)
    
    /// Analyze a specific verse with a chosen analysis type
    /// Note: Skips notification banner since the result is shown inline in the reader
    func analyzeVerse(
        verseReference: VerseReference,
        analysisType: InsightAnalysisType,
        conversation: ChatConversation,
        translationId: String,
        onToken: @escaping (String) -> Void,
        onRetry: ((Int, Int) -> Void)? = nil,
        onComplete: @escaping (Result<AIResponse, AIResponseError>) -> Void
    ) {
        let prompt = buildVerseAnalysisPrompt(
            reference: verseReference,
            analysisType: analysisType
        )
        
        sendMessage(
            prompt,
            mode: .study, // Always use study mode for verse analysis
            conversation: conversation,
            translationId: translationId,
            requestType: .deeper, // Use higher token limit for comprehensive analysis
            skipNotification: true, // Skip notification banner - result shown inline
            onToken: onToken,
            onRetry: onRetry,
            onComplete: onComplete
        )
    }
    
    /// Build the analysis prompt based on verse and analysis type
    private func buildVerseAnalysisPrompt(
        reference: VerseReference,
        analysisType: InsightAnalysisType
    ) -> String {
        let verseContext = """
        VERSE TO ANALYZE:
        \(reference.fullReference)
        
        "\(reference.text)"
        
        Translation: \(reference.translationId)
        """
        
        let typeInstructions = analysisType.systemPromptAddition
        
        return """
        \(verseContext)
        
        ANALYSIS TYPE: \(analysisType.displayName)
        
        \(typeInstructions)
        
        Provide a thoughtful, well-organized analysis. Cite relevant Scripture references in parentheses like (Romans 8:28).
        """
    }
}
