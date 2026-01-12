//
//  WidgetStyles.swift
//  Bible v1 Widgets
//
//  Shared styling for widgets
//

import SwiftUI
import WidgetKit

// MARK: - Widget Style Configuration

/// Configuration that applies styling based on preset selection
struct WidgetStyleConfig {
    let preset: StylePresetEntity?
    let colorScheme: ColorScheme?
    
    // Custom style properties (when using saved widget)
    private var customTextColor: Color?
    private var customSecondaryTextColor: Color?
    private var customAccentColor: Color?
    private var customBackground: AnyView?
    private var isCustom: Bool = false
    
    init(preset: StylePresetEntity, colorScheme: ColorScheme) {
        self.preset = preset
        self.colorScheme = colorScheme
        self.isCustom = false
    }
    
    /// Custom style initializer for saved widget projects
    init(
        textColor: Color,
        secondaryTextColor: Color,
        accentColor: Color,
        background: AnyView
    ) {
        self.preset = nil
        self.colorScheme = nil
        self.customTextColor = textColor
        self.customSecondaryTextColor = secondaryTextColor
        self.customAccentColor = accentColor
        self.customBackground = background
        self.isCustom = true
    }
    
    // MARK: - Colors
    
    var backgroundColor: Color {
        guard let preset = preset, let colorScheme = colorScheme else {
            return .white
        }
        switch preset.id {
        case "system":
            // Pure white in light mode, pure black in dark mode
            return colorScheme == .dark ? Color.black : Color.white
        case "classic_light":
            return Color(red: 0.99, green: 0.99, blue: 0.99)
        case "classic_dark":
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        case "sepia_warmth":
            return Color(red: 0.96, green: 0.93, blue: 0.87)
        case "minimal":
            return Color(red: 0.98, green: 0.98, blue: 0.98)
        case "gradient_bliss", "scripture_art", "midnight_gold", "sunrise_hope":
            return .clear // Uses gradient background
        default:
            return colorScheme == .dark ? Color.black : Color.white
        }
    }
    
    var textColor: Color {
        if isCustom, let color = customTextColor {
            return color
        }
        guard let preset = preset, let colorScheme = colorScheme else {
            return .primary
        }
        switch preset.id {
        case "system":
            return colorScheme == .dark ? Color.white : Color.black
        case "classic_light", "minimal":
            return Color(red: 0.12, green: 0.12, blue: 0.12)
        case "classic_dark", "midnight_gold":
            return Color(red: 0.92, green: 0.92, blue: 0.92)
        case "sepia_warmth":
            return Color(red: 0.24, green: 0.20, blue: 0.15)
        case "gradient_bliss", "scripture_art":
            return .white
        case "sunrise_hope":
            return Color(red: 0.25, green: 0.15, blue: 0.1)
        default:
            return colorScheme == .dark ? Color.white : Color.black
        }
    }
    
    var secondaryTextColor: Color {
        if isCustom, let color = customSecondaryTextColor {
            return color
        }
        guard let preset = preset, let colorScheme = colorScheme else {
            return .secondary
        }
        switch preset.id {
        case "system":
            return colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
        case "classic_light", "minimal":
            return Color(red: 0.45, green: 0.45, blue: 0.45)
        case "classic_dark", "midnight_gold":
            return Color(red: 0.60, green: 0.60, blue: 0.60)
        case "sepia_warmth":
            return Color(red: 0.45, green: 0.40, blue: 0.32)
        case "gradient_bliss", "scripture_art":
            return Color.white.opacity(0.8)
        case "sunrise_hope":
            return Color(red: 0.4, green: 0.25, blue: 0.15)
        default:
            return colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
        }
    }
    
    var accentColor: Color {
        if isCustom, let color = customAccentColor {
            return color
        }
        guard let preset = preset, let colorScheme = colorScheme else {
            return .blue
        }
        switch preset.id {
        case "system":
            return colorScheme == .dark ? Color(red: 0.40, green: 0.60, blue: 0.90) : Color(red: 0.20, green: 0.45, blue: 0.75)
        case "classic_light":
            return Color(red: 0.20, green: 0.45, blue: 0.75)
        case "classic_dark":
            return Color(red: 0.40, green: 0.60, blue: 0.90)
        case "sepia_warmth":
            return Color(red: 0.55, green: 0.35, blue: 0.20)
        case "minimal":
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        case "gradient_bliss":
            return Color.white.opacity(0.9)
        case "scripture_art":
            return Color(red: 0.85, green: 0.75, blue: 0.55)
        case "midnight_gold":
            return Color(red: 0.85, green: 0.70, blue: 0.45)
        case "sunrise_hope":
            return Color(red: 0.3, green: 0.15, blue: 0.1)
        default:
            return colorScheme == .dark ? Color(red: 0.40, green: 0.60, blue: 0.90) : Color(red: 0.20, green: 0.45, blue: 0.75)
        }
    }
    
