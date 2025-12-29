//
//  PromoCodeService.swift
//  Bible v1
//
//  Promo Code Validation and Storage
//

import Foundation
import Combine

/// Service for managing promo codes and developer access
@MainActor
final class PromoCodeService: ObservableObject {
    static let shared = PromoCodeService()
    
    // MARK: - Valid Promo Codes
    
    /// List of valid promo codes (case-insensitive)
    private let validPromoCodes: Set<String> = [
        "vaynerov"  // Developer access code
    ]
    
    // MARK: - Published Properties
    
    @Published private(set) var isPromoActivated: Bool = false
    @Published private(set) var activatedCode: String?
    @Published var showPromoInput: Bool = false
    
    // MARK: - Private Properties
    
    private enum Keys {
        static let promoActivated = "promo_code_activated"
        static let activatedCode = "promo_activated_code"
        static let activationDate = "promo_activation_date"
    }
    
    // MARK: - Initialization
    
    init() {
        loadPromoStatus()
    }
    
    // MARK: - Promo Code Validation
    
    /// Validate and activate a promo code
    /// - Parameter code: The promo code to validate
    /// - Returns: Whether the code was valid and activated
    @discardableResult
    func activatePromoCode(_ code: String) -> Bool {
        let normalizedCode = code.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard validPromoCodes.contains(normalizedCode) else {
            return false
        }
        
        // Activate the promo
        isPromoActivated = true
        activatedCode = code
        
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: Keys.promoActivated)
        UserDefaults.standard.set(code, forKey: Keys.activatedCode)
        UserDefaults.standard.set(Date(), forKey: Keys.activationDate)
        
        // Update subscription status
        SubscriptionManager.shared.activatePromoAccess()
        AudioService.shared.updateSubscriptionStatus(isPremium: true)
        
        return true
    }
    
    /// Deactivate promo code (for testing)
    func deactivatePromoCode() {
        isPromoActivated = false
        activatedCode = nil
        
        UserDefaults.standard.removeObject(forKey: Keys.promoActivated)
        UserDefaults.standard.removeObject(forKey: Keys.activatedCode)
        UserDefaults.standard.removeObject(forKey: Keys.activationDate)
        
        // Update subscription status
        Task {
            await SubscriptionManager.shared.updateSubscriptionStatus()
        }
    }
    
    /// Check if a code is valid without activating
    func isValidCode(_ code: String) -> Bool {
        let normalizedCode = code.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return validPromoCodes.contains(normalizedCode)
    }
    
    // MARK: - Status Loading
    
    private func loadPromoStatus() {
        isPromoActivated = UserDefaults.standard.bool(forKey: Keys.promoActivated)
        activatedCode = UserDefaults.standard.string(forKey: Keys.activatedCode)
        
        // If promo is activated, ensure subscription status reflects it
        if isPromoActivated {
            SubscriptionManager.shared.activatePromoAccess()
            AudioService.shared.updateSubscriptionStatus(isPremium: true)
        }
    }
    
    // MARK: - Helper Properties
    
    /// Get the activation date if promo is active
    var activationDate: Date? {
        UserDefaults.standard.object(forKey: Keys.activationDate) as? Date
    }
    
    /// Display text for settings
    var statusDisplayText: String {
        if isPromoActivated {
            return "Developer Access Active"
        }
        return "No promo code active"
    }
}

