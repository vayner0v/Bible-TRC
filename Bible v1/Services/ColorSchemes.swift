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
    
    // MARK: - Premium Theme: Velvet Light
    // Luxury, editorial, "black tie" — warm neutrals + brass/gold accents
    
    struct VelvetLight {
        static let background = Color(hex: "F7F4EF")           // ivory paper
        static let surface = Color(hex: "FFFFFF")
        static let surfaceElevated = Color(hex: "F1ECE4")
        static let text = Color(hex: "151515")
        static let textMuted = Color(hex: "5D5A54")
        static let border = Color(hex: "1A1A1A").opacity(0.10) // 10% black
        static let primary = Color(hex: "8A5D00")              // deep amber CTA
        static let onPrimary = Color(hex: "FFFFFF")
        static let accent = Color(hex: "C9A24B")               // brass highlight
        static let link = Color(hex: "6B4B00")
        static let success = Color(hex: "1F8A70")
        static let warning = Color(hex: "B45309")
        static let error = Color(hex: "B42318")
        
        // Convenience aliases for ThemeManager compatibility
        static let cardBackground = surface
        static let secondaryText = textMuted
        static let divider = border
    }
    
    // MARK: - Premium Theme: Velvet Dark
    // Soft black with gold accents - super readable
    
    struct VelvetDark {
        static let background = Color(hex: "0B0C10")           // soft black (not pure #000)
        static let surface = Color(hex: "12141A")
        static let surfaceElevated = Color(hex: "1A1D26")
        static let text = Color(hex: "F4F3F0")
        static let textMuted = Color(hex: "B8B3AA")
        static let border = Color(hex: "FFFFFF").opacity(0.12) // 12% white
        static let primary = Color(hex: "C9A24B")              // gold CTA
        static let onPrimary = Color(hex: "0B0C10")            // dark text on gold
        static let accent = Color(hex: "D7B566")
        static let link = Color(hex: "E3C47E")
        static let success = Color(hex: "2DD4BF")
        static let warning = Color(hex: "FBBF24")
        static let error = Color(hex: "FF5C5C")
        
        // Convenience aliases
        static let cardBackground = surface
        static let secondaryText = textMuted
        static let divider = border
    }
    
    // MARK: - Premium Theme: Frosted Glass Light
    // iOS-style translucency / glassmorphism: blur + subtle gradient + crisp typography
    
    struct FrostedGlassLight {
        static let background = Color(hex: "F6F8FF")
        static let bgGradientA = Color(hex: "F2F7FF")
        static let bgGradientB = Color(hex: "F7F2FF")
        static let glassSurface = Color(hex: "FFFFFF").opacity(0.72)  // 72% white
        static let glassElevated = Color(hex: "FFFFFF").opacity(0.80) // 80% white
        static let text = Color(hex: "0B1220")
        static let textMuted = Color(hex: "3C4A66")
        static let border = Color(hex: "0B1220").opacity(0.10)        // 10% ink
        static let primary = Color(hex: "0069FF")                      // accessible blue
        static let onPrimary = Color(hex: "FFFFFF")
        static let accent = Color(hex: "0A84FF")                       // shine
        static let link = Color(hex: "0069FF")
        static let success = Color(hex: "168A45")
        static let warning = Color(hex: "B45309")
        static let error = Color(hex: "D92D20")
        
        // Background blur intensity for glass effect
        static let blurRadius: CGFloat = 20
        
        // Convenience aliases
        static let surface = glassSurface
        static let surfaceElevated = glassElevated
        static let cardBackground = glassSurface
        static let secondaryText = textMuted
        static let divider = border
    }
    
    // MARK: - Premium Theme: Frosted Glass Dark
    // Dark translucent surfaces with depth
    
    struct FrostedGlassDark {
        static let background = Color(hex: "0A1020")
        static let bgGradientA = Color(hex: "060B14")
        static let bgGradientB = Color(hex: "121A2B")
        static let glassSurface = Color(hex: "FFFFFF").opacity(0.08)  // 8% white
        static let glassElevated = Color(hex: "FFFFFF").opacity(0.12) // 12% white
        static let text = Color(hex: "EAF0FF")
        static let textMuted = Color(hex: "A9B4D6")
        static let border = Color(hex: "FFFFFF").opacity(0.18)        // 18% white
        static let primary = Color(hex: "0069FF")
        static let onPrimary = Color(hex: "FFFFFF")
        static let accent = Color(hex: "0A84FF")
        static let link = Color(hex: "0A84FF")
        static let success = Color(hex: "32D74B")
        static let warning = Color(hex: "FF9F0A")
        static let error = Color(hex: "FF453A")
        
        // Background blur intensity
        static let blurRadius: CGFloat = 24
        
        // Convenience aliases
        static let surface = glassSurface
        static let surfaceElevated = glassElevated
        static let cardBackground = glassSurface
        static let secondaryText = textMuted
        static let divider = border
    }
    
    // MARK: - Premium Theme: Aurora Light
    // Deep ink background + teal/violet aurora accents - visually memorable
    
    struct AuroraLight {
        static let background = Color(hex: "FBFAFF")
        static let surface = Color(hex: "FFFFFF")
        static let surfaceElevated = Color(hex: "F3F1FF")
        static let text = Color(hex: "16112A")
        static let textMuted = Color(hex: "4F3B72")
        static let border = Color(hex: "16112A").opacity(0.10)
        static let primary = Color(hex: "0F766E")                      // accessible teal CTA
        static let onPrimary = Color(hex: "FFFFFF")
        static let secondary = Color(hex: "7C3AED")                    // violet button
        static let onSecondary = Color(hex: "FFFFFF")
        static let accentTeal = Color(hex: "14B8A6")
        static let accentViolet = Color(hex: "A855F7")
        static let link = Color(hex: "0F766E")
        static let success = Color(hex: "0F766E")
        static let warning = Color(hex: "B45309")
        static let error = Color(hex: "D92D20")
        
        // Aurora gradient colors
        static let gradientStart = Color(hex: "14B8A6")
        static let gradientEnd = Color(hex: "A855F7")
        
        // Convenience aliases
        static let accent = accentTeal
        static let cardBackground = surface
        static let secondaryText = textMuted
        static let divider = border
    }
    
    // MARK: - Premium Theme: Aurora Dark
    // Deep dark with vibrant teal/violet accents
    
    struct AuroraDark {
        static let background = Color(hex: "070612")
        static let surface = Color(hex: "121024")
        static let surfaceElevated = Color(hex: "1A1633")
        static let text = Color(hex: "F6F4FF")
        static let textMuted = Color(hex: "B8B0D6")
        static let border = Color(hex: "FFFFFF").opacity(0.12)
        static let primary = Color(hex: "0F766E")
        static let onPrimary = Color(hex: "FFFFFF")
        static let secondary = Color(hex: "7C3AED")
        static let onSecondary = Color(hex: "FFFFFF")
        static let accentTeal = Color(hex: "14B8A6")
        static let accentViolet = Color(hex: "A855F7")
        static let link = Color(hex: "14B8A6")
        static let success = Color(hex: "2DD4BF")
        static let warning = Color(hex: "FBBF24")
        static let error = Color(hex: "FF5C5C")
        
        // Aurora gradient colors
        static let gradientStart = Color(hex: "14B8A6")
        static let gradientEnd = Color(hex: "A855F7")
        
        // Convenience aliases
        static let accent = accentTeal
        static let cardBackground = surface
        static let secondaryText = textMuted
        static let divider = border
    }
}

