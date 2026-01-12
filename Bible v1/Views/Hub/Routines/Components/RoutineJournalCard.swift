//
//  RoutineJournalCard.swift
//  Bible v1
//
//  Paper-like card component for the journaling aesthetic
//

import SwiftUI

// MARK: - Journal Card Style

/// A paper-like card with warm journaling aesthetics
struct RoutineJournalCard<Content: View>: View {
    let content: Content
    var mode: RoutineMode = .morning
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 16
    var showPaperTexture: Bool = true
    var elevated: Bool = false
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    init(
        mode: RoutineMode = .morning,
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 16,
        showPaperTexture: Bool = true,
        elevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.mode = mode
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showPaperTexture = showPaperTexture
        self.elevated = elevated
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Base paper color
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(elevated ? Color.Journal.elevatedCard : Color.Journal.cardBackground)
                    
                    // Paper texture overlay
                    if showPaperTexture {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear,
                                        Color.Journal.sepia.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.Journal.sepia.opacity(0.2),
                                    Color.Journal.sepia.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: Color.Journal.inkBrown.opacity(elevated ? 0.12 : 0.08),
                radius: elevated ? 12 : 8,
                x: 0,
                y: elevated ? 6 : 4
            )
    }
}

// MARK: - Journal Header

/// A decorative header for journal-style sections
struct JournalSectionHeader: View {
    let title: String
    var icon: String?
    var mode: RoutineMode = .morning
    
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(mode.accentColor)
            }
            
            Text(title)
                .font(accessibility.headingFont(size: 17))
                .foregroundColor(Color.Journal.inkBrown)
            
            // Decorative line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Journal.sepia.opacity(0.4), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
}

// MARK: - Journal Divider

/// A decorative divider with ornamental flourish
struct JournalDivider: View {
    var mode: RoutineMode = .morning
    var style: DividerStyle = .simple
    
    enum DividerStyle {
        case simple
        case ornamental
        case dotted
    }
    
    var body: some View {
        switch style {
        case .simple:
            Rectangle()
                .fill(Color.Journal.sepia.opacity(0.2))
                .frame(height: 1)
                .padding(.vertical, 8)
            
        case .ornamental:
            HStack(spacing: 8) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.Journal.sepia.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.Journal.sepia.opacity(0.4))
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.Journal.sepia.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
            .padding(.vertical, 12)
            
        case .dotted:
            HStack(spacing: 6) {
                ForEach(0..<20, id: \.self) { _ in
                    Circle()
                        .fill(Color.Journal.sepia.opacity(0.25))
                        .frame(width: 3, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Journal Text Field

/// A styled text field with underline for journaling
struct JournalTextField: View {
    let placeholder: String
    @Binding var text: String
    var mode: RoutineMode = .morning
    var lineLimit: Int = 1
    var isFocused: Bool = false
    var onFocus: (() -> Void)? = nil
    
    @FocusState private var internalFocus: Bool
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            TextField(placeholder, text: $text, axis: lineLimit > 1 ? .vertical : .horizontal)
                .font(accessibility.bodyFont())
                .foregroundColor(Color.Journal.inkBrown)
                .lineLimit(lineLimit)
                .focused($internalFocus)
                .onChange(of: internalFocus) { _, newValue in
                    if newValue {
                        onFocus?()
                    }
                }
            
            // Animated underline
            Rectangle()
                .fill((internalFocus || isFocused) ? mode.accentColor : Color.Journal.sepia.opacity(0.3))
                .frame(height: (internalFocus || isFocused) ? 2 : 1)
                .animation(.easeInOut(duration: 0.2), value: internalFocus)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Journal Text Editor

/// A styled multi-line text editor for reflections
struct JournalTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var mode: RoutineMode = .morning
    var minHeight: CGFloat = 100
    var isFocused: Bool = false
    var onFocus: (() -> Void)? = nil
    
    @FocusState private var internalFocus: Bool
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .font(accessibility.bodyFont())
                    .foregroundColor(Color.Journal.mutedText.opacity(0.6))
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
            
            TextEditor(text: $text)
                .font(accessibility.bodyFont())
                .foregroundColor(Color.Journal.inkBrown)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: minHeight)
                .focused($internalFocus)
                .onChange(of: internalFocus) { _, newValue in
                    if newValue {
                        onFocus?()
                    }
                }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Journal.paper.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder((internalFocus || isFocused) ? mode.accentColor.opacity(0.5) : Color.Journal.sepia.opacity(0.2), lineWidth: (internalFocus || isFocused) ? 2 : 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: internalFocus)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Journal Bullet Point

/// A styled bullet point for lists
struct JournalBulletPoint: View {
    let text: String
    var icon: String = "circle.fill"
    var mode: RoutineMode = .morning
    
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 6))
                .foregroundColor(mode.accentColor)
                .padding(.top, 7)
            
            Text(text)
                .font(accessibility.bodyFont())
                .foregroundColor(Color.Journal.inkBrown)
                .lineSpacing(accessibility.lineSpacingValue)
        }
    }
}

// MARK: - Journal Quote

/// A styled quote block for scripture or inspirational text
struct JournalQuote: View {
    let text: String
    var attribution: String?
    var mode: RoutineMode = .morning
    
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 0) {
                // Opening quote mark
                Text("\u{201C}")
                    .font(.system(size: 48, weight: .light, design: .serif))
                    .foregroundColor(mode.accentColor.opacity(0.3))
                    .offset(y: -8)
                
                Text(text)
                    .font(accessibility.scriptureFont(size: 20))
                    .foregroundColor(Color.Journal.inkBrown)
                    .lineSpacing(accessibility.lineSpacingValue)
                    .padding(.leading, 4)
            }
            
