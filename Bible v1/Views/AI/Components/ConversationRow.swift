//
//  ConversationRow.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Sidebar Conversation Row
//

import SwiftUI

/// Individual conversation row for the sidebar
struct ConversationRow: View {
    let conversation: ChatConversation
    let isSelected: Bool
    let onTap: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Mode icon
                Circle()
                    .fill(conversation.currentMode.accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: conversation.currentMode.icon)
                            .font(.system(size: 14))
                            .foregroundColor(conversation.currentMode.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(conversation.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    Text(conversation.previewText)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(conversation.formattedDate)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("\(conversation.messageCount)")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected 
                          ? themeManager.accentColor.opacity(0.15) 
                          : (isHovered ? themeManager.cardBackgroundColor : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? themeManager.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button {
                onArchive()
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

/// Compact conversation row for smaller displays
struct ConversationRowCompact: View {
    let conversation: ChatConversation
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: conversation.currentMode.icon)
                    .font(.caption)
                    .foregroundColor(conversation.currentMode.accentColor)
                
                Text(conversation.title)
                    .font(.caption)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        ConversationRow(
            conversation: ChatConversation(
                title: "What does John 3:16 mean?",
                currentMode: .study
            ),
            isSelected: true,
            onTap: {},
            onArchive: {},
            onDelete: {}
        )
        
        ConversationRow(
            conversation: ChatConversation(
                title: "Prayer for peace",
                currentMode: .prayer
            ),
            isSelected: false,
            onTap: {},
            onArchive: {},
            onDelete: {}
        )
        
        ConversationRow(
            conversation: ChatConversation(
                title: "Help me understand God's love",
                currentMode: .devotional
            ),
            isSelected: false,
            onTap: {},
            onArchive: {},
            onDelete: {}
        )
    }
    .padding()
}