// MARK: - Custom Theme Colors (for Theme Studio)

/// Dynamic color configuration for user-customized themes
struct CustomThemeColors {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let text: Color
    let textMuted: Color
    let border: Color
    let primary: Color
    let onPrimary: Color
    let accent: Color
    let success: Color
    let warning: Color
    let error: Color
    
    /// Default custom theme (dark mode base)
    static let `default` = CustomThemeColors(
        background: Color(hex: "0F0F12"),
        surface: Color(hex: "1A1A1F"),
        surfaceElevated: Color(hex: "242429"),
        text: Color(hex: "F5F5F7"),
        textMuted: Color(hex: "A0A0A8"),
        border: Color(hex: "FFFFFF").opacity(0.12),
        primary: Color(hex: "0A84FF"),
        onPrimary: Color(hex: "FFFFFF"),
        accent: Color(hex: "0A84FF"),
        success: Color(hex: "32D74B"),
        warning: Color(hex: "FF9F0A"),
        error: Color(hex: "FF453A")
    )
    
    /// Generate colors from user choices
    static func generate(
        accentColor: Color,
        neutralTemperature: Double, // 0 = cool, 1 = warm
        isDarkMode: Bool,
        contrastLevel: ContrastLevel,
        glassIntensity: GlassIntensity
    ) -> CustomThemeColors {
        // Calculate on-primary based on accent luminance
        let onPrimary = accentColor.contrastingTextColor()
        
        // Generate background based on temperature and mode
        let background: Color
        let surface: Color
        let surfaceElevated: Color
        let text: Color
        let textMuted: Color
        let border: Color
        
        if isDarkMode {
            // Dark mode backgrounds
            let warmth = neutralTemperature * 0.03
            background = Color(
                red: 0.04 + warmth,
                green: 0.04 + (warmth * 0.5),
                blue: 0.05 - (warmth * 0.5)
            )
            surface = Color(
                red: 0.08 + warmth,
                green: 0.08 + (warmth * 0.5),
                blue: 0.09 - (warmth * 0.5)
            )
            surfaceElevated = Color(
                red: 0.12 + warmth,
                green: 0.12 + (warmth * 0.5),
                blue: 0.13 - (warmth * 0.5)
            )
            text = contrastLevel == .high ? Color(hex: "FFFFFF") : Color(hex: "F5F5F7")
            textMuted = contrastLevel == .high ? Color(hex: "C0C0C8") : Color(hex: "A0A0A8")
            border = Color.white.opacity(contrastLevel == .high ? 0.18 : 0.12)
        } else {
            // Light mode backgrounds
            let warmth = neutralTemperature * 0.04
            background = Color(
                red: 0.98 + (warmth * 0.02),
                green: 0.98 - (warmth * 0.02),
                blue: 0.99 - (warmth * 0.04)
            )
            surface = Color.white
            surfaceElevated = Color(
                red: 0.96 + (warmth * 0.02),
                green: 0.96 - (warmth * 0.02),
                blue: 0.97 - (warmth * 0.04)
            )
            text = contrastLevel == .high ? Color(hex: "000000") : Color(hex: "1A1A1F")
            textMuted = contrastLevel == .high ? Color(hex: "404048") : Color(hex: "606068")
            border = Color.black.opacity(contrastLevel == .high ? 0.15 : 0.10)
        }
        
        // Apply glass effect to surface if enabled
        let finalSurface: Color
        let finalSurfaceElevated: Color
        
        switch glassIntensity {
        case .off:
            finalSurface = surface
            finalSurfaceElevated = surfaceElevated
        case .subtle:
            finalSurface = isDarkMode ? surface.opacity(0.85) : surface.opacity(0.92)
            finalSurfaceElevated = isDarkMode ? surfaceElevated.opacity(0.90) : surfaceElevated.opacity(0.95)
        case .full:
            finalSurface = isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.72)
            finalSurfaceElevated = isDarkMode ? Color.white.opacity(0.12) : Color.white.opacity(0.80)
        }
        
