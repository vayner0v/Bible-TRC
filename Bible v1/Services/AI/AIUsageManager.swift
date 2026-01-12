//
//  AIUsageManager.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Usage Limits & Freemium Management
//

import Foundation
import Combine

/// Manages usage limits for the AI assistant (freemium model)
/// Free tier: 12 messages every 6 hours
/// Premium: Unlimited
@MainActor
class AIUsageManager: ObservableObject {
    static let shared = AIUsageManager()
    
    // MARK: - Configuration
    
    /// Maximum messages per period for free tier
    private let freeLimit = 12
    
    /// Period duration in seconds (6 hours)
    private let periodDuration: TimeInterval = 6 * 60 * 60
    
    // MARK: - Storage Keys
    
    private let usageHistoryKey = "trc_ai_usage_history"
    private let premiumStatusKey = "trc_ai_premium_status"
    
    // MARK: - Published State
    
    @Published private(set) var messagesUsed: Int = 0
    @Published private(set) var messagesRemaining: Int = 12
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var nextResetTime: Date?
    
    // MARK: - Private State
    
    private var usageHistory: [UsageRecord] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadUsageHistory()
        loadPremiumStatus()
        updateState()
        
        // Clean up old records periodically
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupExpiredRecords()
                self?.updateState()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    /// Check if user can send a message
    var canSendMessage: Bool {
        isPremium || messagesRemaining > 0
    }
    
    /// Record a message usage
    func recordUsage() {
        guard !isPremium else { return }
        
        let record = UsageRecord(timestamp: Date())
        usageHistory.append(record)
        saveUsageHistory()
        updateState()
    }
    
    /// Get the time remaining until next reset (formatted)
    var timeUntilReset: String? {
        guard let resetTime = nextResetTime else { return nil }
        
        let interval = resetTime.timeIntervalSinceNow
        if interval <= 0 { return nil }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Get usage status message
    var usageStatusMessage: String {
        if isPremium {
            return "Premium - Unlimited messages"
        }
        
        if messagesRemaining <= 0 {
            if let time = timeUntilReset {
                return "Limit reached. Resets in \(time)"
            }
            return "Limit reached"
        }
        
        return "\(messagesRemaining) messages remaining"
    }
    
    /// Get usage as a fraction (for progress indicators)
    var usageFraction: Double {
        if isPremium { return 0 }
        return Double(messagesUsed) / Double(freeLimit)
    }
    
    /// Set premium status (called from subscription manager)
    func setPremiumStatus(_ premium: Bool) {
        isPremium = premium
        UserDefaults.standard.set(premium, forKey: premiumStatusKey)
        updateState()
    }
    
    /// Manually reset usage (for testing or admin purposes)
    func resetUsage() {
        usageHistory.removeAll()
        saveUsageHistory()
        updateState()
    }
    
    // MARK: - Private Methods
    
    private func loadUsageHistory() {
        guard let data = UserDefaults.standard.data(forKey: usageHistoryKey),
              let records = try? JSONDecoder().decode([UsageRecord].self, from: data) else {
            usageHistory = []
            return
        }
        usageHistory = records
    }
    
    private func saveUsageHistory() {
        guard let data = try? JSONEncoder().encode(usageHistory) else { return }
        UserDefaults.standard.set(data, forKey: usageHistoryKey)
    }
    
    private func loadPremiumStatus() {
        // Check with SubscriptionManager
        let manager = SubscriptionManager.shared
        isPremium = manager.isPremium
    }
    
    private func cleanupExpiredRecords() {
        let cutoff = Date().addingTimeInterval(-periodDuration)
        usageHistory.removeAll { $0.timestamp < cutoff }
        saveUsageHistory()
    }
    
    private func updateState() {
        // Clean expired records
        let cutoff = Date().addingTimeInterval(-periodDuration)
        let activeRecords = usageHistory.filter { $0.timestamp >= cutoff }
        
        messagesUsed = activeRecords.count
        messagesRemaining = max(0, freeLimit - messagesUsed)
        
        // Calculate next reset time (when oldest active record expires)
        if let oldestRecord = activeRecords.min(by: { $0.timestamp < $1.timestamp }) {
            nextResetTime = oldestRecord.timestamp.addingTimeInterval(periodDuration)
        } else {
            nextResetTime = nil
        }
    }
}

// MARK: - Usage Record

private struct UsageRecord: Codable {
    let id: UUID
    let timestamp: Date
    
    init(id: UUID = UUID(), timestamp: Date) {
        self.id = id
        self.timestamp = timestamp
    }
}

// MARK: - Usage Limit Error

enum UsageLimitError: LocalizedError {
    case limitReached(resetTime: Date?)
    
    var errorDescription: String? {
        switch self {
        case .limitReached(let resetTime):
            if let reset = resetTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "You've used all your free messages. Resets at \(formatter.string(from: reset))."
            }
            return "You've used all your free messages."
        }
    }
}

// MARK: - Premium Upgrade Prompt

extension AIUsageManager {
    
    /// Generate an upgrade prompt message
    var upgradePromptMessage: String {
        """
        You've reached your free message limit!
        
        Upgrade to Premium for:
        • Unlimited AI conversations
        • All three modes: Study, Devotional, Prayer
        • Priority response times
        • Support app development
        
        Your limit will reset in \(timeUntilReset ?? "a few hours"), or upgrade now for unlimited access.
        """
    }
    
    /// Check if should show upgrade prompt
    var shouldShowUpgradePrompt: Bool {
        !isPremium && messagesRemaining <= 0
    }
    
    /// Check if should show low usage warning
    var shouldShowLowUsageWarning: Bool {
        !isPremium && messagesRemaining <= 3 && messagesRemaining > 0
    }
    
    /// Get low usage warning message
    var lowUsageWarningMessage: String {
        "\(messagesRemaining) message\(messagesRemaining == 1 ? "" : "s") remaining. Consider upgrading for unlimited access."
    }
}

