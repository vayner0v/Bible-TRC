//
//  SavedConfigEntity.swift
//  Bible v1 Widgets
//
//  Entity for saved widget configurations from the app
//

import AppIntents
import SwiftUI

/// Entity representing a saved widget configuration from the main app
struct SavedConfigEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Saved Widget Style"
    static var defaultQuery = SavedConfigEntityQuery()
    
    var id: String
    var name: String
    var widgetType: String
    var presetId: String?
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

/// Query for saved widget configurations from App Group
struct SavedConfigEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SavedConfigEntity] {
        let allConfigs = fetchSavedConfigs()
        return allConfigs.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [SavedConfigEntity] {
        fetchSavedConfigs()
    }
    
    func defaultResult() async -> SavedConfigEntity? {
        fetchSavedConfigs().first
    }
    
    private func fetchSavedConfigs() -> [SavedConfigEntity] {
        let configs = WidgetDataProvider.shared.fetchWidgetConfigs()
        return configs.map { config in
            SavedConfigEntity(
                id: config.id,
                name: config.name,
                widgetType: config.widgetType,
                presetId: config.presetId
            )
        }
    }
}

// MARK: - Style Preset Extensions

extension StylePresetEntity {
    /// Get style config for a saved config, falling back to preset or default
    static func from(savedConfig: SavedConfigEntity?) -> StylePresetEntity {
        guard let config = savedConfig else {
            return .system
        }
        
        // If the saved config has a preset ID, use that preset
        if let presetId = config.presetId,
           let preset = StylePresetEntity.allPresets.first(where: { $0.id == presetId }) {
            return preset
        }
        
        // Otherwise fall back to system
        return .system
    }
}

