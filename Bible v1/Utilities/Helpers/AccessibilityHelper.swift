//
//  AccessibilityHelper.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI
import Combine

/// Helper for accessibility labels and hints
enum AccessibilityHelper {
    
    // MARK: - Verse Accessibility
    
    static func verseLabel(
        verse: Int,
        text: String,
        isFavorite: Bool,
        isHighlighted: Bool,
        hasNote: Bool
    ) -> String {
        var label = "Verse \(verse). \(text)"
        
        var annotations: [String] = []
        if isFavorite { annotations.append("Favorited") }
        if isHighlighted { annotations.append("Highlighted") }
        if hasNote { annotations.append("Has note") }
        
        if !annotations.isEmpty {
            label += ". " + annotations.joined(separator: ", ")
        }
        
        return label
    }
    
    static func verseHint(isFavorite: Bool) -> String {
        "Double-tap to open options. Long press to \(isFavorite ? "remove from favorites" : "add to favorites")"
    }
    
    // MARK: - Navigation Accessibility
    
    static func chapterNavigationLabel(book: String, chapter: Int) -> String {
        "\(book), Chapter \(chapter)"
    }
    
    static func previousChapterHint(hasPrevious: Bool) -> String {
        hasPrevious ? "Go to previous chapter" : "No previous chapter"
    }
    
    static func nextChapterHint(hasNext: Bool) -> String {
        hasNext ? "Go to next chapter" : "No next chapter"
    }
    
    // MARK: - Translation Accessibility
    
    static func translationLabel(_ translation: Translation) -> String {
        var label = translation.name
        if let english = translation.englishName {
            label += ", \(english)"
        }
        label += ", \(translation.language.languageDisplayName)"
        if translation.isRTL {
            label += ", right to left text"
        }
        return label
    }
    
    // MARK: - Audio Accessibility
    
    static func audioPlayPauseLabel(isPlaying: Bool, isPaused: Bool) -> String {
        if isPaused {
            return "Resume audio"
        } else if isPlaying {
            return "Pause audio"
        } else {
            return "Play audio"
        }
    }
    
    static func audioSpeedLabel(_ speed: Float) -> String {
        "Playback speed, \(String(format: "%.1f", speed)) times"
    }
    
    // MARK: - Highlight Accessibility
    
    static func highlightColorLabel(_ color: HighlightColor) -> String {
        "Highlight with \(color.displayName)"
    }
    
    // MARK: - Settings Accessibility
    
    static func fontSizeLabel(_ size: Double) -> String {
        "Font size, \(Int(size)) points"
    }
    
    static func lineSpacingLabel(_ spacing: Double) -> String {
        "Line spacing, \(Int(spacing)) points"
    }
}

// MARK: - Accessibility View Modifier

struct AccessibleVerse: ViewModifier {
    let verse: Verse
    let isFavorite: Bool
    let isHighlighted: Bool
    let hasNote: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(
                AccessibilityHelper.verseLabel(
                    verse: verse.verse,
                    text: verse.text,
                    isFavorite: isFavorite,
                    isHighlighted: isHighlighted,
                    hasNote: hasNote
                )
            )
            .accessibilityHint(AccessibilityHelper.verseHint(isFavorite: isFavorite))
            .accessibilityAddTraits(.isButton)
    }
}

extension View {
    func accessibleVerse(
        _ verse: Verse,
        isFavorite: Bool = false,
        isHighlighted: Bool = false,
        hasNote: Bool = false
    ) -> some View {
        modifier(AccessibleVerse(
            verse: verse,
            isFavorite: isFavorite,
            isHighlighted: isHighlighted,
            hasNote: hasNote
        ))
    }
}

