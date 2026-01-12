//
//  CommunityNotificationsView.swift
//  Bible v1
//
//  Community Tab - Notifications View
//

import SwiftUI

struct CommunityNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CommunityNotificationsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Tabs
                filterTabs
                
                // Content
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    loadingView
                } else if viewModel.notifications.isEmpty {
                    emptyView
                } else {
                    notificationsList
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.textColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Mark All as Read") {
                            Task { await viewModel.markAllAsRead() }
                        }
                        
                        Button("Notification Settings") {
                            viewModel.showSettings = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.textColor)
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $viewModel.showSettings) {
                NotificationSettingsView()
            }
        }
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NotificationFilter.allCases) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            if filter == .all && viewModel.unreadCount > 0 {
                                Text("\(viewModel.unreadCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                            
                            Text(filter.displayName)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(
                            viewModel.selectedFilter == filter
                                ? .white
                                : themeManager.textColor.opacity(0.7)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedFilter == filter
                                ? themeManager.accentColor
                                : themeManager.backgroundColor.opacity(0.3)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Notifications List
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredNotifications) { notification in
                    NotificationRow(notification: notification)
                        .onTapGesture {
                            viewModel.handleNotificationTap(notification)
                        }
                    
                    Divider()
                        .padding(.leading, 70)
                }
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(themeManager.accentColor)
            Spacer()
        }
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(themeManager.textColor.opacity(0.3))
            
            Text("No Notifications")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("When you get notifications, they'll appear here")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: CommunityNotification
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Actor Avatar
            ZStack(alignment: .bottomTrailing) {
                if let actor = notification.actor {
                    UserAvatarView(profile: actor, size: 44)
                } else {
                    systemAvatar
                }
                
                // Type Icon Badge
                notification.type.icon
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(notification.type.color)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Message
                Text(notification.message)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(3)
                
                // Time
                Text(notification.relativeTime)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.textColor.opacity(0.5))
                
                // Preview (if any)
                if let preview = notification.contentPreview {
                    Text(preview)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textColor.opacity(0.7))
                        .lineLimit(2)
                        .padding(10)
                        .background(themeManager.backgroundColor.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Unread Indicator
            if !notification.isRead {
                Circle()
                    .fill(themeManager.accentColor)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
        .background(notification.isRead ? Color.clear : themeManager.accentColor.opacity(0.05))
    }
    
    private var systemAvatar: some View {
        Circle()
            .fill(themeManager.accentColor.opacity(0.2))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.accentColor)
            )
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var settings = NotificationSettings.default
    
    var body: some View {
        NavigationStack {
            List {
                Section("Activity") {
                    Toggle("New Followers", isOn: $settings.newFollowers)
                    Toggle("Reactions", isOn: $settings.reactions)
                    Toggle("Comments", isOn: $settings.comments)
                    Toggle("Mentions", isOn: $settings.mentions)
                }
                
                Section("Prayer") {
                    Toggle("Prayer Requests", isOn: $settings.prayerRequests)
                    Toggle("Prayer Answered", isOn: $settings.prayerAnswered)
                    Toggle("Prayed for You", isOn: $settings.prayedForYou)
                }
                
                Section("Groups") {
                    Toggle("Group Posts", isOn: $settings.groupPosts)
                    Toggle("Group Events", isOn: $settings.groupEvents)
                    Toggle("Group Invites", isOn: $settings.groupInvites)
                }
                
                Section("Live") {
                    Toggle("Live Room Starting", isOn: $settings.liveRoomStarting)
                    Toggle("Live Room Invites", isOn: $settings.liveRoomInvites)
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Save settings
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum NotificationFilter: String, CaseIterable, Identifiable {
    case all, reactions, comments, follows, mentions, prayer, groups
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .reactions: return "Reactions"
        case .comments: return "Comments"
        case .follows: return "Follows"
        case .mentions: return "Mentions"
        case .prayer: return "Prayer"
        case .groups: return "Groups"
        }
    }
}

enum CommunityNotificationType: String, Codable {
    case reaction
    case comment
    case follow
    case mention
    case prayedFor
    case prayerAnswered
    case groupInvite
    case groupJoin
    case groupPost
    case groupEvent
    case liveRoomStarting
    case liveRoomInvite
    case system
    
    var icon: Image {
        switch self {
        case .reaction: return Image(systemName: "hand.thumbsup.fill")
        case .comment: return Image(systemName: "bubble.fill")
        case .follow: return Image(systemName: "person.fill.badge.plus")
        case .mention: return Image(systemName: "at")
        case .prayedFor: return Image(systemName: "hands.sparkles.fill")
        case .prayerAnswered: return Image(systemName: "checkmark.seal.fill")
        case .groupInvite: return Image(systemName: "person.3.fill")
        case .groupJoin: return Image(systemName: "person.badge.plus")
        case .groupPost: return Image(systemName: "doc.text.fill")
        case .groupEvent: return Image(systemName: "calendar")
        case .liveRoomStarting: return Image(systemName: "dot.radiowaves.left.and.right")
        case .liveRoomInvite: return Image(systemName: "antenna.radiowaves.left.and.right")
        case .system: return Image(systemName: "bell.fill")
        }
    }
    
    var color: Color {
        switch self {
        case .reaction: return .orange
        case .comment: return .blue
        case .follow: return .green
        case .mention: return .purple
        case .prayedFor, .prayerAnswered: return .pink
        case .groupInvite, .groupJoin, .groupPost, .groupEvent: return .cyan
        case .liveRoomStarting, .liveRoomInvite: return .red
        case .system: return .gray
        }
    }
    
    var filter: NotificationFilter {
        switch self {
        case .reaction: return .reactions
        case .comment: return .comments
        case .follow: return .follows
        case .mention: return .mentions
        case .prayedFor, .prayerAnswered: return .prayer
        case .groupInvite, .groupJoin, .groupPost, .groupEvent: return .groups
        default: return .all
        }
    }
}

struct CommunityNotification: Identifiable, Codable {
    let id: UUID
    let type: CommunityNotificationType
    let actorId: UUID?
    let targetType: String?
    let targetId: UUID?
    let message: String
    let contentPreview: String?
    var isRead: Bool
    let createdAt: Date
    
    // Joined data
    var actor: CommunityProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id, type
        case actorId = "actor_id"
        case targetType = "target_type"
        case targetId = "target_id"
        case message
        case contentPreview = "content_preview"
        case isRead = "is_read"
        case createdAt = "created_at"
        case actor
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

struct NotificationSettings {
    var newFollowers = true
    var reactions = true
    var comments = true
    var mentions = true
    var prayerRequests = true
    var prayerAnswered = true
    var prayedForYou = true
    var groupPosts = true
    var groupEvents = true
    var groupInvites = true
    var liveRoomStarting = true
    var liveRoomInvites = true
    
    static let `default` = NotificationSettings()
}

#Preview {
    CommunityNotificationsView()
        .environmentObject(ThemeManager.shared)
}

