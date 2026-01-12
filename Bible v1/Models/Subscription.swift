//
//  Subscription.swift
//  Bible v1
//
//  Subscription Models for Premium Features
//

import Foundation

/// Subscription tier levels
enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
    
    var description: String {
        switch self {
        case .free: return "Basic features with system TTS"
        case .premium: return "AI voices, unlimited listening, and more"
        }
    }
}

/// Product identifiers for App Store Connect - Subscriptions
enum SubscriptionProductID: String, CaseIterable {
    case monthlyPremium = "com.bibleapp.premium.monthly"
    case yearlyPremium = "com.bibleapp.premium.yearly"
    
    var displayName: String {
        switch self {
        case .monthlyPremium: return "Monthly"
        case .yearlyPremium: return "Annual"
        }
    }
    
    var priceDisplay: String {
        switch self {
        case .monthlyPremium: return "$9.99/month"
        case .yearlyPremium: return "$99.99/year"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthlyPremium: return nil
        case .yearlyPremium: return "Save $20"
        }
    }
    
    var tier: SubscriptionTier {
        return .premium
    }
}

/// Product identifiers for one-time purchases
enum OneTimePurchaseProductID: String, CaseIterable {
    case themeStudio = "com.bibleapp.themestudio"
    
    var displayName: String {
        switch self {
        case .themeStudio: return "Theme Studio"
        }
    }
    
    var description: String {
        switch self {
        case .themeStudio: return "Create your own custom theme with personalized colors and styles"
        }
    }
    
    /// Original price before sale
    var originalPrice: String {
        switch self {
        case .themeStudio: return "$4.99"
        }
    }
    
    /// Current sale price
    var salePrice: String {
        switch self {
        case .themeStudio: return "$3.33"
        }
    }
    
    /// Whether currently on sale
    var isOnSale: Bool {
        switch self {
        case .themeStudio: return true
        }
    }
    
    /// Discount percentage
    var discountPercentage: Int {
        switch self {
        case .themeStudio: return 33 // 33% off
        }
    }
    
    /// Icon for the product
    var icon: String {
        switch self {
        case .themeStudio: return "paintpalette.fill"
        }
    }
}

/// Current subscription status
struct SubscriptionStatus: Codable {
    let tier: SubscriptionTier
    let productId: String?
    let expirationDate: Date?
    let isActive: Bool
    let willRenew: Bool
    
    init(
        tier: SubscriptionTier = .free,
        productId: String? = nil,
        expirationDate: Date? = nil,
        isActive: Bool = false,
        willRenew: Bool = false
    ) {
        self.tier = tier
        self.productId = productId
        self.expirationDate = expirationDate
        self.isActive = isActive
        self.willRenew = willRenew
    }
    
    /// Check if subscription is currently valid
    var isValid: Bool {
        guard tier == .premium else { return false }
        guard let expDate = expirationDate else { return false }
        return expDate > Date() && isActive
    }
    
    /// Days until expiration
    var daysUntilExpiration: Int? {
        guard let expDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expDate).day
    }
    
    /// Formatted expiration date
    var formattedExpirationDate: String? {
        guard let expDate = expirationDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expDate)
    }
    
    /// Free tier status
    static let free = SubscriptionStatus(tier: .free)
}

/// Premium feature model
struct PremiumFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

/// Premium features available to subscribers
struct PremiumFeatures {
    static let features: [PremiumFeature] = [
        PremiumFeature(icon: "sparkles", title: "Unlimited TRC AI", description: "Unlimited AI Bible assistant conversations"),
        PremiumFeature(icon: "waveform.circle.fill", title: "AI Voices", description: "Natural, expressive narration powered by OpenAI"),
        PremiumFeature(icon: "infinity", title: "Unlimited Listening", description: "No daily limits on AI audio generation"),
        PremiumFeature(icon: "bolt.fill", title: "Priority Generation", description: "Faster audio & AI processing"),
        PremiumFeature(icon: "arrow.down.circle.fill", title: "Offline Caching", description: "Save AI audio for offline listening"),
        PremiumFeature(icon: "brain.head.profile", title: "AI Memory", description: "TRC AI remembers your prayer requests & preferences"),
        PremiumFeature(icon: "heart.fill", title: "Support Development", description: "Help us keep improving the app")
    ]
}

/// Subscription event for analytics
enum SubscriptionEvent: String {
    case viewedPaywall = "viewed_paywall"
    case startedPurchase = "started_purchase"
    case completedPurchase = "completed_purchase"
    case cancelledPurchase = "cancelled_purchase"
    case restoredPurchase = "restored_purchase"
    case subscriptionExpired = "subscription_expired"
    case subscriptionRenewed = "subscription_renewed"
}

