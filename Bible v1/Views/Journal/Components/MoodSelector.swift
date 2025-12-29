//
//  MoodSelector.swift
//  Bible v1
//
//  Spiritual Journal - Mood Selection Components
//

import SwiftUI

/// Full-screen mood picker sheet
struct MoodPickerSheet: View {
    @Binding var selectedMood: JournalMood?
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("How are you feeling?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textColor)
                            
                            Text("Select your current mood")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.top)
                        
                        // Mood grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(JournalMood.allCases) { mood in
                                MoodCard(
                                    mood: mood,
                                    isSelected: selectedMood == mood,
                                    themeManager: themeManager
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedMood == mood {
                                            selectedMood = nil
                                        } else {
                                            selectedMood = mood
                                        }
                                    }
                                    HapticManager.shared.lightImpact()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Selected mood verse suggestion
                        if let mood = selectedMood {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Scripture for you")
                                    .font(.headline)
                                    .foregroundColor(themeManager.textColor)
                                
                                Text(mood.suggestedVerse)
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundColor(themeManager.textColor)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(mood.lightColor)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        // Skip button
                        Button {
                            selectedMood = nil
                            dismiss()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Individual mood card in the grid
struct MoodCard: View {
    let mood: JournalMood
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? mood.color : mood.lightColor)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: mood.icon)
                        .font(.title)
                        .foregroundColor(isSelected ? .white : mood.color)
                }
                
                // Name
                Text(mood.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(themeManager.textColor)
                
                // Emoji
                Text(mood.emoji)
                    .font(.title3)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: isSelected ? mood.color.opacity(0.3) : .clear, radius: 8, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

/// Compact mood selector for inline use
struct MoodSelectorCompact: View {
    @Binding var selectedMood: JournalMood?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(JournalMood.allCases) { mood in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedMood == mood {
                                selectedMood = nil
                            } else {
                                selectedMood = mood
                            }
                        }
                        HapticManager.shared.lightImpact()
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(selectedMood == mood ? mood.color : mood.lightColor)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: mood.icon)
                                    .font(.body)
                                    .foregroundColor(selectedMood == mood ? .white : mood.color)
                            }
                            
                            Text(mood.displayName)
                                .font(.caption2)
                                .foregroundColor(
                                    selectedMood == mood ? mood.color : themeManager.secondaryTextColor
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Mood indicator badge for display
struct MoodBadge: View {
    let mood: JournalMood
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var iconSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var textSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            case .large: return EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mood.icon)
                .font(size.iconSize)
            Text(mood.displayName)
                .font(size.textSize)
        }
        .foregroundColor(mood.color)
        .padding(size.padding)
        .background(mood.lightColor)
        .cornerRadius(20)
    }
}

#Preview("Mood Picker Sheet") {
    MoodPickerSheet(selectedMood: .constant(.peaceful))
}

#Preview("Mood Selector Compact") {
    MoodSelectorCompact(selectedMood: .constant(.grateful))
}

#Preview("Mood Badge") {
    VStack(spacing: 16) {
        MoodBadge(mood: .joyful, size: .small)
        MoodBadge(mood: .peaceful, size: .medium)
        MoodBadge(mood: .reflective, size: .large)
    }
}

