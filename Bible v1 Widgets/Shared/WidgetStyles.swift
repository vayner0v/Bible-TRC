//
//  WidgetStyles.swift
//  Bible v1 Widgets
//
//  Shared styling for widgets
//

import SwiftUI
import WidgetKit

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

