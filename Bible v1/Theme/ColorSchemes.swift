//
//  ColorSchemes.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// Color definitions for the app
struct AppColors {
    
    // MARK: - Brand Colors
    
    static let primary = Color("PrimaryColor", bundle: nil)
    static let secondary = Color("SecondaryColor", bundle: nil)
    
    // MARK: - Semantic Colors
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // MARK: - Highlight Colors
    
    static let highlightYellow = Color.yellow.opacity(0.4)
    static let highlightGreen = Color.green.opacity(0.4)
    static let highlightBlue = Color.blue.opacity(0.4)
    static let highlightPink = Color.pink.opacity(0.4)
    static let highlightPurple = Color.teal.opacity(0.4)  // Previously purple, now teal for theme consistency
    static let highlightOrange = Color.orange.opacity(0.4)
    
    // MARK: - Sepia Theme Colors
    
    struct Sepia {
        static let background = Color(red: 0.96, green: 0.93, blue: 0.87)
        static let cardBackground = Color(red: 0.94, green: 0.90, blue: 0.82)
        static let text = Color(red: 0.24, green: 0.20, blue: 0.15)
        static let secondaryText = Color(red: 0.45, green: 0.40, blue: 0.32)
        static let accent = Color(red: 0.55, green: 0.35, blue: 0.20)
        static let divider = Color(red: 0.85, green: 0.80, blue: 0.70)
    }
    
    // MARK: - Dark Theme Colors
    
    struct Dark {
        static let background = Color(red: 0.11, green: 0.11, blue: 0.12)
        static let cardBackground = Color(red: 0.17, green: 0.17, blue: 0.18)
        static let text = Color(red: 0.92, green: 0.92, blue: 0.92)
        static let secondaryText = Color(red: 0.60, green: 0.60, blue: 0.60)
        static let accent = Color(red: 0.40, green: 0.60, blue: 0.90)
        static let divider = Color(red: 0.25, green: 0.25, blue: 0.27)
    }
    
    // MARK: - Light Theme Colors
    
    struct Light {
        static let background = Color(red: 0.99, green: 0.99, blue: 0.99)
        static let cardBackground = Color(red: 0.96, green: 0.96, blue: 0.97)
        static let text = Color(red: 0.12, green: 0.12, blue: 0.12)
        static let secondaryText = Color(red: 0.45, green: 0.45, blue: 0.45)
        static let accent = Color(red: 0.20, green: 0.45, blue: 0.75)
        static let divider = Color(red: 0.88, green: 0.88, blue: 0.88)
    }
}

// MARK: - Color Extension

extension Color {
    /// Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}




