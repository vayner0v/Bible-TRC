//
//  PaywallView.swift
//  Bible v1
//
//  Premium Subscription Paywall
//

import SwiftUI
import StoreKit

/// Full-screen paywall for promoting premium subscription
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Gradient background - theme aware
            LinearGradient(
                colors: [
                    themeManager.backgroundColor,
                    themeManager.accentColor.opacity(0.1),
                    themeManager.backgroundColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Header
                    VStack(spacing: 16) {
                        // Animated crown icon
                        ZStack {
                            Circle()
                                .fill(themeManager.accentGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: themeManager.accentColor.opacity(0.5), radius: 20)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        
                            Text("Unlock Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Experience scripture with natural AI voices")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Features list
                    VStack(spacing: 16) {
                        ForEach(PremiumFeatures.features, id: \.title) { feature in
                            PaywallFeatureRow(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Pricing options
                    VStack(spacing: 12) {
                        if subscriptionManager.hasProducts {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                PricingCard(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    savingsPercentage: product.id == SubscriptionProductID.yearlyPremium.rawValue ?
                                        subscriptionManager.yearlySavingsPercentage : nil
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
                            Text("Unable to load subscription options")
                                .foregroundColor(themeManager.secondaryTextColor)
                                .padding()
                            
                            Button("Retry") {
                                Task {
                                    await subscriptionManager.loadProducts()
                                }
                            }
                            .foregroundColor(themeManager.accentColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Subscribe button
                    VStack(spacing: 12) {
                        Button {
                            guard let product = selectedProduct else { return }
                            purchase(product)
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                selectedProduct != nil ? themeManager.accentGradient :
                                    LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: themeManager.accentColor.opacity(0.4), radius: 10, y: 5)
                        }
                        .disabled(selectedProduct == nil || isPurchasing)
                        
                        // Restore purchases
                        Button {
                            Task {
                                await subscriptionManager.restorePurchases()
                                if subscriptionManager.isPremium {
                                    HapticManager.shared.success()
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .disabled(subscriptionManager.isLoading)
                    }
                    .padding(.horizontal)
                    
                    // Legal text
                    VStack(spacing: 8) {
                        Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage your subscription in Settings.")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            Link("Privacy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                        }
                        .font(.caption2)
                        .foregroundColor(themeManager.accentColor)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Select yearly by default (better value)
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.yearlyProduct ?? subscriptionManager.monthlyProduct
            }
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
                    dismiss()
                }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Paywall Feature Row

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.2))
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

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let savingsPercentage: Int?
    let onTap: () -> Void
    @ObservedObject var themeManager = ThemeManager.shared
    
    private var isYearly: Bool {
        product.id == SubscriptionProductID.yearlyPremium.rawValue
    }
    
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
                                .font(.caption)
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
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(isYearly ? "per year" : "per month")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.dividerColor)
                    .padding(.leading, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.15) : themeManager.cardBackgroundColor)
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
    PaywallView()
}

