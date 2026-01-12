//
//  StylePresetEntity.swift
//  Bible v1 Widgets
//
//  Style preset entity for widget configuration
//

import AppIntents
import SwiftUI

/// Entity representing a style preset for widget customization
struct StylePresetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Style Preset"
    static var defaultQuery = StylePresetEntityQuery()
    
    var id: String
    var name: String
    var description: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(description)")
    }
    
    // MARK: - Preset Definitions
    
    static let system = StylePresetEntity(
        id: "system",
        name: "System",
        description: "Follows your device's light/dark mode"
    )
    
    static let classicLight = StylePresetEntity(
        id: "classic_light",
        name: "Classic Light",
        description: "Clean white with accent color"
    )
    
    static let classicDark = StylePresetEntity(
        id: "classic_dark",
        name: "Classic Dark",
        description: "Dark mode with subtle gradients"
    )
    
    static let sepia = StylePresetEntity(
        id: "sepia_warmth",
        name: "Sepia Warmth",
        description: "Warm tones matching sepia theme"
    )
    
    static let minimal = StylePresetEntity(
        id: "minimal",
        name: "Minimal",
        description: "Ultra-clean, typography-focused"
    )
    
    static let gradientBliss = StylePresetEntity(
        id: "gradient_bliss",
        name: "Gradient Bliss",
        description: "Soft gradient backgrounds"
    )
    
    static let scriptureArt = StylePresetEntity(
        id: "scripture_art",
        name: "Scripture Art",
        description: "Decorative patterns with elegance"
    )
    
    static let midnightGold = StylePresetEntity(
        id: "midnight_gold",
        name: "Midnight Gold",
        description: "Luxurious dark with gold accents"
    )
    
    static let sunriseHope = StylePresetEntity(
        id: "sunrise_hope",
        name: "Sunrise Hope",
        description: "Warm sunrise gradients"
    )
    
    static let allPresets: [StylePresetEntity] = [
        .system,
        .classicLight,
        .classicDark,
        .sepia,
        .minimal,
        .gradientBliss,
        .scriptureArt,
        .midnightGold,
        .sunriseHope
    ]
}

/// Query for style presets
struct StylePresetEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [StylePresetEntity] {
        StylePresetEntity.allPresets.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [StylePresetEntity] {
        StylePresetEntity.allPresets
    }
    
    func defaultResult() async -> StylePresetEntity? {
        .system
    }
}

