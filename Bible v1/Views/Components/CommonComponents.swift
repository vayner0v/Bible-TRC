//
//  CommonComponents.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

// MARK: - Verse Action Types

enum VerseAction {
    case favorite
    case highlight(HighlightColor)
    case removeHighlight
    case addNote
    case copy
    case share
}

// MARK: - Themed Toolbar Button

struct ThemedToolbarButton: View {
    let icon: String
    let title: String?
    let themeManager: ThemeManager
    let action: () -> Void
    
    init(icon: String, title: String? = nil, themeManager: ThemeManager = ThemeManager.shared, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.themeManager = themeManager
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            if let title = title {
                Label(title, systemImage: icon)
            } else {
                Image(systemName: icon)
            }
        }
        .foregroundColor(themeManager.accentColor)
    }
}

// MARK: - Card View

struct CardView<Content: View>: View {
    let themeManager: ThemeManager
    @ViewBuilder let content: Content
    
    init(themeManager: ThemeManager = ThemeManager.shared, @ViewBuilder content: () -> Content) {
        self.themeManager = themeManager
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Pill Tag

struct PillTag: View {
    let text: String
    let color: Color
    let themeManager: ThemeManager
    
    init(_ text: String, color: Color = .blue, themeManager: ThemeManager = ThemeManager.shared) {
        self.text = text
        self.color = color
        self.themeManager = themeManager
    }
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        LoadingView("Loading scripture...")
        
        SettingsSection(title: "Test Section", themeManager: ThemeManager.shared) {
            Text("Content goes here")
        }
        
        HStack {
            ForEach(ReadingFont.allCases.prefix(3)) { font in
                FontButton(font: font, isSelected: font == .serif, themeManager: ThemeManager.shared) {}
            }
        }
    }
    .padding()
}

