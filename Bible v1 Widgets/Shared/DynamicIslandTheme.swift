//
//  DynamicIslandTheme.swift
//  Bible v1 Widgets
//
//  Shared theme definitions for Dynamic Island Live Activities
//  Reads settings from App Groups UserDefaults
//

import SwiftUI

// MARK: - Theme Enum (Mirrored from main app)

enum DITheme: String, Codable, CaseIterable {
    case iOSDefault = "ios_default"
    case appTheme = "app_theme"
    case darkGlass = "dark_glass"
    case minimal = "minimal"
    case vibrant = "vibrant"
}

enum DITextSize: String, Codable {
    case small, medium, large
    
    var scaleFactor: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        }
    }
}

// MARK: - Settings Structure (Mirrored from main app)

struct DynamicIslandWidgetSettings: Codable {
    // Audio Settings
    var audioTheme: DITheme = .appTheme
    var audioTextSize: DITextSize = .medium
    var audioShowProgress: Bool = true
    var audioShowVerseText: Bool = true
    var audioCompactMode: Bool = false
    var audioAnimationsEnabled: Bool = true
    
    // AI Settings
    var aiTheme: DITheme = .appTheme
    var aiTextSize: DITextSize = .medium
    var aiShowProgress: Bool = true
    var aiCompactMode: Bool = false
    var aiAnimationsEnabled: Bool = true
    
    static let `default` = DynamicIslandWidgetSettings()
    
    static func load() -> DynamicIslandWidgetSettings {
        guard let defaults = UserDefaults(suiteName: "group.vaynerov.Bible-v1"),
              let data = defaults.data(forKey: "dynamicIslandSettings"),
              let settings = try? JSONDecoder().decode(DynamicIslandWidgetSettings.self, from: data) else {
            return .default
        }
        return settings
    }
}

// MARK: - Theme Colors

struct ThemeColors {
    let background: Color
    let backgroundGradient: [Color]
    let accent: Color
    let text: Color
    let secondaryText: Color
    let progressBackground: Color
    let progressFill: Color
    
    static func audio(for theme: DITheme) -> ThemeColors {
        switch theme {
        case .iOSDefault:
            return ThemeColors(
                background: Color(white: 0.12),
                backgroundGradient: [Color(white: 0.14), Color(white: 0.1)],
                accent: .blue,
                text: .white,
                secondaryText: .white.opacity(0.6),
                progressBackground: .white.opacity(0.15),
                progressFill: .blue
            )
            
        case .appTheme:
            return ThemeColors(
                background: Color(red: 0.06, green: 0.08, blue: 0.12),
                backgroundGradient: [
                    Color(red: 0.06, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.05, blue: 0.08)
                ],
                accent: .cyan,
                text: .white,
                secondaryText: .white.opacity(0.6),
                progressBackground: .white.opacity(0.12),
                progressFill: .cyan
            )
            
        case .darkGlass:
            return ThemeColors(
                background: Color.black.opacity(0.7),
                backgroundGradient: [Color.black.opacity(0.75), Color.black.opacity(0.55)],
                accent: Color(red: 0.4, green: 0.8, blue: 1.0),
                text: .white,
                secondaryText: .white.opacity(0.55),
                progressBackground: .white.opacity(0.2),
                progressFill: Color(red: 0.4, green: 0.8, blue: 1.0)
            )
            
        case .minimal:
            return ThemeColors(
                background: .black,
                backgroundGradient: [.black, .black],
                accent: .white,
                text: .white,
                secondaryText: .white.opacity(0.5),
                progressBackground: .white.opacity(0.1),
                progressFill: .white.opacity(0.8)
            )
            
        case .vibrant:
            return ThemeColors(
                background: Color(red: 0.08, green: 0.04, blue: 0.14),
                backgroundGradient: [
                    Color(red: 0.1, green: 0.04, blue: 0.16),
                    Color(red: 0.04, green: 0.02, blue: 0.08)
                ],
                accent: Color(red: 0.2, green: 0.85, blue: 1.0),
                text: .white,
                secondaryText: Color(red: 0.2, green: 0.85, blue: 1.0).opacity(0.7),
                progressBackground: Color(red: 0.2, green: 0.85, blue: 1.0).opacity(0.2),
                progressFill: Color(red: 0.2, green: 0.85, blue: 1.0)
            )
        }
    }
    
    static func ai(for theme: DITheme, mode: String) -> ThemeColors {
        let modeAccent: Color = {
            switch mode {
            case "study": return Color(red: 0.4, green: 0.65, blue: 1.0)
            case "devotional": return Color(red: 0.75, green: 0.55, blue: 0.95)
            case "prayer": return Color(red: 1.0, green: 0.65, blue: 0.45)
            default: return Color(red: 0.4, green: 0.65, blue: 1.0)
            }
        }()
        
        switch theme {
        case .iOSDefault:
            return ThemeColors(
                background: Color(white: 0.12),
                backgroundGradient: [Color(white: 0.14), Color(white: 0.1)],
                accent: modeAccent,
                text: .white,
                secondaryText: .white.opacity(0.6),
                progressBackground: .white.opacity(0.15),
                progressFill: modeAccent
            )
            
        case .appTheme:
            return ThemeColors(
                background: Color(red: 0.06, green: 0.06, blue: 0.1),
                backgroundGradient: [
                    Color(red: 0.06, green: 0.06, blue: 0.1),
                    Color(red: 0.04, green: 0.04, blue: 0.07)
                ],
                accent: modeAccent,
                text: .white,
                secondaryText: .white.opacity(0.6),
                progressBackground: .white.opacity(0.1),
                progressFill: modeAccent
            )
            
        case .darkGlass:
            return ThemeColors(
                background: Color.black.opacity(0.7),
                backgroundGradient: [Color.black.opacity(0.75), Color.black.opacity(0.55)],
                accent: modeAccent,
                text: .white,
                secondaryText: .white.opacity(0.55),
                progressBackground: .white.opacity(0.2),
                progressFill: modeAccent
            )
            
        case .minimal:
            return ThemeColors(
                background: .black,
                backgroundGradient: [.black, .black],
                accent: .white,
                text: .white,
                secondaryText: .white.opacity(0.5),
                progressBackground: .white.opacity(0.1),
                progressFill: .white.opacity(0.8)
            )
            
        case .vibrant:
            let vibrantAccent: Color = {
                switch mode {
                case "study": return Color(red: 0.3, green: 0.7, blue: 1.0)
                case "devotional": return Color(red: 0.85, green: 0.5, blue: 1.0)
                case "prayer": return Color(red: 1.0, green: 0.5, blue: 0.4)
                default: return Color(red: 0.3, green: 0.7, blue: 1.0)
                }
            }()
            return ThemeColors(
                background: Color(red: 0.08, green: 0.04, blue: 0.14),
                backgroundGradient: [
                    Color(red: 0.1, green: 0.04, blue: 0.16),
                    Color(red: 0.04, green: 0.02, blue: 0.08)
                ],
                accent: vibrantAccent,
                text: .white,
                secondaryText: vibrantAccent.opacity(0.7),
                progressBackground: vibrantAccent.opacity(0.2),
                progressFill: vibrantAccent
            )
        }
    }
}



