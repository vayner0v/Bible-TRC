//
//  UsageTrackingService.swift
//  Bible v1
//
//  Tracks TTS API usage to prevent excessive costs
//

import Foundation
import Combine

/// Service for tracking TTS API usage with daily and monthly limits
@MainActor
class UsageTrackingService: ObservableObject {
    static let shared = UsageTrackingService()
    
    // MARK: - Usage Limits
    
    /// Monthly character limit (2M characters = ~450 chapters)
    static let monthlyCharacterLimit = 2_000_000
    
    /// Daily character limit (100K characters = ~22 chapters)
    static let dailyCharacterLimit = 100_000
    
    // MARK: - Published Properties
    
    @Published private(set) var dailyUsage: Int = 0
    @Published private(set) var monthlyUsage: Int = 0
    @Published private(set) var lastResetDate: Date = Date()
    @Published private(set) var monthStartDate: Date = Date()
    
    // MARK: - Private Properties
    
    private enum Keys {
        static let dailyUsage = "usage_daily_characters"
        static let monthlyUsage = "usage_monthly_characters"
        static let lastResetDate = "usage_last_reset_date"
        static let monthStartDate = "usage_month_start_date"
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadUsageData()
        checkAndResetIfNeeded()
        
        // Set up daily reset timer
        setupResetTimer()
    }
    
    // MARK: - Usage Tracking
    
    /// Record character usage
    /// - Parameter characters: Number of characters used
    func recordUsage(characters: Int) {
        checkAndResetIfNeeded()
        
        dailyUsage += characters
        monthlyUsage += characters
        
        saveUsageData()
        
        // Check if limits are reached - notify via NotificationCenter to avoid circular dependency
        if isDailyLimitReached || isMonthlyLimitReached {
            NotificationCenter.default.post(name: .usageLimitReached, object: nil)
        }
    }
    
    /// Check if text would exceed limits
    /// - Parameter text: Text to check
    /// - Returns: Whether the text can be processed
    func canProcess(text: String) -> Bool {
        let chars = text.count
        return canProcess(characters: chars)
    }
    
    /// Check if character count would exceed limits
    /// - Parameter characters: Character count to check
    /// - Returns: Whether the characters can be processed
    func canProcess(characters: Int) -> Bool {
        checkAndResetIfNeeded()
        
        let wouldExceedDaily = (dailyUsage + characters) > Self.dailyCharacterLimit
        let wouldExceedMonthly = (monthlyUsage + characters) > Self.monthlyCharacterLimit
        
        return !wouldExceedDaily && !wouldExceedMonthly
    }
    
    /// Get remaining daily characters
    var remainingDailyCharacters: Int {
        max(0, Self.dailyCharacterLimit - dailyUsage)
    }
    
    /// Get remaining monthly characters
    var remainingMonthlyCharacters: Int {
        max(0, Self.monthlyCharacterLimit - monthlyUsage)
    }
    
    /// Check if daily limit is reached
    var isDailyLimitReached: Bool {
        dailyUsage >= Self.dailyCharacterLimit
    }
    
    /// Check if monthly limit is reached
    var isMonthlyLimitReached: Bool {
        monthlyUsage >= Self.monthlyCharacterLimit
    }
    
    /// Daily usage percentage (0-100)
    var dailyUsagePercentage: Double {
        Double(dailyUsage) / Double(Self.dailyCharacterLimit) * 100
    }
    
    /// Monthly usage percentage (0-100)
    var monthlyUsagePercentage: Double {
        Double(monthlyUsage) / Double(Self.monthlyCharacterLimit) * 100
    }
    
    // MARK: - Usage Display
    
