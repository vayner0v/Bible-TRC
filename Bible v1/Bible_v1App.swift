//
//  Bible_v1App.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI
import UserNotifications

@main
struct Bible_v1App: App {
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var privacyManager = PrivacyManager.shared
    @AppStorage("hasSeenSplash") private var hasSeenSplash = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingSplash = true
    
    // Reference notification service to ensure it's initialized early
    private let notificationService = NotificationService.shared
    
    init() {
        // Configure app appearance
        configureAppearance()
        
        // Initialize notification system - MUST be done early in app lifecycle
        // This sets up notification categories for actions (Pray Now, Snooze, Dismiss)
        // and ensures the delegate is assigned before any notifications arrive
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content (only visible after onboarding)
                if hasCompletedOnboarding {
                    HomeView()
                        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                        .accessibilityEnvironment()
                        .opacity(showingSplash ? 0 : 1)
                }
                
                // Onboarding flow (shown after splash if not completed)
                if !showingSplash && !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                        .accessibilityEnvironment()
                        .transition(.opacity)
                }
                
                // Splash screen overlay
                if showingSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showingSplash = false
                        }
                    }
                    .transition(.opacity)
                }
                
                // Lock screen overlay (shown when app is locked)
                if privacyManager.isLocked && !showingSplash {
                    LockScreenView()
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .privacyBlur()
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            .onAppear {
                // Refresh pending notifications when app becomes active
                notificationService.refreshPendingNotifications()
                
                // Sync AudioService subscription status after all singletons are initialized
                // This deferred call prevents circular dependency crashes between
                // AudioService, SubscriptionManager, and UsageTrackingService
                syncServicesAfterLaunch()
            }
        }
    }
    
    /// Configure notification system on app launch
    private func setupNotifications() {
        // Set up notification categories and actions
        // This enables the action buttons (Pray Now, Snooze, Dismiss) on notifications
        notificationService.setupNotificationCategories()
        
        // Ensure the notification center delegate is set
        // This is already done in NotificationService.init() but we ensure it's done early
        UNUserNotificationCenter.current().delegate = notificationService
        
        // Refresh list of pending notifications
        notificationService.refreshPendingNotifications()
    }
    
    /// Sync services after app launch to avoid circular dependency during initialization
    /// This is called after all singletons have finished their init() methods
    private func syncServicesAfterLaunch() {
        // 1. Sync AudioService with current subscription status
        // This must be done after SubscriptionManager is fully initialized
        AudioService.shared.syncSubscriptionStatus()
        
        // 2. Check and apply promo code status
        if PromoCodeService.shared.isPromoActivated {
            AudioService.shared.updateSubscriptionStatus(isPremium: true)
        }
        
        // 3. Initialize SettingsStore observers to ensure UI sync
        _ = SettingsStore.shared
        
        // 4. Schedule initial notifications if enabled
        if notificationService.preferences.isEnabled {
            Task {
                let authorized = await notificationService.requestAuthorization()
                if authorized {
                    // Trigger notification scheduling
                    notificationService.savePreferences()
                }
            }
        }
        
        // 5. Sync AccessibilityManager with SettingsStore
        _ = AccessibilityManager.shared
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
