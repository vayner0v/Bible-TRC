//
//  Color+Extensions.swift
//  Bible v1
//
//  Color utilities for Journal theme colors
//  Note: init(hex:) is defined in ColorSchemes.swift
//

import SwiftUI

extension Color {
    
    /// Convert Color to hex string
    var hexString: String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r: CGFloat = components.count > 0 ? components[0] : 0
        let g: CGFloat = components.count > 1 ? components[1] : 0
        let b: CGFloat = components.count > 2 ? components[2] : 0
        
        return String(
            format: "%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}

// MARK: - Routine Journal Theme Colors

extension Color {
    
    /// Journaling aesthetic color palette
    struct Journal {
        /// Warm cream paper background
        static let paper = Color(hex: "FAF8F5")
        
        /// Slightly darker cream for cards
        static let cardBackground = Color(hex: "F5F2ED")
        
        /// Even darker for elevated surfaces
        static let elevatedCard = Color(hex: "EDE8E0")
        
        /// Sepia tone for borders and dividers
        static let sepia = Color(hex: "D4C4A8")
        
        /// Warm brown for text accents
        static let warmBrown = Color(hex: "8B7355")
        
        /// Deep brown for primary text
        static let inkBrown = Color(hex: "4A3728")
        
        /// Muted text color
        static let mutedText = Color(hex: "8C7B6B")
        
        /// Morning routine colors
        struct Morning {
            static let primary = Color(hex: "D4883A")
            static let secondary = Color(hex: "E8A84C")
            static let background = Color(hex: "FFF8E7")
            static let gradientStart = Color(hex: "FFF8E7")
            static let gradientEnd = Color(hex: "FFE4C4")
        }
        
        /// Evening routine colors
        struct Evening {
            static let primary = Color(hex: "7B68A6")
            static let secondary = Color(hex: "9B8BC4")
            static let background = Color(hex: "F0EBF5")
            static let gradientStart = Color(hex: "E8E4F0")
            static let gradientEnd = Color(hex: "D4C4E8")
        }
        
        /// Anytime routine colors
        struct Anytime {
            static let primary = Color(hex: "8B7355")
            static let secondary = Color(hex: "A08060")
            static let background = Color(hex: "F5F2ED")
            static let gradientStart = Color(hex: "F5F2ED")
            static let gradientEnd = Color(hex: "E8E4DC")
        }
        
        /// Get colors for a specific routine mode
        static func colors(for mode: RoutineMode) -> (primary: Color, secondary: Color, background: Color, gradientStart: Color, gradientEnd: Color) {
            switch mode {
            case .morning:
                return (Morning.primary, Morning.secondary, Morning.background, Morning.gradientStart, Morning.gradientEnd)
            case .evening:
                return (Evening.primary, Evening.secondary, Evening.background, Evening.gradientStart, Evening.gradientEnd)
            case .anytime:
                return (Anytime.primary, Anytime.secondary, Anytime.background, Anytime.gradientStart, Anytime.gradientEnd)
            }
        }
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {
    
    /// Create a journal-style gradient for routine backgrounds
    static func journalGradient(for mode: RoutineMode) -> LinearGradient {
        let colors = Color.Journal.colors(for: mode)
        return LinearGradient(
            colors: [colors.gradientStart, colors.gradientEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Paper texture overlay gradient
    static var paperTexture: LinearGradient {
        LinearGradient(
            colors: [
                Color.Journal.paper.opacity(0.9),
                Color.Journal.cardBackground.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

