//
//  VerseActionSheet.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// Enhanced action sheet for verse interactions
struct VerseActionSheet: View {
    let verse: Verse
    let reference: VerseReference
    let currentHighlight: Highlight?
    let isFavorite: Bool
    let onAction: (VerseAction) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showCopiedFeedback = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Verse preview card
                        VersePreviewCard(
                            verse: verse,
                            reference: reference,
                            themeManager: themeManager
                        )
                        
                        // Quick actions
                        QuickActionsSection(
                            isFavorite: isFavorite,
                            currentHighlight: currentHighlight,
                            showCopiedFeedback: $showCopiedFeedback,
                            themeManager: themeManager,
                            onAction: handleAction
                        )
                        
                        // Highlight colors
                        HighlightSection(
                            currentHighlight: currentHighlight,
                            themeManager: themeManager,
                            onSelectColor: { color in
                                handleAction(.highlight(color))
                            },
                            onRemove: {
                                handleAction(.removeHighlight)
                            }
                        )
                        
                        // More options
                        MoreOptionsSection(
                            themeManager: themeManager,
                            onAction: handleAction
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Verse Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .overlay {
                // Copied feedback toast
                if showCopiedFeedback {
                    VStack {
                        Spacer()
                        CopiedToast(themeManager: themeManager)
                            .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCopiedFeedback)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func handleAction(_ action: VerseAction) {
        switch action {
        case .copy:
            showCopiedFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCopiedFeedback = false
            }
            onAction(action)
        case .favorite, .highlight, .removeHighlight:
            onAction(action)
        case .addNote, .share:
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onAction(action)
            }
        }
    }
}

// MARK: - Verse Preview Card

struct VersePreviewCard: View {
    let verse: Verse
    let reference: VerseReference
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reference header
            HStack {
                Text(reference.shortReference)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(themeManager.accentColor.opacity(0.15))
                    .cornerRadius(6)
                
                Spacer()
                
                Text(reference.translationId)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Verse text
            Text(verse.text)
                .font(themeManager.verseFont)
                .foregroundColor(themeManager.textColor)
                .lineSpacing(themeManager.lineSpacing)
        }
        .padding(20)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    let isFavorite: Bool
    let currentHighlight: Highlight?
    @Binding var showCopiedFeedback: Bool
    let themeManager: ThemeManager
    let onAction: (VerseAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.leading, 4)
            
            HStack(spacing: 12) {
                // Favorite
                QuickActionButton(
                    icon: isFavorite ? "heart.fill" : "heart",
                    title: isFavorite ? "Saved" : "Save",
                    iconColor: isFavorite ? .red : themeManager.textColor,
                    isActive: isFavorite,
                    themeManager: themeManager
                ) {
                    onAction(.favorite)
                }
                
                // Copy
                QuickActionButton(
                    icon: "doc.on.doc",
                    title: "Copy",
                    iconColor: themeManager.textColor,
                    isActive: false,
                    themeManager: themeManager
                ) {
                    onAction(.copy)
                }
                
                // Share
                QuickActionButton(
                    icon: "square.and.arrow.up",
                    title: "Share",
                    iconColor: themeManager.textColor,
                    isActive: false,
                    themeManager: themeManager
                ) {
                    onAction(.share)
                }
                
                // Note
                QuickActionButton(
                    icon: "note.text",
                    title: "Note",
                    iconColor: .orange,
                    isActive: false,
                    themeManager: themeManager
                ) {
                    onAction(.addNote)
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let iconColor: Color
    let isActive: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? iconColor.opacity(0.15) : themeManager.cardBackgroundColor)
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.textColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Highlight Section

struct HighlightSection: View {
    let currentHighlight: Highlight?
    let themeManager: ThemeManager
    let onSelectColor: (HighlightColor) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Highlight")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                if currentHighlight != nil {
                    Button(action: onRemove) {
                        Text("Remove")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 16) {
                ForEach(HighlightColor.allCases) { color in
                    HighlightColorButton(
                        color: color,
                        isSelected: currentHighlight?.color == color,
                        themeManager: themeManager
                    ) {
                        onSelectColor(color)
                    }
                }
            }
            .padding(16)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
        }
    }
}

struct HighlightColorButton: View {
    let color: HighlightColor
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(isSelected ? themeManager.textColor : Color.clear, lineWidth: 3)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(color == .yellow ? .black : .white)
                    }
                }
                
                Text(color.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - More Options Section

struct MoreOptionsSection: View {
    let themeManager: ThemeManager
    let onAction: (VerseAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                MoreOptionRow(
                    icon: "speaker.wave.2",
                    title: "Listen to verse",
                    subtitle: "Have this verse read aloud",
                    themeManager: themeManager
                ) {
                    // Audio action would go here
                }
                
                Divider()
                    .padding(.leading, 52)
                
                MoreOptionRow(
                    icon: "books.vertical",
                    title: "Compare translations",
                    subtitle: "See this verse in other versions",
                    themeManager: themeManager
                ) {
                    // Compare action would go here
                }
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
        }
    }
}

struct MoreOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Copied Toast

struct CopiedToast: View {
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text("Copied to clipboard")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
        )
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VerseActionSheet(
        verse: Verse(verse: 1, text: "In the beginning God created the heaven and the earth."),
        reference: VerseReference(
            translationId: "BSB",
            bookId: "GEN",
            bookName: "Genesis",
            chapter: 1,
            verse: 1,
            text: "In the beginning God created the heaven and the earth."
        ),
        currentHighlight: nil,
        isFavorite: false,
        onAction: { _ in }
    )
}
