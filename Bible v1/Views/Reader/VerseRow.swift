//
//  VerseRow.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// A row displaying a single verse
struct VerseRow: View {
    let verse: Verse
    let isRTL: Bool
    let highlightColor: Color?
    let hasNote: Bool
    let isFavorite: Bool
    let isPlaying: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    
    init(
        verse: Verse,
        isRTL: Bool = false,
        highlightColor: Color? = nil,
        hasNote: Bool = false,
        isFavorite: Bool = false,
        isPlaying: Bool = false
    ) {
        self.verse = verse
        self.isRTL = isRTL
        self.highlightColor = highlightColor
        self.hasNote = hasNote
        self.isFavorite = isFavorite
        self.isPlaying = isPlaying
    }
    
    /// Computed text alignment that respects RTL override
    private var effectiveTextAlignment: SwiftUI.TextAlignment {
        if isRTL { return .trailing }
        switch settings.readerTextAlignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
    
    /// Computed horizontal alignment for the VStack
    private var effectiveHorizontalAlignment: HorizontalAlignment {
        if isRTL { return .trailing }
        switch settings.readerTextAlignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
    
    /// Computed frame alignment
    private var effectiveFrameAlignment: Alignment {
        if isRTL { return .trailing }
        switch settings.readerTextAlignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if !isRTL && settings.showVerseNumbers {
                verseNumberView
            }
            
            // Verse text
            VStack(alignment: effectiveHorizontalAlignment, spacing: 6) {
                Text(verse.text)
                    .font(themeManager.verseFont)
                    .foregroundColor(themeManager.textColor)
                    .lineSpacing(themeManager.lineSpacing)
                    .multilineTextAlignment(effectiveTextAlignment)
                    .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Indicators
                if hasNote || isFavorite {
                    HStack(spacing: 6) {
                        if isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        if hasNote {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: effectiveFrameAlignment)
            
            if isRTL && settings.showVerseNumbers {
                verseNumberView
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(backgroundView)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
    
    private var verseNumberView: some View {
        Text(verse.verseNumber)
            .font(themeManager.verseNumberFont)
            .foregroundColor(themeManager.accentColor)
            .frame(width: 36, alignment: isRTL ? .trailing : .leading)
            .padding(.top, 3)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isPlaying {
            themeManager.accentColor.opacity(0.15)
        } else if let highlightColor = highlightColor {
            highlightColor
        } else {
            Color.clear
        }
    }
}

/// A verse row with selection capability
struct SelectableVerseRow: View {
    let verse: Verse
    let reference: VerseReference
    let isRTL: Bool
    let highlightColor: Color?
    let hasNote: Bool
    let isFavorite: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VerseRow(
            verse: verse,
            isRTL: isRTL,
            highlightColor: highlightColor,
            hasNote: hasNote,
            isFavorite: isFavorite,
            isPlaying: isPlaying
        )
        .background(isPressed ? themeManager.accentColor.opacity(0.1) : Color.clear)
        .scaleEffect(isPressed ? 0.99 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onLongPress()
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

/// Verse row optimized for search results
struct SearchResultVerseRow: View {
    let result: SearchResult
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.reference.shortReference)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.accentColor)
            
            Text(result.highlightedText)
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Normal Verse") {
    VStack(spacing: 0) {
        VerseRow(
            verse: Verse(verse: 1, text: "In the beginning God created the heaven and the earth.")
        )
        
        VerseRow(
            verse: Verse(verse: 2, text: "And the earth was without form, and void; and darkness was upon the face of the deep."),
            highlightColor: .yellow.opacity(0.4)
        )
        
        VerseRow(
            verse: Verse(verse: 3, text: "And God said, Let there be light: and there was light."),
            hasNote: true,
            isFavorite: true
        )
        
        VerseRow(
            verse: Verse(verse: 4, text: "And God saw the light, that it was good."),
            isPlaying: true
        )
    }
    .background(Color(.systemBackground))
}
