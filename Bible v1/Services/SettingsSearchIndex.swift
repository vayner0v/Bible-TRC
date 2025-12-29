//
//  SettingsSearchIndex.swift
//  Bible v1
//
//  Search index for settings navigation
//

import Foundation
import SwiftUI
import Combine

/// Represents a searchable setting item
struct SettingsSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let keywords: [String]
    let section: SearchSettingsSection
    let icon: String
    let destination: SettingsDestination
    
    /// Check if this result matches a search query
    func matches(_ query: String) -> Bool {
        let lowercased = query.lowercased()
        if title.lowercased().contains(lowercased) { return true }
        return keywords.contains { $0.lowercased().contains(lowercased) }
    }
}

/// Settings sections for organization (renamed to avoid conflict with SettingsSection view)
enum SearchSettingsSection: String, CaseIterable {
    case quickSettings = "Quick Settings"
    case premium = "Premium"
    case reading = "Reading"
    case audio = "Audio & Voice"
    case downloads = "Offline Reading"
    case hub = "Spiritual Hub"
    case data = "Your Data"
    case about = "About"
    case developer = "Developer"
}

/// Destinations for settings navigation
enum SettingsDestination: Equatable {
    case reading
    case audio
    case immersiveMode
    case downloads
    case notifications
    case privacy
    case accessibility
    case subscription
    case acknowledgments
    case voiceSettings
    
    // Specific settings within sections
    case theme
    case fontSize
    case font
    case voiceType
    case autoContinue
    case clearData
    case clearCache
    case exportData
}

/// Provides searchable index for all settings
@MainActor
class SettingsSearchIndex: ObservableObject {
    static let shared = SettingsSearchIndex()
    
    @Published var searchResults: [SettingsSearchResult] = []
    
