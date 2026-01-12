//
//  AccessibilityModifiers.swift
//  Bible v1
//
//  View modifiers that apply accessibility settings from SettingsStore
//

import SwiftUI

// MARK: - Accessibility Environment Modifier

/// Applies accessibility settings from SettingsStore to a view hierarchy
struct AccessibilityEnvironmentModifier: ViewModifier {
    @ObservedObject private var settings = SettingsStore.shared
    
    func body(content: Content) -> some View {
        content
            // Apply bold text if enabled
            .environment(\.legibilityWeight, settings.boldTextEnabled ? .bold : .regular)
            // Apply reduced motion if enabled
            .transaction { transaction in
                if settings.reducedMotionEnabled {
                    transaction.animation = nil
                }
            }
    }
}

// MARK: - Button Shape Modifier

/// Adds visible borders to buttons when button shapes are enabled
struct AccessibleButtonModifier: ViewModifier {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if settings.buttonShapesEnabled {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.accentColor, lineWidth: 1)
                }
            }
    }
}

// MARK: - High Contrast Text Modifier

/// Applies high contrast colors when enabled
struct HighContrastTextModifier: ViewModifier {
    @ObservedObject private var settings = SettingsStore.shared
    let isSecondary: Bool
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(textColor)
    }
    
    private var textColor: Color {
        if settings.highContrastEnabled {
            return isSecondary ? Color(UIColor.secondaryLabel) : Color(UIColor.label)
        }
        return isSecondary ? ThemeManager.shared.secondaryTextColor : ThemeManager.shared.textColor
    }
}

// MARK: - Accessible Font Modifier

/// Applies the accessible font style from settings
struct AccessibleFontModifier: ViewModifier {
    @ObservedObject private var settings = SettingsStore.shared
    let style: AccessibleTextStyle
    
    enum AccessibleTextStyle {
        case body
        case headline
        case subheadline
        case caption
        case title
    }
    
    func body(content: Content) -> some View {
        content
            .font(fontForStyle)
            .lineSpacing(settings.effectiveLineSpacing)
    }
    
    private var fontForStyle: Font {
        let baseSize = settings.effectiveUIFontSize
        let weight: Font.Weight = settings.boldTextEnabled ? .semibold : .regular
        let design = fontDesign
        
        switch style {
        case .body:
            return .system(size: baseSize, weight: weight, design: design)
        case .headline:
            return .system(size: baseSize * 1.2, weight: .bold, design: design)
        case .subheadline:
            return .system(size: baseSize * 0.9, weight: .medium, design: design)
        case .caption:
            return .system(size: baseSize * 0.75, weight: weight, design: design)
        case .title:
            return .system(size: baseSize * 1.5, weight: .bold, design: design)
        }
    }
    
    private var fontDesign: Font.Design {
        switch settings.accessibleFontStyle {
        case .system:
            return .default
        case .openDyslexic:
            return .rounded
        case .serif:
            return .serif
        case .sansSerif:
            return .default
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies accessibility environment settings to the view hierarchy
    func accessibilityEnvironment() -> some View {
        modifier(AccessibilityEnvironmentModifier())
    }
    
    /// Adds button shape styling when accessibility setting is enabled
    func accessibleButtonShape() -> some View {
        modifier(AccessibleButtonModifier())
    }
    
    /// Applies high contrast text color when enabled
    func highContrastText(secondary: Bool = false) -> some View {
        modifier(HighContrastTextModifier(isSecondary: secondary))
    }
    
    /// Applies accessible font styling based on settings
    func accessibleFont(_ style: AccessibleFontModifier.AccessibleTextStyle = .body) -> some View {
        modifier(AccessibleFontModifier(style: style))
    }
    
    /// Applies animation respecting reduced motion setting
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        let settings = SettingsStore.shared
        return self.animation(settings.reducedMotionEnabled ? nil : animation, value: value)
    }
}

// MARK: - Reduced Motion Animation Wrapper

/// Animation wrapper that respects reduced motion settings
struct AccessibleAnimation {
    static func standard<V: Equatable>(value: V) -> Animation? {
        SettingsStore.shared.reducedMotionEnabled ? nil : .easeInOut(duration: 0.3)
    }
    
    static func spring() -> Animation? {
        SettingsStore.shared.reducedMotionEnabled ? nil : .spring(response: 0.4, dampingFraction: 0.8)
    }
}






