//
//  Typography.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// Typography system for the app
struct Typography {
    
    // MARK: - Display Fonts
    
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body Fonts
    
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - Reading Fonts (Serif)
    
    static func readingFont(size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
    
    static func verseNumber(size: CGFloat) -> Font {
        .system(size: size * 0.7, weight: .semibold, design: .serif)
    }
    
    // MARK: - Dynamic Type Support
    
    static func scaledFont(style: Font.TextStyle, design: Font.Design = .default) -> Font {
        .system(style, design: design)
    }
}

// MARK: - Text Styles

struct VerseTextStyle: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .font(themeManager.verseFont)
            .foregroundColor(themeManager.textColor)
            .lineSpacing(themeManager.lineSpacing)
    }
}

struct VerseNumberStyle: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .font(themeManager.verseNumberFont)
            .foregroundColor(themeManager.accentColor)
    }
}

struct HeadingStyle: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .font(themeManager.headingFont)
            .foregroundColor(themeManager.textColor)
    }
}

extension View {
    func verseTextStyle() -> some View {
        modifier(VerseTextStyle())
    }
    
    func verseNumberStyle() -> some View {
        modifier(VerseNumberStyle())
    }
    
    func headingStyle() -> some View {
        modifier(HeadingStyle())
    }
}




