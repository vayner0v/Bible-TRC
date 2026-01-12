//
//  CustomThemeConfiguration.swift
//  Bible v1
//
//  User-customizable theme configuration for Theme Studio
//

import SwiftUI

/// Available corner radius options for custom themes
enum ThemeCornerRadius: Int, CaseIterable, Codable, Identifiable {
    case small = 8
    case medium = 12
    case large = 16
    case extraLarge = 20
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "Minimal"
        case .medium: return "Standard"
        case .large: return "Rounded"
        case .extraLarge: return "Pill"
        }
    }
    
    var cgFloat: CGFloat {
        CGFloat(rawValue)
    }
}

/// Preset accent colors for Theme Studio
struct AccentColorPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let color: Color
    let hex: String
    
    static let presets: [AccentColorPreset] = [
        AccentColorPreset(id: "blue", name: "Ocean", color: Color(hex: "0A84FF"), hex: "0A84FF"),
        AccentColorPreset(id: "teal", name: "Teal", color: Color(hex: "14B8A6"), hex: "14B8A6"),
        AccentColorPreset(id: "green", name: "Forest", color: Color(hex: "22C55E"), hex: "22C55E"),
        AccentColorPreset(id: "gold", name: "Gold", color: Color(hex: "C9A24B"), hex: "C9A24B"),
        AccentColorPreset(id: "amber", name: "Amber", color: Color(hex: "F59E0B"), hex: "F59E0B"),
        AccentColorPreset(id: "rose", name: "Rose", color: Color(hex: "F43F5E"), hex: "F43F5E"),
        AccentColorPreset(id: "purple", name: "Violet", color: Color(hex: "7C3AED"), hex: "7C3AED"),
        AccentColorPreset(id: "indigo", name: "Indigo", color: Color(hex: "6366F1"), hex: "6366F1"),
        AccentColorPreset(id: "pink", name: "Magenta", color: Color(hex: "EC4899"), hex: "EC4899"),
        AccentColorPreset(id: "slate", name: "Slate", color: Color(hex: "64748B"), hex: "64748B"),
    ]
    
    static func == (lhs: AccentColorPreset, rhs: AccentColorPreset) -> Bool {
        lhs.id == rhs.id
    }
}

/// User's custom theme configuration
/// Stores all customizable options and generates the full color scheme
struct CustomThemeConfiguration: Codable, Equatable {
    
    // MARK: - User Choices
    
    /// Accent/primary color hex (e.g., "0A84FF")
    var accentColorHex: String
    
    /// Neutral temperature: 0 = cool (blue-ish), 1 = warm (sepia-ish)
    var neutralTemperature: Double
    
    /// Corner radius for cards and buttons
    var cornerRadius: ThemeCornerRadius
    
    /// Contrast level
    var contrastLevel: ContrastLevel
    
    /// Glass/blur intensity
    var glassIntensity: GlassIntensity
    
    /// Whether this is a dark mode theme
    var isDarkMode: Bool
    
    // MARK: - Initialization
    
    init(
        accentColorHex: String = "0A84FF",
        neutralTemperature: Double = 0.5,
        cornerRadius: ThemeCornerRadius = .medium,
        contrastLevel: ContrastLevel = .normal,
        glassIntensity: GlassIntensity = .off,
        isDarkMode: Bool = true
    ) {
        self.accentColorHex = accentColorHex
        self.neutralTemperature = neutralTemperature
        self.cornerRadius = cornerRadius
        self.contrastLevel = contrastLevel
        self.glassIntensity = glassIntensity
        self.isDarkMode = isDarkMode
    }
    
    // MARK: - Computed Properties
    
    /// Accent color as SwiftUI Color
    var accentColor: Color {
        Color(hex: accentColorHex)
    }
    
    /// Generate the full color scheme from user choices
    var generatedColors: CustomThemeColors {
        CustomThemeColors.generate(
            accentColor: accentColor,
            neutralTemperature: neutralTemperature,
            isDarkMode: isDarkMode,
            contrastLevel: contrastLevel,
            glassIntensity: glassIntensity
        )
    }
    
    /// Corner radius as CGFloat
    var cornerRadiusValue: CGFloat {
        cornerRadius.cgFloat
    }
    
    /// Whether glass blur should be applied
    var shouldApplyGlassBlur: Bool {
        glassIntensity != .off
    }
    
    /// Blur radius for glass effects
    var blurRadius: CGFloat {
        glassIntensity.blurRadius
    }
    
    // MARK: - Presets
    
    /// Default custom theme
    static let `default` = CustomThemeConfiguration()
    
    /// Midnight Blue preset
    static let midnightBlue = CustomThemeConfiguration(
        accentColorHex: "0A84FF",
        neutralTemperature: 0.3,
        cornerRadius: .medium,
        contrastLevel: .normal,
        glassIntensity: .subtle,
        isDarkMode: true
    )
    
    /// Warm Gold preset
    static let warmGold = CustomThemeConfiguration(
        accentColorHex: "C9A24B",
        neutralTemperature: 0.8,
        cornerRadius: .large,
        contrastLevel: .normal,
        glassIntensity: .off,
        isDarkMode: false
    )
    
    /// Deep Violet preset
    static let deepViolet = CustomThemeConfiguration(
        accentColorHex: "7C3AED",
        neutralTemperature: 0.2,
        cornerRadius: .medium,
        contrastLevel: .normal,
        glassIntensity: .full,
        isDarkMode: true
    )
    
    /// Fresh Teal preset
    static let freshTeal = CustomThemeConfiguration(
        accentColorHex: "14B8A6",
        neutralTemperature: 0.4,
        cornerRadius: .large,
        contrastLevel: .normal,
        glassIntensity: .subtle,
        isDarkMode: false
    )
    
    /// All preset configurations for Theme Studio
    static let presets: [CustomThemeConfiguration] = [
        .default,
        .midnightBlue,
        .warmGold,
        .deepViolet,
        .freshTeal
    ]
    
    // MARK: - Validation
    
    /// Validate the configuration
    var isValid: Bool {
        // Check hex is valid
        let hexSet = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        guard accentColorHex.count == 6,
              accentColorHex.unicodeScalars.allSatisfy({ hexSet.contains($0) }) else {
            return false
        }
        
        // Check temperature is in range
        guard neutralTemperature >= 0, neutralTemperature <= 1 else {
            return false
        }
        
        return true
    }
    
    // MARK: - Mutations
    
    /// Create a copy with a different accent color
    func withAccentColor(_ hex: String) -> CustomThemeConfiguration {
        var copy = self
        copy.accentColorHex = hex
        return copy
    }
    
    /// Create a copy with different dark mode setting
    func withDarkMode(_ isDark: Bool) -> CustomThemeConfiguration {
        var copy = self
        copy.isDarkMode = isDark
        return copy
    }
    
    /// Create a copy with different temperature
    func withTemperature(_ temp: Double) -> CustomThemeConfiguration {
        var copy = self
        copy.neutralTemperature = max(0, min(1, temp))
        return copy
    }
}

// MARK: - Preview Helpers

extension CustomThemeConfiguration {
    /// Preview description for debugging
    var previewDescription: String {
        "Custom Theme: \(isDarkMode ? "Dark" : "Light"), Accent: #\(accentColorHex), Temp: \(String(format: "%.1f", neutralTemperature))"
    }
}




