//
//  SubscriptionManager.swift
//  Bible v1
//
//  StoreKit 2 Subscription Management
//

import Foundation
import StoreKit
import Combine

/// Manages in-app subscriptions using StoreKit 2
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var oneTimeProducts: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .free
    @Published private(set) var themeStudioPurchased: Bool = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Error>?
    private let subscriptionProductIDs = SubscriptionProductID.allCases.map { $0.rawValue }
    private let oneTimeProductIDs = OneTimePurchaseProductID.allCases.map { $0.rawValue }
    
    /// Combined product IDs for loading
    private var allProductIDs: [String] {
        subscriptionProductIDs + oneTimeProductIDs
    }
    
    /// Flag to track if initialization is complete - prevents circular dependency crashes
    private var isInitialized = false
    
    // UserDefaults keys for caching
    private enum Keys {
        static let subscriptionStatus = "subscription_status_cache"
        static let lastVerificationDate = "subscription_last_verification"
        static let themeStudioPurchased = "theme_studio_purchased"
    }
    
    // MARK: - Initialization
    
    init() {
        // Load cached subscription status
        loadCachedSubscriptionStatus()
        loadCachedThemeStudioStatus()
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Mark initialization as complete
        isInitialized = true
        
        // Load products and verify subscription
        Task { [weak self] in
            await self?.loadProducts()
            await self?.updateSubscriptionStatus()
            await self?.updateThemeStudioStatus()
        }
    }
    
    // MARK: - Product Loading
    
    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allProducts = try await Product.products(for: allProductIDs)
            
            // Separate subscriptions and one-time purchases
            products = allProducts.filter { subscriptionProductIDs.contains($0.id) }
            products.sort { $0.price < $1.price }
            
            oneTimeProducts = allProducts.filter { oneTimeProductIDs.contains($0.id) }
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    /// Purchase a subscription product
    /// - Parameter product: The product to purchase
    /// - Returns: Whether the purchase was successful
    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check verification
                let transaction = try Self.checkVerified(verification)
                
                // Update subscription status
                await updateSubscriptionStatus()
                
                // Finish the transaction
                await transaction.finish()
                
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Purchase a subscription by product ID
    func purchase(productID: SubscriptionProductID) async throws -> Bool {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            throw SubscriptionError.productNotFound
        }
        return try await purchase(product)
    }
    
    // MARK: - Restore Purchases
    
    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Subscription Status
    
    /// Update the current subscription status
    func updateSubscriptionStatus() async {
        var foundActiveSubscription = false
        var latestExpiration: Date?
        var activeProductId: String?
        var willRenew = false
        
        // Check for active subscriptions and one-time purchases
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)
                
                // Check if this is one of our subscription products
                if subscriptionProductIDs.contains(transaction.productID) {
                    foundActiveSubscription = true
                    activeProductId = transaction.productID
                    latestExpiration = transaction.expirationDate
                    willRenew = transaction.revocationDate == nil
                    
                    purchasedProductIDs.insert(transaction.productID)
                }
                
                // Check for one-time purchases (Theme Studio)
                if transaction.productID == OneTimePurchaseProductID.themeStudio.rawValue {
                    themeStudioPurchased = true
                    purchasedProductIDs.insert(transaction.productID)
                    cacheThemeStudioStatus()
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        if foundActiveSubscription {
            subscriptionStatus = SubscriptionStatus(
                tier: .premium,
                productId: activeProductId,
                expirationDate: latestExpiration,
                isActive: true,
                willRenew: willRenew
            )
        } else {
            subscriptionStatus = .free
            // Only remove subscription product IDs, keep one-time purchases
            for id in subscriptionProductIDs {
                purchasedProductIDs.remove(id)
            }
        }
        
        // Cache the status
        cacheSubscriptionStatus()
        
        // Notify via NotificationCenter to avoid circular dependency during init
        // AudioService will observe this notification
        NotificationCenter.default.post(
            name: .subscriptionStatusChanged,
            object: nil,
            userInfo: ["isPremium": subscriptionStatus.isValid]
        )
    }
    
    // MARK: - Theme Studio Purchase
    
    /// Update Theme Studio purchase status
    func updateThemeStudioStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)
                
                if transaction.productID == OneTimePurchaseProductID.themeStudio.rawValue {
                    themeStudioPurchased = true
                    cacheThemeStudioStatus()
                    return
                }
            } catch {
                print("Failed to verify Theme Studio transaction: \(error)")
            }
        }
    }
    
    /// Purchase Theme Studio (one-time purchase)
    @discardableResult
    func purchaseThemeStudio() async throws -> Bool {
        guard let product = themeStudioProduct else {
            throw SubscriptionError.productNotFound
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                
                // Update Theme Studio status
                themeStudioPurchased = true
                purchasedProductIDs.insert(transaction.productID)
                cacheThemeStudioStatus()
                
                await transaction.finish()
                
                isLoading = false
                
                // Notify of Theme Studio purchase
                NotificationCenter.default.post(
                    name: .themeStudioPurchased,
                    object: nil
                )
                
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Theme Studio product
    var themeStudioProduct: Product? {
        oneTimeProducts.first { $0.id == OneTimePurchaseProductID.themeStudio.rawValue }
    }
    
    /// Check if user can use Theme Studio (purchased or promo, but not in simulation mode)
    var canUseThemeStudio: Bool {
        if PromoCodeService.shared.isCustomerSimulationMode {
            return false
        }
        return themeStudioPurchased || PromoCodeService.shared.isPromoActivated
    }
    
    // MARK: - Transaction Listening
    
    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try SubscriptionManager.checkVerified(result)
                    
                    // Update subscription status on main actor
                    await self?.updateSubscriptionStatus()
                    
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    /// Verify a transaction result (nonisolated static to avoid actor isolation issues)
    private nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw SubscriptionError.verificationFailed(error)
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Caching
    
    /// Cache subscription status to UserDefaults
    private func cacheSubscriptionStatus() {
        if let encoded = try? JSONEncoder().encode(subscriptionStatus) {
            UserDefaults.standard.set(encoded, forKey: Keys.subscriptionStatus)
            UserDefaults.standard.set(Date(), forKey: Keys.lastVerificationDate)
        }
    }
    
    /// Load cached subscription status
    private func loadCachedSubscriptionStatus() {
        guard let data = UserDefaults.standard.data(forKey: Keys.subscriptionStatus),
              let cached = try? JSONDecoder().decode(SubscriptionStatus.self, from: data) else {
            subscriptionStatus = .free
            return
        }
        
        // Use cached status if it's still valid
        if cached.isValid {
            subscriptionStatus = cached
            // Don't update AudioService here to avoid initialization issues
            // It will be updated in updateSubscriptionStatus()
        } else {
            subscriptionStatus = .free
        }
    }
    
    /// Cache Theme Studio purchase status
    private func cacheThemeStudioStatus() {
        UserDefaults.standard.set(themeStudioPurchased, forKey: Keys.themeStudioPurchased)
    }
    
    /// Load cached Theme Studio status
    private func loadCachedThemeStudioStatus() {
        themeStudioPurchased = UserDefaults.standard.bool(forKey: Keys.themeStudioPurchased)
    }
    
    // MARK: - Promo Code Access
    
    /// Activate premium access via promo code
    func activatePromoAccess() {
        // Defer @Published property changes to avoid SwiftUI view update conflicts
        let newStatus = SubscriptionStatus(
            tier: .premium,
            productId: "promo_code",
            expirationDate: Date.distantFuture,
            isActive: true,
            willRenew: false
        )
        
        // Use async to break synchronous call chain during view body computation
        DispatchQueue.main.async { [weak self] in
            self?.subscriptionStatus = newStatus
            self?.cacheSubscriptionStatus()
            
            // Notify via NotificationCenter to avoid circular dependency
            NotificationCenter.default.post(
                name: .subscriptionStatusChanged,
                object: nil,
                userInfo: ["isPremium": true]
            )
        }
    }
    
    /// Deactivate promo access (for customer simulation mode)
    func deactivatePromoAccess() {
        let newStatus = SubscriptionStatus(
            tier: .free,
            productId: nil,
            expirationDate: nil,
            isActive: false,
            willRenew: false
        )
        
        // Use async to break synchronous call chain during view body computation
        DispatchQueue.main.async { [weak self] in
            self?.subscriptionStatus = newStatus
            
            // Notify via NotificationCenter
            NotificationCenter.default.post(
                name: .subscriptionStatusChanged,
                object: nil,
                userInfo: ["isPremium": false]
            )
        }
    }
    
    // MARK: - Helper Properties
    
    /// Check if user has an active premium subscription
    var isPremium: Bool {
        // Return false when in customer simulation mode
        if PromoCodeService.shared.isCustomerSimulationMode {
            return false
        }
        return subscriptionStatus.isValid || PromoCodeService.shared.isPromoActivated
    }
    
    /// Get the monthly product
    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProductID.monthlyPremium.rawValue }
    }
    
    /// Get the yearly product
    var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionProductID.yearlyPremium.rawValue }
    }
    
    /// Check if products are available
    var hasProducts: Bool {
        !products.isEmpty
    }
    
    /// Format price for display
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
    
    /// Calculate savings for yearly vs monthly
    var yearlySavingsPercentage: Int? {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else {
            return nil
        }
        
        let monthlyAnnualized = monthly.price * 12
        let savings = (1 - (yearly.price / monthlyAnnualized)) * 100
        return Int(Double(truncating: savings as NSDecimalNumber).rounded())
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed(Error)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        case .verificationFailed(let error):
            return "Verification failed: \(error.localizedDescription)"
        case .networkError:
            return "Network error occurred"
        }
    }
}
