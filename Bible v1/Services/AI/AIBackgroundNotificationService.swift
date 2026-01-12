//
//  AIBackgroundNotificationService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Background Processing Notifications
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

/// Service for managing background AI processing and notifications
@MainActor
class AIBackgroundNotificationService: ObservableObject {
    static let shared = AIBackgroundNotificationService()
    
    // MARK: - Published State
    
    @Published var hasPendingResponse: Bool = false
    @Published var pendingConversationId: UUID?
    @Published var pendingMessagePreview: String = ""
    @Published var isProcessingInBackground: Bool = false
    @Published var showNotificationBanner: Bool = false
    @Published var notificationPermissionGranted: Bool = false
    
    // MARK: - Notification Data
    
    struct PendingNotification: Identifiable {
        let id: UUID
        let conversationId: UUID
        let title: String
        let preview: String
        let timestamp: Date
    }
    
    @Published var pendingNotifications: [PendingNotification] = []
    
    // MARK: - Notification Center
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    init() {
        // Check current notification permission status
        Task {
            await checkNotificationPermission()
        }
    }
    
    // MARK: - Permission Management
    
    /// Check current notification permission status
    private func checkNotificationPermission() async {
        let settings = await notificationCenter.notificationSettings()
        notificationPermissionGranted = settings.authorizationStatus == .authorized
    }
    
    /// Request notification permission
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            notificationPermissionGranted = granted
            return granted
        } catch {
            print("AIBackgroundNotificationService: Failed to request notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Background Processing
    
    /// Mark that we're starting a background AI request
    func startBackgroundProcessing(conversationId: UUID) {
        isProcessingInBackground = true
        pendingConversationId = conversationId
        
        // Request notification permission if not already granted
        if !notificationPermissionGranted {
            Task {
                _ = await requestNotificationPermission()
            }
        }
    }
    
    /// Mark that the background AI request completed
    func completeBackgroundProcessing(
        conversationId: UUID,
        title: String,
        preview: String
    ) {
        isProcessingInBackground = false
        
        let truncatedPreview = String(preview.prefix(100)) + (preview.count > 100 ? "..." : "")
        let displayTitle = title.isEmpty ? "TRC AI responded" : title
        
        let notification = PendingNotification(
            id: UUID(),
            conversationId: conversationId,
            title: displayTitle,
            preview: truncatedPreview,
            timestamp: Date()
        )
        
        pendingNotifications.insert(notification, at: 0)
        hasPendingResponse = true
        pendingMessagePreview = preview
        
        // Show banner if app is in foreground
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showNotificationBanner = true
        }
        
        // Play haptic
        HapticManager.shared.success()
        
        // Send local notification if app is in background
        sendLocalNotification(
            conversationId: conversationId,
            title: displayTitle,
            preview: truncatedPreview
        )
        
        // Auto-hide banner after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            withAnimation {
                self?.showNotificationBanner = false
            }
        }
    }
    
    // MARK: - Local Notifications
    
    /// Send a local notification when AI response is ready
    private func sendLocalNotification(
        conversationId: UUID,
        title: String,
        preview: String
    ) {
        // Only send if app is in background
        guard UIApplication.shared.applicationState != .active else { return }
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "TRC AI"
        content.subtitle = title
        content.body = preview
        content.sound = .default
        content.categoryIdentifier = "AI_RESPONSE"
        content.userInfo = [
            "conversationId": conversationId.uuidString,
            "type": "ai_response"
        ]
        
        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "ai_response_\(conversationId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        Task {
            do {
                try await notificationCenter.add(request)
                print("AIBackgroundNotificationService: Local notification scheduled")
            } catch {
                print("AIBackgroundNotificationService: Failed to schedule notification: \(error)")
            }
        }
    }
    
    /// Remove pending notification for a conversation
    func removePendingLocalNotification(for conversationId: UUID) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["ai_response_\(conversationId.uuidString)"]
        )
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: ["ai_response_\(conversationId.uuidString)"]
        )
    }
    
    /// Clear the pending notification for a conversation
    func clearNotification(for conversationId: UUID) {
        pendingNotifications.removeAll { $0.conversationId == conversationId }
        removePendingLocalNotification(for: conversationId)
        
        if pendingNotifications.isEmpty {
            hasPendingResponse = false
            showNotificationBanner = false
        }
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        // Remove all local notifications
        for notification in pendingNotifications {
            removePendingLocalNotification(for: notification.conversationId)
        }
        
        pendingNotifications.removeAll()
        hasPendingResponse = false
        showNotificationBanner = false
    }
    
    /// Cancel background processing
    func cancelBackgroundProcessing() {
        isProcessingInBackground = false
        if let conversationId = pendingConversationId {
            removePendingLocalNotification(for: conversationId)
        }
        pendingConversationId = nil
    }
    
    // MARK: - Notification Categories
    
    /// Register notification categories for actionable notifications
    func registerNotificationCategories() {
        let openAction = UNNotificationAction(
            identifier: "OPEN_CONVERSATION",
            title: "View Response",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        
        let aiResponseCategory = UNNotificationCategory(
            identifier: "AI_RESPONSE",
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([aiResponseCategory])
    }
}

// MARK: - Notification Banner View

/// Floating banner that appears when AI response is ready
struct AINotificationBannerView: View {
    @ObservedObject var notificationService = AIBackgroundNotificationService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    let onTap: (UUID) -> Void
    
    var body: some View {
        if notificationService.showNotificationBanner,
           let notification = notificationService.pendingNotifications.first {
            VStack {
                HStack(spacing: 12) {
                    // AI Icon with animation
                    ZStack {
                        Circle()
                            .fill(themeManager.accentColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TRC AI responded")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(themeManager.textColor)
                        
                        Text(notification.preview)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.cardBackgroundColor)
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                .onTapGesture {
                    notificationService.clearNotification(for: notification.conversationId)
                    onTap(notification.conversationId)
                }
                
                Spacer()
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - Processing Indicator View

/// Small floating indicator showing AI is processing in background
struct AIBackgroundProcessingIndicator: View {
    @ObservedObject var notificationService = AIBackgroundNotificationService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var isAnimating = false
    
    var body: some View {
        if notificationService.isProcessingInBackground {
            HStack(spacing: 8) {
                // Animated dots
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 6, height: 6)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                
                Text("TRC AI is thinking...")
                    .font(.caption)
                    .foregroundColor(themeManager.textColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            )
            .onAppear {
                isAnimating = true
            }
        }
    }
}