            if let attribution = attribution {
                Text("— \(attribution)")
                    .font(accessibility.bodyFont(size: 15))
                    .foregroundColor(mode.accentColor)
                    .padding(.leading, 40)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(mode.accentColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(mode.accentColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Journal Badge

/// A small decorative badge for labels
struct JournalBadge: View {
    let text: String
    var icon: String?
    var mode: RoutineMode = .morning
    var style: BadgeStyle = .filled
    
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    enum BadgeStyle {
        case filled
        case outlined
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
            }
            
            Text(text)
                .font(accessibility.captionFont(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Group {
                switch style {
                case .filled:
                    Capsule()
                        .fill(mode.accentColor.opacity(0.15))
                case .outlined:
                    Capsule()
                        .strokeBorder(mode.accentColor.opacity(0.3), lineWidth: 1)
                }
            }
        )
        .foregroundColor(mode.accentColor)
    }
}

// MARK: - Journal Completion Stamp

/// An animated "completed" stamp for routine completion
struct JournalCompletionStamp: View {
    var mode: RoutineMode = .morning
    @State private var isShowing = false
    @State private var rotation = -15.0
    @State private var scale = 0.3
    
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(mode.accentColor, lineWidth: 3)
                .frame(width: 100, height: 100)
            
            // Inner content
            VStack(spacing: 2) {
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                
                Text("COMPLETE")
                    .font(accessibility.captionFont(size: 10))
                    .tracking(1)
            }
            .foregroundColor(mode.accentColor)
        }
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .opacity(isShowing ? 1 : 0)
        .onAppear {
            withAnimation(accessibility.standardAnimation ?? .spring(response: 0.5, dampingFraction: 0.6)) {
                isShowing = true
                rotation = -8
                scale = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("Journal Components") {
    ScrollView {
        VStack(spacing: 24) {
            RoutineJournalCard(mode: .morning) {
                VStack(alignment: .leading, spacing: 16) {
                    JournalSectionHeader(title: "Morning Reflection", icon: "sunrise.fill", mode: .morning)
                    
                    JournalBulletPoint(text: "Thank God for a new day", mode: .morning)
                    JournalBulletPoint(text: "Ask for His guidance", mode: .morning)
                    
                    JournalDivider(mode: .morning, style: .ornamental)
                    
                    JournalQuote(
                        text: "This is the day the Lord has made; let us rejoice and be glad in it.",
                        attribution: "Psalm 118:24",
                        mode: .morning
                    )
                }
            }
            
            HStack {
                JournalBadge(text: "2 min", icon: "clock", mode: .morning)
                JournalBadge(text: "Prayer", mode: .morning, style: .outlined)
            }
            
            JournalCompletionStamp(mode: .morning)
        }
        .padding()
    }
    .background(Color.Journal.paper)
}

