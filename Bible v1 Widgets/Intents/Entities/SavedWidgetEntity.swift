//
//  SavedWidgetEntity.swift
//  Bible v1 Widgets
//
//  Entity for saved widget projects from Widget Studio
//

import AppIntents
import SwiftUI

/// Entity representing a saved widget project from Widget Studio
struct SavedWidgetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "My Widget"
    static var defaultQuery = SavedWidgetEntityQuery()
    
    var id: String
    var name: String
    var widgetType: String
    var size: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(widgetType) • \(size)")
    }
    
    /// Default widget when none are saved
    static let defaultWidget = SavedWidgetEntity(
        id: "default",
        name: "Default Style",
        widgetType: "Verse of Day",
        size: "Medium"
    )
}

/// Query for saved widget projects from App Group
struct SavedWidgetEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SavedWidgetEntity] {
        let allWidgets = fetchSavedWidgets()
        return allWidgets.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [SavedWidgetEntity] {
        fetchSavedWidgets()
    }
    
    func defaultResult() async -> SavedWidgetEntity? {
        fetchSavedWidgets().first ?? .defaultWidget
    }
    
    /// Fetch saved widgets from App Group
    private func fetchSavedWidgets() -> [SavedWidgetEntity] {
        guard let userDefaults = UserDefaults(suiteName: WidgetAppGroup.suiteName) else {
            return [.defaultWidget]
        }
        
        // Try to load from widget_projects folder
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: WidgetAppGroup.suiteName) else {
            return [.defaultWidget]
        }
        
        let projectsFolder = containerURL.appendingPathComponent("widget_projects")
        let indexURL = projectsFolder.appendingPathComponent("index.json")
        
        // Load project index
        guard let indexData = try? Data(contentsOf: indexURL),
              let index = try? JSONDecoder().decode(ProjectIndexStorage.self, from: indexData) else {
            // Fall back to legacy widget configs
            return fetchLegacyConfigs(from: userDefaults)
        }
        
        // Load each project
        var entities: [SavedWidgetEntity] = []
        
        for projectId in index.projectIds {
            let projectURL = projectsFolder.appendingPathComponent("\(projectId.uuidString).json")
            if let projectData = try? Data(contentsOf: projectURL),
               let project = try? JSONDecoder().decode(WidgetProjectStorage.self, from: projectData) {
                entities.append(SavedWidgetEntity(
                    id: project.id.uuidString,
                    name: project.name,
                    widgetType: project.widgetType,
                    size: project.size
                ))
            }
        }
        
        if entities.isEmpty {
            return [.defaultWidget]
        }
        
        return entities
    }
    
    /// Fetch legacy widget configs
    private func fetchLegacyConfigs(from userDefaults: UserDefaults) -> [SavedWidgetEntity] {
        let configs = WidgetDataProvider.shared.fetchWidgetConfigs()
        
        if configs.isEmpty {
            return [.defaultWidget]
        }
        
        return configs.map { config in
            SavedWidgetEntity(
                id: config.id,
                name: config.name,
                widgetType: config.widgetType,
                size: config.size
            )
        }
    }
}

// MARK: - Storage Types (Minimal for decoding)

/// Minimal project index for widget extension
private struct ProjectIndexStorage: Codable {
    var projectIds: [UUID]
    var lastModified: Date
}

/// Minimal project storage for widget extension
private struct WidgetProjectStorage: Codable {
    let id: UUID
    var name: String
    var widgetType: String
    var size: String
}




