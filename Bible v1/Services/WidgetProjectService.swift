//
//  WidgetProjectService.swift
//  Bible v1
//
//  Service for persisting WidgetProject with full layer data
//

import Foundation
import SwiftUI
import WidgetKit
import Combine

/// Service for managing widget projects with full layer persistence
@MainActor
final class WidgetProjectService: ObservableObject {
    static let shared = WidgetProjectService()
    
    // MARK: - Published Properties
    
    @Published private(set) var projects: [WidgetProject] = []
    @Published private(set) var isLoading = false
    @Published var saveError: String?
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var containerURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.suiteName)
    }
    
    private var projectsFolder: URL? {
        guard let container = containerURL else { return nil }
        return container.appendingPathComponent("widget_projects")
    }
    
    private var indexURL: URL? {
        guard let folder = projectsFolder else { return nil }
        return folder.appendingPathComponent("index.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        setupProjectsFolder()
        loadProjects()
    }
    
    // MARK: - Public Methods
    
    /// Save a widget project
    func saveProject(_ project: WidgetProject) {
        var updatedProject = project
        updatedProject.modifiedAt = Date()
        
        // Update in memory
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = updatedProject
        } else {
            projects.insert(updatedProject, at: 0)
        }
        
        // Persist to disk
        persistProject(updatedProject)
        saveIndex()
        
        // Also sync to legacy WidgetConfig for widget extension compatibility
        syncToLegacyConfig(updatedProject)
        
        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Delete a project
    func deleteProject(_ project: WidgetProject) {
        deleteProject(withId: project.id)
    }
    
    /// Delete a project by ID
    func deleteProject(withId id: UUID) {
        projects.removeAll { $0.id == id }
        
        // Remove from disk
        if let folder = projectsFolder {
            let fileURL = folder.appendingPathComponent("\(id.uuidString).json")
            try? fileManager.removeItem(at: fileURL)
        }
        
        saveIndex()
        
        // Also remove from legacy configs
        WidgetDataService.shared.deleteConfig(withId: id)
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Get project by ID
    func project(withId id: UUID) -> WidgetProject? {
        projects.first { $0.id == id }
    }
    
    /// Get projects for a specific widget type
    func projects(for type: BibleWidgetType) -> [WidgetProject] {
        projects.filter { $0.widgetType == type }
    }
    
    /// Get recent projects
    var recentProjects: [WidgetProject] {
        Array(projects.sorted { $0.modifiedAt > $1.modifiedAt }.prefix(5))
    }
    
    /// Get favorite projects
    var favoriteProjects: [WidgetProject] {
        projects.filter { $0.isFavorite }
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ projectId: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[index].isFavorite.toggle()
        persistProject(projects[index])
        saveIndex()
    }
    
    /// Duplicate a project
    func duplicateProject(_ project: WidgetProject) -> WidgetProject {
        // Generate new IDs for all layers
        let duplicatedLayers = project.layers.map { layer in
            WidgetLayer(
                id: UUID(),
                name: layer.name,
                element: layer.element,
                frame: layer.frame,
                style: layer.style,
                zIndex: layer.zIndex,
                isVisible: layer.isVisible,
                isLocked: layer.isLocked,
                opacity: layer.opacity,
                blendMode: layer.blendMode
            )
        }
        
        let duplicate = WidgetProject(
            id: UUID(),
            name: "\(project.name) Copy",
            widgetType: project.widgetType,
            size: project.size,
            layers: duplicatedLayers,
            background: project.background,
            isFavorite: false,
            templateId: project.templateId
        )
        
        projects.insert(duplicate, at: 0)
        persistProject(duplicate)
        saveIndex()
        
        return duplicate
    }
    
    /// Rename a project
    func renameProject(_ projectId: UUID, to newName: String) {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[index].name = newName
        projects[index].modifiedAt = Date()
        persistProject(projects[index])
        saveIndex()
    }
    
    // MARK: - Private Methods
    
    private func setupProjectsFolder() {
        guard let folder = projectsFolder else { return }
        
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }
    
    private func loadProjects() {
        isLoading = true
        
        guard let indexURL = indexURL,
              let data = try? Data(contentsOf: indexURL),
              let index = try? decoder.decode(ProjectIndex.self, from: data) else {
            isLoading = false
            return
        }
        
        // Load each project file
        var loadedProjects: [WidgetProject] = []
        
        for id in index.projectIds {
            if let project = loadProject(withId: id) {
                loadedProjects.append(project)
            }
        }
        
        // Sort by modified date
        projects = loadedProjects.sorted { $0.modifiedAt > $1.modifiedAt }
        isLoading = false
    }
    
    private func loadProject(withId id: UUID) -> WidgetProject? {
        guard let folder = projectsFolder else { return nil }
        let fileURL = folder.appendingPathComponent("\(id.uuidString).json")
        
        guard let data = try? Data(contentsOf: fileURL),
              let project = try? decoder.decode(WidgetProject.self, from: data) else {
            return nil
        }
        
        return project
    }
    
    private func persistProject(_ project: WidgetProject) {
        guard let folder = projectsFolder else {
            saveError = "Storage unavailable"
            return
        }
        
        let fileURL = folder.appendingPathComponent("\(project.id.uuidString).json")
        
        do {
            let data = try encoder.encode(project)
            try data.write(to: fileURL)
            saveError = nil
        } catch {
            saveError = "Failed to save project: \(error.localizedDescription)"
        }
    }
    
    private func saveIndex() {
        guard let indexURL = indexURL else { return }
        
        let index = ProjectIndex(
            projectIds: projects.map { $0.id },
            lastModified: Date()
        )
        
        if let data = try? encoder.encode(index) {
            try? data.write(to: indexURL)
        }
    }
    
    /// Sync project to legacy WidgetConfig for widget extension compatibility
    private func syncToLegacyConfig(_ project: WidgetProject) {
        // Convert project background to legacy format
        var background: WidgetBackgroundStyle
        
        switch project.background {
        case .solid(let fill):
            background = .solid(color: fill.color)
        case .gradient(let fill):
            let colors = fill.stops.map { $0.color }
            background = .gradient(colors: colors, startPoint: fill.startPoint, endPoint: fill.endPoint)
        case .image(let fill):
            background = .image(imageName: fill.imageId, opacity: 1.0)
        case .glassmorphism:
            background = .solid(color: CodableColor(red: 1, green: 1, blue: 1, opacity: 0.7))
        }
        
        // Create legacy config with project metadata
        let config = WidgetConfig(
            id: project.id,
            widgetType: project.widgetType,
            size: project.size,
            name: project.name,
            background: background
        )
        
        // Save to legacy service
        if WidgetDataService.shared.widgetConfigs.contains(where: { $0.id == project.id }) {
            WidgetDataService.shared.updateConfig(config)
        } else {
            WidgetDataService.shared.addConfig(config)
        }
    }
    
    // MARK: - Migration from Legacy Configs
    
    /// Migrate legacy WidgetConfigs to WidgetProjects (one-time operation)
    func migrateFromLegacyConfigs() {
        let legacyConfigs = WidgetDataService.shared.widgetConfigs
        
        for config in legacyConfigs {
            // Skip if already migrated
            if projects.contains(where: { $0.id == config.id }) {
                continue
            }
            
            let project = convertLegacyConfig(config)
            projects.append(project)
            persistProject(project)
        }
        
        saveIndex()
    }
    
    private func convertLegacyConfig(_ config: WidgetConfig) -> WidgetProject {
        // Convert background
        var background: ProjectBackground
        
        switch config.background {
        case .solid(let color):
            background = .solid(SolidFill(color: color))
        case .gradient(let colors, let start, let end):
            let stops = colors.enumerated().map { index, color in
                GradientStop(color: color, location: Double(index) / Double(max(colors.count - 1, 1)))
            }
            background = .gradient(GradientFill(
                type: .linear,
                stops: stops,
                startPoint: start,
                endPoint: end
            ))
        case .pattern(_, let baseColor):
            background = .solid(SolidFill(color: baseColor))
        case .image(let imageName, _):
            background = .image(ImageFill(imageId: imageName))
        }
        
        // Create default layers based on widget type
        var layers: [WidgetLayer] = []
        
        switch config.widgetType {
        case .verseOfDay, .scriptureQuote:
            layers.append(WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: config.bodyStyle.family.rawValue,
                        fontSize: Double(config.bodyStyle.size.pointSize),
                        textColor: config.bodyStyle.color
                    )
                )),
                frame: LayerFrame(x: 8, y: 25, width: 84, height: 50, rotation: 0),
                zIndex: 0
            ))
            layers.append(WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: config.titleStyle.family.rawValue,
                        fontSize: Double(config.titleStyle.size.pointSize) * 0.8,
                        fontWeight: .semibold,
                        textColor: config.titleStyle.color
                    )
                )),
                frame: LayerFrame(x: 8, y: 80, width: 84, height: 12, rotation: 0),
                zIndex: 1
            ))
            
        case .readingProgress:
            layers.append(WidgetLayer(
                name: "Title",
                element: .text(TextElementConfig(
                    text: "Reading Progress",
                    fontId: config.titleStyle.family.rawValue,
                    fontSize: Double(config.titleStyle.size.pointSize),
                    fontWeight: .bold,
                    textColor: config.titleStyle.color
                )),
                frame: LayerFrame(x: 8, y: 10, width: 84, height: 15, rotation: 0),
                zIndex: 0
            ))
            layers.append(WidgetLayer(
                name: "Progress",
                element: .dataBinding(DataBindingConfig(
                    dataType: .readingProgress,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 28,
                        fontWeight: .bold,
                        textColor: config.bodyStyle.color
                    )
                )),
                frame: LayerFrame(x: 8, y: 40, width: 84, height: 30, rotation: 0),
                zIndex: 1
            ))
            
        default:
            layers.append(WidgetLayer(
                name: "Title",
                element: .text(TextElementConfig(
                    text: config.widgetType.displayName,
                    fontId: config.titleStyle.family.rawValue,
                    fontSize: Double(config.titleStyle.size.pointSize),
                    fontWeight: .semibold,
                    textColor: config.titleStyle.color
                )),
                frame: LayerFrame(x: 8, y: 10, width: 84, height: 15, rotation: 0),
                zIndex: 0
            ))
        }
        
        return WidgetProject(
            id: config.id,
            name: config.name,
            widgetType: config.widgetType,
            size: config.size,
            layers: layers,
            background: background,
            isFavorite: false
        )
    }
}

// MARK: - Project Index

private struct ProjectIndex: Codable {
    var projectIds: [UUID]
    var lastModified: Date
}