    var cardBackground: Color {
        guard let preset = preset, let colorScheme = colorScheme else {
            return Color(white: 0.95)
        }
        switch preset.id {
        case "system":
            return colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95)
        case "classic_light", "minimal":
            return Color(red: 0.96, green: 0.96, blue: 0.97)
        case "classic_dark", "midnight_gold":
            return Color(red: 0.17, green: 0.17, blue: 0.18)
        case "sepia_warmth":
            return Color(red: 0.94, green: 0.90, blue: 0.82)
        case "gradient_bliss", "scripture_art", "sunrise_hope":
            return Color.white.opacity(0.15)
        default:
            return colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95)
        }
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    var background: some View {
        if isCustom, let customBg = customBackground {
            customBg
        } else if let preset = preset {
            switch preset.id {
            case "gradient_bliss":
                WidgetGradients.lavender
            case "scripture_art":
                WidgetGradients.midnight
            case "midnight_gold":
                WidgetGradients.midnight
            case "sunrise_hope":
                WidgetGradients.sunrise
            default:
                backgroundColor
            }
        } else {
            Color.white
        }
    }
}

// MARK: - Legacy Widget Theme (for backwards compatibility)

/// Widget color themes matching the app
enum WidgetTheme {
    case light
    case dark
    case sepia
    
    var backgroundColor: Color {
        switch self {
        case .light: return Color(red: 0.99, green: 0.99, blue: 0.99)
        case .dark: return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .sepia: return Color(red: 0.96, green: 0.93, blue: 0.87)
        }
    }
    
    var textColor: Color {
        switch self {
        case .light: return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .dark: return Color(red: 0.92, green: 0.92, blue: 0.92)
        case .sepia: return Color(red: 0.24, green: 0.20, blue: 0.15)
        }
    }
    
    var secondaryTextColor: Color {
        switch self {
        case .light: return Color(red: 0.45, green: 0.45, blue: 0.45)
        case .dark: return Color(red: 0.60, green: 0.60, blue: 0.60)
        case .sepia: return Color(red: 0.45, green: 0.40, blue: 0.32)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .light: return Color(red: 0.20, green: 0.45, blue: 0.75)
        case .dark: return Color(red: 0.40, green: 0.60, blue: 0.90)
        case .sepia: return Color(red: 0.55, green: 0.35, blue: 0.20)
        }
    }
    
    var cardBackground: Color {
        switch self {
        case .light: return Color(red: 0.96, green: 0.96, blue: 0.97)
        case .dark: return Color(red: 0.17, green: 0.17, blue: 0.18)
        case .sepia: return Color(red: 0.94, green: 0.90, blue: 0.82)
        }
    }
}

/// Common widget styling modifiers
struct WidgetContainerStyle: ViewModifier {
    let theme: WidgetTheme
    
    func body(content: Content) -> some View {
        content
            .containerBackground(for: .widget) {
                theme.backgroundColor
            }
    }
}

extension View {
    func widgetContainer(theme: WidgetTheme = .light) -> some View {
        modifier(WidgetContainerStyle(theme: theme))
    }
}

// MARK: - Gradient Backgrounds

/// Gradient backgrounds for widgets
struct WidgetGradients {
    static let sunrise = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.65, blue: 0.45),
            Color(red: 0.98, green: 0.80, blue: 0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let ocean = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.5, blue: 0.8),
            Color(red: 0.4, green: 0.7, blue: 0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let lavender = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.5, blue: 0.8),
            Color(red: 0.8, green: 0.7, blue: 0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let forest = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.5, blue: 0.4),
            Color(red: 0.3, green: 0.7, blue: 0.5)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let midnight = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.08, blue: 0.15),
            Color(red: 0.15, green: 0.12, blue: 0.25)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Widget Icon Styles

/// Widget icon styles
struct WidgetIconStyle: ViewModifier {
    let color: Color
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(color)
    }
}

extension View {
    func widgetIcon(color: Color, size: CGFloat = 18) -> some View {
        modifier(WidgetIconStyle(color: color, size: size))
    }
}
