//
//  SubscriptionStepView.swift
//  Bible v1
//
//  Onboarding Subscription Screen with Promo Code
//

import SwiftUI
import StoreKit

struct SubscriptionStepView: View {
    let onComplete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var promoCodeService = PromoCodeService.shared
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showContent = false
    
    // Promo code
    @State private var logoTapCount = 0
    @State private var showPromoInput = false
    @State private var promoCode = ""
    @State private var promoError = false
    @State private var promoSuccess = false
    
    var body: some View {
        ZStack {
            // Background gradient matching theme
            LinearGradient(
                colors: [
                    themeManager.backgroundColor,
                    themeManager.accentColor.opacity(0.05),
                    themeManager.backgroundColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with tappable logo for promo code
                    VStack(spacing: 16) {
                        // Crown icon (tap 5 times to reveal promo)
                        Button {
                            handleLogoTap()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(themeManager.accentGradient)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: themeManager.accentColor.opacity(0.4), radius: 15)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("Unlock Premium")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Experience scripture like never before")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.top, 40)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)
                    
                    // Promo code input (hidden until revealed)
                    if showPromoInput {
                        PromoCodeInputView(
                            promoCode: $promoCode,
                            promoError: $promoError,
                            promoSuccess: $promoSuccess,
                            themeManager: themeManager,
                            onSubmit: { validatePromoCode() }
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                    
                    // Features
                    VStack(spacing: 12) {
                        ForEach(Array(PremiumFeatures.features.prefix(4))) { feature in
                            OnboardingFeatureRow(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description,
                                themeManager: themeManager
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    
                    // Pricing options
                    VStack(spacing: 12) {
                        if subscriptionManager.hasProducts {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                OnboardingPricingCard(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    isYearly: product.id == SubscriptionProductID.yearlyPremium.rawValue,
                                    savingsPercentage: product.id == SubscriptionProductID.yearlyPremium.rawValue ?
                                        subscriptionManager.yearlySavingsPercentage : nil,
                                    themeManager: themeManager
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedProduct = product
                                    }
                                    HapticManager.shared.lightImpact()
                                }
                            }
                        } else if subscriptionManager.isLoading {
                            ProgressView()
                                .tint(themeManager.accentColor)
                                .padding()
                        } else {
                            // Show placeholder pricing when products not loaded
                            Text("Subscription options loading...")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .padding()
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    
                    // Subscribe button
                    VStack(spacing: 16) {
                        Button {
                            if let product = selectedProduct {
                                purchase(product)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Subscribe Now")
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .buttonStyle(OnboardingPrimaryButtonStyle())
                        .disabled(selectedProduct == nil || isPurchasing)
                        .opacity(selectedProduct != nil ? 1 : 0.6)
                        
                        // Restore & Skip
                        HStack(spacing: 24) {
                            Button("Restore Purchases") {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                    if subscriptionManager.isPremium {
                                        HapticManager.shared.success()
                                        onComplete()
                                    }
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                            
                            Button("Maybe Later") {
                                onComplete()
                            }
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    
                    // Legal
                    Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                        .opacity(showContent ? 1 : 0)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Select yearly by default
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.yearlyProduct ?? subscriptionManager.monthlyProduct
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleLogoTap() {
        logoTapCount += 1
        
        if logoTapCount >= 5 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showPromoInput = true
            }
            HapticManager.shared.success()
            logoTapCount = 0
        } else {
            HapticManager.shared.lightImpact()
        }
    }
    
    private func validatePromoCode() {
        if promoCodeService.activatePromoCode(promoCode) {
            promoSuccess = true
            promoError = false
            HapticManager.shared.success()
            
            // Complete onboarding after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        } else {
            promoError = true
            promoSuccess = false
            HapticManager.shared.error()
        }
    }
    
    private func purchase(_ product: Product) {
        isPurchasing = true
        
        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                isPurchasing = false
                
                if success {
                    HapticManager.shared.success()
                    onComplete()
                }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Promo Code Input

struct PromoCodeInputView: View {
    @Binding var promoCode: String
    @Binding var promoError: Bool
    @Binding var promoSuccess: Bool
    let themeManager: ThemeManager
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .foregroundColor(themeManager.accentColor)
                
                TextField("Enter promo code", text: $promoCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(themeManager.textColor)
                
                Button(action: onSubmit) {
                    Image(systemName: promoSuccess ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(promoSuccess ? .green : themeManager.accentColor)
                }
                .disabled(promoCode.isEmpty || promoSuccess)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(promoError ? Color.red : (promoSuccess ? Color.green : Color.clear), lineWidth: 2)
            )
            
            if promoSuccess {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Developer Access Activated!")
                }
                .font(.caption)
                .foregroundColor(.green)
            } else if promoError {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Invalid promo code")
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Onboarding Feature Row

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(themeManager.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Onboarding Pricing Card

struct OnboardingPricingCard: View {
    let product: Product
    let isSelected: Bool
    let isYearly: Bool
    let savingsPercentage: Int?
    let themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Annual" : "Monthly")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        if let savings = savingsPercentage, savings > 0 {
                            Text("Save \(savings)%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    if isYearly {
                        Text("Best value")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(isYearly ? "per year" : "per month")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.dividerColor)
                    .padding(.leading, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SubscriptionStepView(onComplete: {})
}