    /// Format characters for display
    func formatCharacters(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
    
    /// Daily usage display string
    var dailyUsageDisplay: String {
        "\(formatCharacters(dailyUsage)) / \(formatCharacters(Self.dailyCharacterLimit))"
    }
    
    /// Monthly usage display string
    var monthlyUsageDisplay: String {
        "\(formatCharacters(monthlyUsage)) / \(formatCharacters(Self.monthlyCharacterLimit))"
    }
    
    /// Estimated chapters remaining today
    var estimatedChaptersRemainingToday: Int {
        // Average chapter is ~4,500 characters
        return remainingDailyCharacters / 4_500
    }
    
    /// Estimated chapters remaining this month
    var estimatedChaptersRemainingMonth: Int {
        return remainingMonthlyCharacters / 4_500
    }
    
    // MARK: - Reset Logic
    
    /// Check if usage should be reset and perform reset if needed
    private func checkAndResetIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check for daily reset
        if !calendar.isDate(lastResetDate, inSameDayAs: now) {
            resetDailyUsage()
        }
        
        // Check for monthly reset
        let lastMonth = calendar.component(.month, from: monthStartDate)
        let currentMonth = calendar.component(.month, from: now)
        
        if lastMonth != currentMonth {
            resetMonthlyUsage()
        }
    }
    
    /// Reset daily usage
    private func resetDailyUsage() {
        dailyUsage = 0
        lastResetDate = Date()
        
        // Notify via NotificationCenter to avoid circular dependency
        NotificationCenter.default.post(name: .usageLimitReset, object: nil)
        
        saveUsageData()
    }
    
    /// Reset monthly usage
    private func resetMonthlyUsage() {
        monthlyUsage = 0
        monthStartDate = Date()
        
        // Notify via NotificationCenter to avoid circular dependency
        NotificationCenter.default.post(name: .usageLimitReset, object: nil)
        
        saveUsageData()
    }
    
    /// Manual reset (for testing or admin purposes)
    func manualReset() {
        dailyUsage = 0
        monthlyUsage = 0
        lastResetDate = Date()
        monthStartDate = Date()
        
        // Notify via NotificationCenter to avoid circular dependency
        NotificationCenter.default.post(name: .usageLimitReset, object: nil)
        
        saveUsageData()
    }
    
    // MARK: - Timer Setup
    
    private func setupResetTimer() {
        // Check for reset every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAndResetIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Persistence
    
    private func saveUsageData() {
        let defaults = UserDefaults.standard
        defaults.set(dailyUsage, forKey: Keys.dailyUsage)
        defaults.set(monthlyUsage, forKey: Keys.monthlyUsage)
        defaults.set(lastResetDate, forKey: Keys.lastResetDate)
        defaults.set(monthStartDate, forKey: Keys.monthStartDate)
    }
    
    private func loadUsageData() {
        let defaults = UserDefaults.standard
        
        dailyUsage = defaults.integer(forKey: Keys.dailyUsage)
        monthlyUsage = defaults.integer(forKey: Keys.monthlyUsage)
        
        if let lastReset = defaults.object(forKey: Keys.lastResetDate) as? Date {
            lastResetDate = lastReset
        } else {
            lastResetDate = Date()
        }
        
        if let monthStart = defaults.object(forKey: Keys.monthStartDate) as? Date {
            monthStartDate = monthStart
        } else {
            monthStartDate = Date()
        }
    }
    
    // MARK: - Cost Estimation
    
    /// Estimate cost for current monthly usage (at $15/1M chars)
    var estimatedMonthlyCost: Double {
        return Double(monthlyUsage) / 1_000_000 * 15.0
    }
    
    /// Format cost for display
    var formattedMonthlyCost: String {
        return String(format: "$%.2f", estimatedMonthlyCost)
    }
}

// MARK: - Usage Statistics

struct UsageStatistics {
    let dailyUsage: Int
    let monthlyUsage: Int
    let dailyLimit: Int
    let monthlyLimit: Int
    let dailyRemaining: Int
    let monthlyRemaining: Int
    let chaptersRemainingToday: Int
    let chaptersRemainingMonth: Int
    
    static func current() -> UsageStatistics {
        let service = UsageTrackingService.shared
        return UsageStatistics(
            dailyUsage: service.dailyUsage,
            monthlyUsage: service.monthlyUsage,
            dailyLimit: UsageTrackingService.dailyCharacterLimit,
            monthlyLimit: UsageTrackingService.monthlyCharacterLimit,
            dailyRemaining: service.remainingDailyCharacters,
            monthlyRemaining: service.remainingMonthlyCharacters,
            chaptersRemainingToday: service.estimatedChaptersRemainingToday,
            chaptersRemainingMonth: service.estimatedChaptersRemainingMonth
        )
    }
}

