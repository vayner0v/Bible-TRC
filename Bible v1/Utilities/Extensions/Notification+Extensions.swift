//
//  Notification+Extensions.swift
//  Bible v1
//
//  Notification names for decoupled service communication
//

import Foundation

extension Notification.Name {
    // MARK: - Usage Tracking Notifications
    
    /// Posted when the daily or monthly usage limit is reached
    static let usageLimitReached = Notification.Name("usageLimitReached")
    
    /// Posted when usage limits are reset (daily or monthly)
    static let usageLimitReset = Notification.Name("usageLimitReset")
    
    // MARK: - Subscription Notifications
    
    /// Posted when subscription status changes
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
    
    // MARK: - Audio Notifications
    
    /// Posted when audio playback completes the current chapter and auto-continue is enabled
    static let audioChapterCompleted = Notification.Name("audioChapterCompleted")
}