    /// All searchable settings
    private let allSettings: [SettingsSearchResult] = [
        // Quick Settings
        SettingsSearchResult(
            title: "Theme",
            keywords: ["dark mode", "light mode", "appearance", "color", "sepia", "night"],
            section: SearchSettingsSection.quickSettings,
            icon: "paintbrush.fill",
            destination: SettingsDestination.theme
        ),
        SettingsSearchResult(
            title: "Reader Text Size",
            keywords: ["font size", "text size", "bigger", "smaller", "zoom", "reading size"],
            section: SearchSettingsSection.quickSettings,
            icon: "textformat.size",
            destination: SettingsDestination.fontSize
        ),
        SettingsSearchResult(
            title: "Premium Voice",
            keywords: ["AI voice", "voice type", "narration", "TTS", "speech"],
            section: SearchSettingsSection.quickSettings,
            icon: "waveform",
            destination: SettingsDestination.voiceType
        ),
        SettingsSearchResult(
            title: "Auto-Continue",
            keywords: ["next chapter", "continuous", "autoplay"],
            section: SearchSettingsSection.quickSettings,
            icon: "arrow.right.circle",
            destination: SettingsDestination.autoContinue
        ),
        
        // Premium
        SettingsSearchResult(
            title: "Subscription",
            keywords: ["premium", "upgrade", "pro", "purchase", "payment"],
            section: SearchSettingsSection.premium,
            icon: "crown.fill",
            destination: SettingsDestination.subscription
        ),
        
        // Reading
        SettingsSearchResult(
            title: "Reading Settings",
            keywords: ["text", "display", "format", "verse", "scripture"],
            section: SearchSettingsSection.reading,
            icon: "book.fill",
            destination: SettingsDestination.reading
        ),
        SettingsSearchResult(
            title: "Font Family",
            keywords: ["typeface", "georgia", "palatino", "serif", "font style"],
            section: SearchSettingsSection.reading,
            icon: "textformat",
            destination: SettingsDestination.font
        ),
        SettingsSearchResult(
            title: "Line Spacing",
            keywords: ["paragraph", "spacing", "leading", "gap"],
            section: SearchSettingsSection.reading,
            icon: "text.alignleft",
            destination: SettingsDestination.reading
        ),
        SettingsSearchResult(
            title: "Verse Numbers",
            keywords: ["show verse", "hide verse", "numbers", "reference"],
            section: SearchSettingsSection.reading,
            icon: "number",
            destination: SettingsDestination.reading
        ),
        SettingsSearchResult(
            title: "Reading Presets",
            keywords: ["study", "night", "large print", "minimal", "preset"],
            section: SearchSettingsSection.reading,
            icon: "slider.horizontal.3",
            destination: SettingsDestination.reading
        ),
        
        // Audio
        SettingsSearchResult(
            title: "Audio Settings",
            keywords: ["voice", "speech", "listen", "narration", "playback"],
            section: SearchSettingsSection.audio,
            icon: "speaker.wave.3.fill",
            destination: SettingsDestination.audio
        ),
        SettingsSearchResult(
            title: "Voice Selection",
            keywords: ["choose voice", "alloy", "echo", "fable", "onyx", "nova", "shimmer"],
            section: SearchSettingsSection.audio,
            icon: "person.wave.2",
            destination: SettingsDestination.voiceSettings
        ),
        SettingsSearchResult(
            title: "Reading Speed",
            keywords: ["playback speed", "rate", "faster", "slower"],
            section: SearchSettingsSection.audio,
            icon: "speedometer",
            destination: SettingsDestination.audio
        ),
        SettingsSearchResult(
            title: "Immersive Mode",
            keywords: ["fullscreen", "listening", "animation", "focus"],
            section: SearchSettingsSection.audio,
            icon: "sparkles",
            destination: SettingsDestination.immersiveMode
        ),
        
        // Downloads
        SettingsSearchResult(
            title: "Manage Downloads",
            keywords: ["offline", "translation", "download", "storage"],
            section: SearchSettingsSection.downloads,
            icon: "arrow.down.circle",
            destination: SettingsDestination.downloads
        ),
        SettingsSearchResult(
            title: "Clear Cache",
            keywords: ["storage", "space", "delete cache", "free up"],
            section: SearchSettingsSection.downloads,
            icon: "trash",
            destination: SettingsDestination.clearCache
        ),
        
        // Hub Settings
        SettingsSearchResult(
            title: "Notifications",
            keywords: ["reminder", "alert", "push", "prayer reminder", "daily verse"],
            section: SearchSettingsSection.hub,
            icon: "bell.badge",
            destination: SettingsDestination.notifications
        ),
        SettingsSearchResult(
            title: "Privacy & Security",
            keywords: ["lock", "passcode", "face id", "touch id", "biometric", "private"],
            section: SearchSettingsSection.hub,
            icon: "lock.shield",
            destination: SettingsDestination.privacy
        ),
        SettingsSearchResult(
            title: "Accessibility",
            keywords: ["text size", "bold", "contrast", "motion", "voiceover", "dynamic type"],
            section: SearchSettingsSection.hub,
            icon: "accessibility",
            destination: SettingsDestination.accessibility
        ),
        
        // Data
        SettingsSearchResult(
            title: "Clear All Data",
            keywords: ["delete", "remove", "reset", "favorites", "highlights", "notes"],
            section: SearchSettingsSection.data,
            icon: "trash.fill",
            destination: SettingsDestination.clearData
        ),
        SettingsSearchResult(
            title: "Export Data",
            keywords: ["backup", "save", "download", "export", "share"],
            section: SearchSettingsSection.data,
            icon: "square.and.arrow.up",
            destination: SettingsDestination.exportData
        ),
        
        // About
        SettingsSearchResult(
            title: "Acknowledgments",
            keywords: ["credits", "thanks", "license", "about", "api"],
            section: SearchSettingsSection.about,
            icon: "heart.fill",
            destination: SettingsDestination.acknowledgments
        )
    ]
    
    private init() {}
    
    /// Search settings with a query
    func search(_ query: String) -> [SettingsSearchResult] {
        guard !query.isEmpty else { return [] }
        
        let results = allSettings.filter { $0.matches(query) }
        
        // Sort by relevance (title matches first)
        return results.sorted { lhs, rhs in
            let lhsTitleMatch = lhs.title.lowercased().contains(query.lowercased())
            let rhsTitleMatch = rhs.title.lowercased().contains(query.lowercased())
            
            if lhsTitleMatch && !rhsTitleMatch { return true }
            if !lhsTitleMatch && rhsTitleMatch { return false }
            return lhs.title < rhs.title
        }
    }
    
    /// Get all settings grouped by section
    func allSettingsGrouped() -> [(section: SearchSettingsSection, items: [SettingsSearchResult])] {
        var grouped: [SearchSettingsSection: [SettingsSearchResult]] = [:]
        
        for setting in allSettings {
            grouped[setting.section, default: []].append(setting)
        }
        
        return SearchSettingsSection.allCases.compactMap { section in
            guard let items = grouped[section], !items.isEmpty else { return nil }
            return (section: section, items: items)
        }
    }
}

// MARK: - Search Result Row View

struct SettingsSearchResultRow: View {
    let result: SettingsSearchResult
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: result.icon)
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.body)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(result.section.rawValue)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            }
            .padding(.vertical, 4)
        }
    }
}