        return CustomThemeColors(
            background: background,
            surface: finalSurface,
            surfaceElevated: finalSurfaceElevated,
            text: text,
            textMuted: textMuted,
            border: border,
            primary: accentColor,
            onPrimary: onPrimary,
            accent: accentColor,
            success: Color(hex: isDarkMode ? "32D74B" : "168A45"),
            warning: Color(hex: isDarkMode ? "FF9F0A" : "B45309"),
            error: Color(hex: isDarkMode ? "FF453A" : "D92D20")
        )
    }
}

/// Contrast level for custom themes
enum ContrastLevel: String, CaseIterable, Codable, Identifiable {
    case normal = "Normal"
    case high = "High"
    
    var id: String { rawValue }
}

/// Glass/blur intensity for custom themes
enum GlassIntensity: String, CaseIterable, Codable, Identifiable {
    case off = "Off"
    case subtle = "Subtle"
    case full = "Full"
    
    var id: String { rawValue }
    
    var blurRadius: CGFloat {
        switch self {
        case .off: return 0
        case .subtle: return 12
        case .full: return 24
        }
    }
}

// MARK: - Color Extension

extension Color {
    /// Calculate a contrasting text color (white or black) based on luminance
    func contrastingTextColor() -> Color {
        // Approximate luminance calculation
        // This is a simplified version - in production you'd extract RGB components
        // For now, default to white which works for most accent colors
        return .white
    }
    
    /// Adjust brightness of a color
    func adjustBrightness(by amount: Double) -> Color {
        // This is a placeholder - proper implementation would use UIColor conversion
        return self.opacity(1.0 - amount)
    }
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




