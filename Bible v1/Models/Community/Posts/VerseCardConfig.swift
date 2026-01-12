//
//  VerseCardConfig.swift
//  Bible v1
//
//  Community Tab - Verse Card Configuration Model
//

import Foundation
import SwiftUI

/// Configuration for a customizable verse card
struct VerseCardConfig: Codable, Hashable {
    var templateId: String?
    var backgroundColor: String?
    var backgroundGradient: GradientConfig?
    var backgroundImageUrl: String?
    var textColor: String
    var fontFamily: String
    var fontSize: CGFloat
    var textAlignment: TextAlignmentOption
    var showReference: Bool
    var showTranslation: Bool
    var padding: CGFloat
    var cornerRadius: CGFloat
    var overlayOpacity: CGFloat
    
    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case backgroundColor = "background_color"
        case backgroundGradient = "background_gradient"
        case backgroundImageUrl = "background_image_url"
        case textColor = "text_color"
        case fontFamily = "font_family"
        case fontSize = "font_size"
        case textAlignment = "text_alignment"
        case showReference = "show_reference"
        case showTranslation = "show_translation"
        case padding
        case cornerRadius = "corner_radius"
        case overlayOpacity = "overlay_opacity"
    }
    
    static let `default` = VerseCardConfig(
        templateId: nil,
        backgroundColor: "#1a1a2e",
        backgroundGradient: nil,
        backgroundImageUrl: nil,
        textColor: "#ffffff",
        fontFamily: "Georgia",
        fontSize: 24,
        textAlignment: .center,
        showReference: true,
        showTranslation: true,
        padding: 32,
        cornerRadius: 16,
        overlayOpacity: 0
    )
    
    init(
        templateId: String? = nil,
        backgroundColor: String? = nil,
        backgroundGradient: GradientConfig? = nil,
        backgroundImageUrl: String? = nil,
        textColor: String = "#ffffff",
        fontFamily: String = "Georgia",
        fontSize: CGFloat = 24,
        textAlignment: TextAlignmentOption = .center,
        showReference: Bool = true,
        showTranslation: Bool = true,
        padding: CGFloat = 32,
        cornerRadius: CGFloat = 16,
        overlayOpacity: CGFloat = 0
    ) {
        self.templateId = templateId
        self.backgroundColor = backgroundColor
        self.backgroundGradient = backgroundGradient
        self.backgroundImageUrl = backgroundImageUrl
        self.textColor = textColor
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.textAlignment = textAlignment
        self.showReference = showReference
        self.showTranslation = showTranslation
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.overlayOpacity = overlayOpacity
    }
}

/// Gradient configuration for verse cards
struct GradientConfig: Codable, Hashable {
    let colors: [String]
    let startPoint: VerseCardGradientPoint
    let endPoint: VerseCardGradientPoint
    
    enum CodingKeys: String, CodingKey {
        case colors
        case startPoint = "start_point"
        case endPoint = "end_point"
    }
}

/// Gradient point options for verse cards
enum VerseCardGradientPoint: String, Codable {
    case topLeading = "top_leading"
    case top = "top"
    case topTrailing = "top_trailing"
    case leading = "leading"
    case center = "center"
    case trailing = "trailing"
    case bottomLeading = "bottom_leading"
    case bottom = "bottom"
    case bottomTrailing = "bottom_trailing"
    
    var unitPoint: UnitPoint {
        switch self {
        case .topLeading: return .topLeading
        case .top: return .top
        case .topTrailing: return .topTrailing
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        case .bottomLeading: return .bottomLeading
        case .bottom: return .bottom
        case .bottomTrailing: return .bottomTrailing
        }
    }
}

/// Text alignment options for verse cards
enum TextAlignmentOption: String, Codable, CaseIterable {
    case leading = "leading"
    case center = "center"
    case trailing = "trailing"
    
    var alignment: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    var displayName: String {
        switch self {
        case .leading: return "Left"
        case .center: return "Center"
        case .trailing: return "Right"
        }
    }
    
    var icon: String {
        switch self {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }
}

/// Pre-made verse card template
struct VerseCardTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let category: TemplateCategory
    let config: VerseCardConfig
    let previewImageUrl: String?
    let isPremium: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, config
        case previewImageUrl = "preview_image_url"
        case isPremium = "is_premium"
    }
    
    enum TemplateCategory: String, Codable, CaseIterable {
        case minimal = "minimal"
        case nature = "nature"
        case abstract = "abstract"
        case classic = "classic"
        case modern = "modern"
        case seasonal = "seasonal"
        
        var displayName: String {
            switch self {
            case .minimal: return "Minimal"
            case .nature: return "Nature"
            case .abstract: return "Abstract"
            case .classic: return "Classic"
            case .modern: return "Modern"
            case .seasonal: return "Seasonal"
            }
        }
    }
}

