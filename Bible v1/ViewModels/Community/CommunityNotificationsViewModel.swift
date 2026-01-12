//
//  CommunityNotificationsViewModel.swift
//  Bible v1
//
//  Community Tab - Notifications View Model
//

import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
final class CommunityNotificationsViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var notifications: [CommunityNotification] = []
    @Published var selectedFilter: NotificationFilter = .all
    @Published var isLoading = false
    @Published var showSettings = false
    
    // MARK: - Computed Properties
    
    var filteredNotifications: [CommunityNotification] {
        guard selectedFilter != .all else { return notifications }
        return notifications.filter { $0.type.filter == selectedFilter }
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    func load() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = CommunityService.shared.currentProfile?.id else { return }
            
            let notifications: [CommunityNotification] = try await supabase
                .from("community_notifications")
                .select("*, actor:community_profiles!actor_id(id, display_name, username, avatar_url, is_verified, verification_type)")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            
            self.notifications = notifications
        } catch {
            print("❌ Notifications: Failed to load - \(error.localizedDescription)")
        }
    }
    
    func markAllAsRead() async {
        do {
            guard let userId = CommunityService.shared.currentProfile?.id else { return }
            
            try await supabase
                .from("community_notifications")
                .update(["is_read": true])
                .eq("user_id", value: userId.uuidString)
                .eq("is_read", value: false)
                .execute()
            
            // Update local state
            for index in notifications.indices {
                notifications[index].isRead = true
            }
        } catch {
            print("❌ Notifications: Failed to mark all as read - \(error.localizedDescription)")
        }
    }
    
    func markAsRead(_ notificationId: UUID) async {
        do {
            try await supabase
                .from("community_notifications")
                .update(["is_read": true])
                .eq("id", value: notificationId.uuidString)
                .execute()
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].isRead = true
            }
        } catch {
            print("❌ Notifications: Failed to mark as read - \(error.localizedDescription)")
        }
    }
    
    func handleNotificationTap(_ notification: CommunityNotification) {
        // Mark as read
        Task {
            await markAsRead(notification.id)
        }
        
        // Navigate to target
        // Navigation would be handled by the parent view via NavigationPath
    }
    
    func getDestination(for notification: CommunityNotification) -> CommunityDestination? {
        guard let targetId = notification.targetId else { return nil }
        
        switch notification.targetType {
        case "post":
            return .postDetail(targetId)
        case "profile":
            return .profile(targetId)
        case "group":
            return .group(targetId)
        case "live_room":
            return .liveRoom(targetId)
        default:
            return nil
        }
    }
}

