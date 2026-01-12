//
//  GroupCardView.swift
//  Bible v1
//
//  Community Tab - Group Card Component
//

import SwiftUI

struct GroupCardView: View {
    let group: CommunityGroup
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 14) {
            // Group Avatar
            groupAvatar
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    if group.isVerifiedChurch {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 6) {
                    Image(systemName: group.type.icon)
                        .font(.system(size: 11))
                        .foregroundColor(group.type.color)
                    
                    Text(group.type.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(themeManager.textColor.opacity(0.4))
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                    Text("\(group.memberCount)")
                        .font(.system(size: 12))
                }
                .foregroundColor(themeManager.textColor.opacity(0.6))
                
                if let description = group.description {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textColor.opacity(0.7))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.textColor.opacity(0.3))
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var groupAvatar: some View {
        Group {
            if let avatarUrl = group.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var defaultAvatar: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(group.type.color.opacity(0.2))
            .overlay(
                Image(systemName: group.type.icon)
                    .font(.system(size: 22))
                    .foregroundColor(group.type.color)
            )
    }
}

// MARK: - Compact Group Card

struct GroupCardCompact: View {
    let group: GroupSummary
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 10) {
            // Avatar
            groupAvatar
            
            // Info
            VStack(spacing: 2) {
                Text(group.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("\(group.memberCount) members")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.textColor.opacity(0.5))
            }
            
            // Join Button
            if !group.isMember {
                Button {
                    // Join group
                } label: {
                    Text("Join")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(themeManager.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(width: 120)
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var groupAvatar: some View {
        Group {
            if let avatarUrl = group.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var defaultAvatar: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(group.type.color.opacity(0.2))
            .overlay(
                Image(systemName: group.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(group.type.color)
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        GroupCardView(group: CommunityGroup(
            name: "Morning Prayer Warriors",
            description: "Join us every morning for prayer and devotion",
            type: .study,
            memberCount: 156
        ))
        
        HStack(spacing: 12) {
            GroupCardCompact(group: GroupSummary(
                id: UUID(),
                name: "Bible Study Group",
                type: .study,
                privacy: .public,
                avatarUrl: nil,
                memberCount: 45,
                isMember: false
            ))
            
            GroupCardCompact(group: GroupSummary(
                id: UUID(),
                name: "First Church",
                type: .church,
                privacy: .public,
                avatarUrl: nil,
                memberCount: 234,
                isMember: true
            ))
        }
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}

