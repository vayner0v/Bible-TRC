//
//  DynamicIslandSettings.swift
//  Bible v1
//
//  Settings model for Dynamic Island customization
//

import Foundation
import SwiftUI

// MARK: - Theme Options

/// Available themes for Dynamic Island appearance
enum DITheme: String, Codable, CaseIterable, Identifiable {
    case iOSDefault = "ios_default"
    case appTheme = "app_theme"
    case darkGlass = "dark_glass"
    case minimal = "minimal"
    case vibrant = "vibrant"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .iOSDefault: return "iOS Default"
        case .appTheme: return "App Theme"
        case .darkGlass: return "Dark Glass"
        case .minimal: return "Minimal"
        case .vibrant: return "Vibrant"
        }
    }
    
    var description: String {
        switch self {
        case .iOSDefault: return "System appearance"
        case .appTheme: return "Matches your app theme"
        case .darkGlass: return "Translucent with blur"
        case .minimal: return "Clean, text-focused"
        case .vibrant: return "Bold, high contrast"
        }
    }
    
    var iconName: String {
        switch self {
        case .iOSDefault: return "iphone"
        case .appTheme: return "paintpalette"
        case .darkGlass: return "rectangle.on.rectangle"
        case .minimal: return "text.alignleft"
        case .vibrant: return "sparkles"
        }
    }
}

// MARK: - Text Size Options

/// Text size options for Dynamic Island
enum DITextSize: String, Codable, CaseIterable, Identifiable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        }
    }
}

// MARK: - Settings Model

/// Complete settings for Dynamic Island customization
struct DynamicIslandSettings: Codable, Equatable {
    
    // MARK: - Audio Playback Settings
    
    var audioTheme: DITheme = .appTheme
    var audioTextSize: DITextSize = .medium
    var audioShowProgress: Bool = true
    var audioShowVerseText: Bool = true
    var audioCompactMode: Bool = false
    var audioAnimationsEnabled: Bool = true
    var audioHapticsEnabled: Bool = true
    
    // MARK: - AI Generation Settings
    
    var aiTheme: DITheme = .appTheme
    var aiTextSize: DITextSize = .medium
    var aiShowProgress: Bool = true
    var aiCompactMode: Bool = false
    var aiAnimationsEnabled: Bool = true
    
    // MARK: - Defaults
    
    static let `default` = DynamicIslandSettings()
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case audioTheme, audioTextSize, audioShowProgress, audioShowVerseText
        case audioCompactMode, audioAnimationsEnabled, audioHapticsEnabled
        case aiTheme, aiTextSize, aiShowProgress, aiCompactMode, aiAnimationsEnabled
    }
}

// MARK: - Theme Colors

/// Color palette for each theme
struct DIThemeColors {
    let background: Color
    let backgroundGradient: [Color]
    let accent: Color
    let text: Color
    let secondaryText: Color
    let progressBackground: Color
    let progressFill: Color
    let controlBackground: Color
    let controlForeground: Color
    
    static func colors(for theme: DITheme, mode: String = "audio") -> DIThemeColors {
        switch theme {
        case .iOSDefault:
            return DIThemeColors(
                background: Color(.systemBackground),
                backgroundGradient: [Color(.systemBackground), Color(.secondarySystemBackground)],
                accent: .blue,
                text: Color(.label),
                secondaryText: Color(.secondaryLabel),
                progressBackground: Color(.systemGray5),
                progressFill: .blue,
                controlBackground: Color(.systemGray5),
                controlForeground: .blue
            )
            
        case .appTheme:
            // These will be overridden by actual app theme colors
            let accentColor = mode == "audio" ? 
                Color(red: 0.4, green: 0.6, blue: 0.9) : 
                Color(red: 0.6, green: 0.4, blue: 0.9)
            return DIThemeColors(
                background: Color(red: 0.08, green: 0.08, blue: 0.12),
                backgroundGradient: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                accent: accentColor,
                text: .white,
                secondaryText: .white.opacity(0.7),
                progressBackground: .white.opacity(0.15),
                progressFill: accentColor,
                controlBackground: accentColor,
                controlForeground: .white
            )
            
        case .darkGlass:
            return DIThemeColors(
                background: Color.black.opacity(0.6),
                backgroundGradient: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.5)
                ],
                accent: .cyan,
                text: .white,
                secondaryText: .white.opacity(0.6),
                progressBackground: .white.opacity(0.2),
                progressFill: .cyan,
                controlBackground: .white.opacity(0.15),
                controlForeground: .cyan
            )
            
        case .minimal:
            return DIThemeColors(
                background: Color.black,
                backgroundGradient: [Color.black, Color.black],
                accent: .white,
                text: .white,
                secondaryText: .white.opacity(0.5),
                progressBackground: .white.opacity(0.1),
                progressFill: .white.opacity(0.8),
                controlBackground: .clear,
                controlForeground: .white
            )
            
        case .vibrant:
            let vibrantAccent = mode == "audio" ?
                Color(red: 0.2, green: 0.8, blue: 1.0) :
                Color(red: 1.0, green: 0.4, blue: 0.6)
            return DIThemeColors(
                background: Color(red: 0.1, green: 0.05, blue: 0.15),
                backgroundGradient: [
                    Color(red: 0.15, green: 0.05, blue: 0.2),
                    Color(red: 0.05, green: 0.02, blue: 0.1)
                ],
                accent: vibrantAccent,
                text: .white,
                secondaryText: vibrantAccent.opacity(0.7),
                progressBackground: vibrantAccent.opacity(0.2),
                progressFill: vibrantAccent,
                controlBackground: vibrantAccent,
                controlForeground: .white
            )
        }
    }
}



