//
//  ReadingPreset.swift
//  Bible v1
//
//  Reading presets for one-tap customization
//

import Foundation
import SwiftUI
import Combine

/// A reading preset that bundles font, size, spacing, and theme settings
struct ReadingPreset: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let fontFamily: String
    let textOffset: Double      // Reader text offset multiplier
    let lineSpacing: Double     // Line spacing multiplier
    let theme: AppTheme?        // Optional theme override
    let isCustom: Bool          // Whether this is a user-created preset
    
    init(
        id: String,
        name: String,
        icon: String,
        fontFamily: String,
        textOffset: Double,
        lineSpacing: Double,
        theme: AppTheme? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.fontFamily = fontFamily
        self.textOffset = textOffset
        self.lineSpacing = lineSpacing
        self.theme = theme
        self.isCustom = isCustom
    }
    
    // MARK: - Built-in Presets
    
    static let builtIn: [ReadingPreset] = [
        ReadingPreset(
            id: "study",
            name: "Study",
            icon: "book.fill",
            fontFamily: "serif",
            textOffset: 1.0,
            lineSpacing: 1.6,
            theme: .light
        ),
        ReadingPreset(
            id: "night",
            name: "Night",
            icon: "moon.fill",
            fontFamily: "georgia",
            textOffset: 1.1,
            lineSpacing: 1.5,
            theme: .dark
        ),
        ReadingPreset(
            id: "largePrint",
            name: "Large Print",
            icon: "textformat.size.larger",
            fontFamily: "georgia",
            textOffset: 1.5,
            lineSpacing: 1.8,
            theme: nil
        ),
        ReadingPreset(
            id: "minimal",
            name: "Minimal",
            icon: "text.alignleft",
            fontFamily: "system",
            textOffset: 0.95,
            lineSpacing: 1.3,
            theme: nil
        ),
        ReadingPreset(
            id: "sepia",
            name: "Classic",
            icon: "book.closed.fill",
            fontFamily: "palatino",
            textOffset: 1.05,
            lineSpacing: 1.5,
            theme: .sepia
        )
    ]
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, fontFamily, textOffset, lineSpacing, theme, isCustom
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        fontFamily = try container.decode(String.self, forKey: .fontFamily)
        textOffset = try container.decode(Double.self, forKey: .textOffset)
        lineSpacing = try container.decode(Double.self, forKey: .lineSpacing)
        
        if let themeRaw = try container.decodeIfPresent(String.self, forKey: .theme) {
            theme = AppTheme(rawValue: themeRaw)
        } else {
            theme = nil
        }
        
        isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(fontFamily, forKey: .fontFamily)
        try container.encode(textOffset, forKey: .textOffset)
        try container.encode(lineSpacing, forKey: .lineSpacing)
        try container.encodeIfPresent(theme?.rawValue, forKey: .theme)
        try container.encode(isCustom, forKey: .isCustom)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: ReadingPreset, rhs: ReadingPreset) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preset Storage Service

/// Manages custom reading presets
@MainActor
class ReadingPresetStore: ObservableObject {
    static let shared = ReadingPresetStore()
    
    @Published var customPresets: [ReadingPreset] = []
    
    private let customPresetsKey = "customReadingPresets"
    
    /// All available presets (built-in + custom)
    var allPresets: [ReadingPreset] {
        ReadingPreset.builtIn + customPresets
    }
    
    private init() {
        loadCustomPresets()
    }
    
    // MARK: - Persistence
    
    private func loadCustomPresets() {
        guard let data = UserDefaults.standard.data(forKey: customPresetsKey),
              let presets = try? JSONDecoder().decode([ReadingPreset].self, from: data) else {
            return
        }
        customPresets = presets
    }
    
    private func saveCustomPresets() {
        guard let data = try? JSONEncoder().encode(customPresets) else { return }
        UserDefaults.standard.set(data, forKey: customPresetsKey)
    }
    
    // MARK: - CRUD
    
    /// Create a new custom preset from current settings
    func createPreset(
        name: String,
        icon: String,
        from settings: SettingsStore
    ) -> ReadingPreset {
        let preset = ReadingPreset(
            id: UUID().uuidString,
            name: name,
            icon: icon,
            fontFamily: settings.readerFontFamily.rawValue,
            textOffset: settings.readerTextOffset,
            lineSpacing: settings.readerLineSpacing,
            theme: settings.selectedTheme,
            isCustom: true
        )
        customPresets.append(preset)
        saveCustomPresets()
        return preset
    }
    
    /// Update an existing custom preset
    func updatePreset(_ preset: ReadingPreset, with settings: SettingsStore) {
        guard preset.isCustom,
              let index = customPresets.firstIndex(where: { $0.id == preset.id }) else {
            return
        }
        
        let updated = ReadingPreset(
            id: preset.id,
            name: preset.name,
            icon: preset.icon,
            fontFamily: settings.readerFontFamily.rawValue,
            textOffset: settings.readerTextOffset,
            lineSpacing: settings.readerLineSpacing,
            theme: settings.selectedTheme,
            isCustom: true
        )
        customPresets[index] = updated
        saveCustomPresets()
    }
    
    /// Delete a custom preset
    func deletePreset(_ preset: ReadingPreset) {
        guard preset.isCustom else { return }
        customPresets.removeAll { $0.id == preset.id }
        saveCustomPresets()
    }
    
    /// Find a preset by ID
    func preset(withId id: String) -> ReadingPreset? {
        allPresets.first { $0.id == id }
    }
}

