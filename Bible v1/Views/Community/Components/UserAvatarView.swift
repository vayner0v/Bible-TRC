//
//  UserAvatarView.swift
//  Bible v1
//
//  Community Tab - User Avatar Component
//

import SwiftUI

struct UserAvatarView: View {
    let profile: CommunityProfileSummary
    let size: CGFloat
    var showBadge: Bool = true
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar Image
            if let avatarUrl = profile.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initialsView
            }
            
            // Verification Badge
            if showBadge && profile.isVerified, let type = profile.verificationType {
                Image(systemName: type.icon)
                    .font(.system(size: size * 0.3))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(type.badgeColor)
                    .clipShape(Circle())
                    .offset(x: 2, y: 2)
            }
        }
    }
    
    private var initialsView: some View {
        Circle()
            .fill(themeManager.accentColor.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
            )
    }
    
    private var initials: String {
        let components = profile.displayName.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(profile.displayName.prefix(2)).uppercased()
    }
}

// MARK: - Avatar Group View

struct AvatarGroupView: View {
    let profiles: [CommunityProfileSummary]
    let maxVisible: Int
    let size: CGFloat
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(Array(profiles.prefix(maxVisible).enumerated()), id: \.element.id) { index, profile in
                UserAvatarView(profile: profile, size: size, showBadge: false)
                    .overlay(
                        Circle()
                            .stroke(themeManager.backgroundColor, lineWidth: 2)
                    )
                    .zIndex(Double(maxVisible - index))
            }
            
            // Overflow count
            if profiles.count > maxVisible {
                Circle()
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Text("+\(profiles.count - maxVisible)")
                            .font(.system(size: size * 0.35, weight: .semibold))
                            .foregroundColor(themeManager.textColor.opacity(0.7))
                    )
                    .overlay(
                        Circle()
                            .stroke(themeManager.backgroundColor, lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Follow Button

struct FollowButton: View {
    let isFollowing: Bool
    let isLoading: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(isFollowing ? themeManager.textColor : .white)
                } else {
                    Image(systemName: isFollowing ? "checkmark" : "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isFollowing ? themeManager.textColor : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isFollowing ? themeManager.backgroundColor.opacity(0.3) : themeManager.accentColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isFollowing ? themeManager.textColor.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Verification Badge

struct VerificationBadge: View {
    let type: VerificationType
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.system(size: size * 0.7))
            Text(type.displayName)
                .font(.system(size: size, weight: .medium))
        }
        .foregroundColor(type.badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(type.badgeColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        UserAvatarView(
            profile: CommunityProfileSummary(
                id: UUID(),
                displayName: "John Smith",
                isVerified: true,
                verificationType: .leader
            ),
            size: 60
        )
        
        AvatarGroupView(
            profiles: [
                CommunityProfileSummary(id: UUID(), displayName: "John Smith"),
                CommunityProfileSummary(id: UUID(), displayName: "Jane Doe"),
                CommunityProfileSummary(id: UUID(), displayName: "Bob Wilson"),
                CommunityProfileSummary(id: UUID(), displayName: "Alice Brown"),
                CommunityProfileSummary(id: UUID(), displayName: "Charlie Green")
            ],
            maxVisible: 3,
            size: 32
        )
        
        HStack {
            FollowButton(isFollowing: false, isLoading: false) { }
            FollowButton(isFollowing: true, isLoading: false) { }
        }
        
        VerificationBadge(type: .church, size: 12)
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}

