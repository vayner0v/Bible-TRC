//
//  SubscriptionView.swift
//  Bible v1
//
//  Subscription Management View
//

import SwiftUI
import StoreKit

/// View for managing subscription status and settings
struct SubscriptionView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var usageTrackingService = UsageTrackingService.shared
    
    @State private var showingPaywall = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Current subscription status
                    subscriptionStatusCard
                    
                    // Usage statistics
                    if subscriptionManager.isPremium {
                        usageStatsCard
                    }
                    
                    // Actions
                    actionsSection
                    
                    // Info
                    infoSection
                }
                .padding()
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreMessage)
        }
    }
    
    // MARK: - Subscription Status Card
    
    private var subscriptionStatusCard: some View {
        VStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(
                        subscriptionManager.isPremium ?
                            themeManager.accentGradient :
                            LinearGradient(colors: [themeManager.cardBackgroundColor, themeManager.cardBackgroundColor], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(subscriptionManager.isPremium ? .white : themeManager.secondaryTextColor)
            }
            
            // Status text
            VStack(spacing: 8) {
                Text(subscriptionManager.isPremium ? "Premium Active" : "Free Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                if subscriptionManager.isPremium {
                    if let expDate = subscriptionManager.subscriptionStatus.formattedExpirationDate {
                        Text("Renews on \(expDate)")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Unlimited TRC AI")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("AI Voices Enabled")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    Text("Upgrade to unlock TRC AI & AI voices")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Upgrade button (if not premium)
            if !subscriptionManager.isPremium {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Premium")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.accentGradient)
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Usage Stats Card
    
    private var usageStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage This Period")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            // Daily usage
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                    Spacer()
                    Text(usageTrackingService.dailyUsageDisplay)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                }
                
                ProgressView(value: min(usageTrackingService.dailyUsagePercentage, 100), total: 100)
                    .tint(usageTrackingService.isDailyLimitReached ? .red : themeManager.accentColor)
                
                Text("~\(usageTrackingService.estimatedChaptersRemainingToday) chapters remaining")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Divider()
                .background(themeManager.dividerColor)
            
            // Monthly usage
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("This Month")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                    Spacer()
                    Text(usageTrackingService.monthlyUsageDisplay)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                }
                
                ProgressView(value: min(usageTrackingService.monthlyUsagePercentage, 100), total: 100)
                    .tint(usageTrackingService.isMonthlyLimitReached ? .red : themeManager.accentColor)
                
                Text("~\(usageTrackingService.estimatedChaptersRemainingMonth) chapters remaining")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Restore purchases
            Button {
                Task {
                    await subscriptionManager.restorePurchases()
                    restoreMessage = subscriptionManager.isPremium ?
                        "Your subscription has been restored!" :
                        "No active subscription found."
                    showingRestoreAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(themeManager.accentColor)
                    Text("Restore Purchases")
                        .foregroundColor(themeManager.textColor)
                    Spacer()
                    if subscriptionManager.isLoading {
                        ProgressView()
                    }
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
            .disabled(subscriptionManager.isLoading)
            
            // Manage subscription (opens App Store)
            if subscriptionManager.isPremium {
                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(themeManager.accentColor)
                        Text("Manage Subscription")
                            .foregroundColor(themeManager.textColor)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Premium")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(PremiumFeatures.features.prefix(4))) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: feature.icon)
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.textColor)
                            Text(feature.description)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            
            // Legal links
            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Link("Privacy Policy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}

