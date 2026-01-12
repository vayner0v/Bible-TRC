//
//  WidgetProjectLoader.swift
//  Bible v1 Widgets
//
//  Loads saved widget project configurations for widget rendering
//

import Foundation
import SwiftUI

/// Loads saved widget projects from App Group storage
struct WidgetProjectLoader {
    static let shared = WidgetProjectLoader()
    
    private let fileManager = FileManager.default
    
    private var containerURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: WidgetAppGroup.suiteName)
    }
    
    private var projectsFolder: URL? {
        guard let container = containerURL else { return nil }
        return container.appendingPathComponent("widget_projects")
    }
    
}

// MARK: - Saved Project Data (Decodable)

/// Minimal project data needed for widget styling
struct SavedProjectData: Codable {
    let id: UUID
    var name: String
    var background: ProjectBackgroundData
    
    // Make layers optional and handle decoding failures gracefully
    var layers: [LayerData]?
    
    // Extra fields we don't need but must handle
    var widgetType: String?
    var size: String?
    var createdAt: Date?
    var modifiedAt: Date?
    var isFavorite: Bool?
    var templateId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, background, layers, widgetType, size, createdAt, modifiedAt, isFavorite, templateId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        background = try container.decode(ProjectBackgroundData.self, forKey: .background)
        
        // Ignore layers decoding errors - they're complex enums we don't fully need
        layers = try? container.decodeIfPresent([LayerData].self, forKey: .layers)
        
        widgetType = try? container.decodeIfPresent(String.self, forKey: .widgetType)
        size = try? container.decodeIfPresent(String.self, forKey: .size)
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        modifiedAt = try? container.decodeIfPresent(Date.self, forKey: .modifiedAt)
        isFavorite = try? container.decodeIfPresent(Bool.self, forKey: .isFavorite)
        templateId = try? container.decodeIfPresent(String.self, forKey: .templateId)
    }
    
    /// Decodes the ProjectBackground enum from main app
    enum ProjectBackgroundData: Codable {
        case solid(SolidFillData)
        case gradient(GradientFillData)
        case image(ImageFillData)
        case glassmorphism(GlassmorphismFillData)
        
        var solidFill: SolidFillData? {
            if case .solid(let fill) = self { return fill }
            return nil
        }
        
        var gradientFill: GradientFillData? {
            if case .gradient(let fill) = self { return fill }
            return nil
        }
        
        var imageFill: ImageFillData? {
            if case .image(let fill) = self { return fill }
            return nil
        }
        
        var glassmorphismFill: GlassmorphismFillData? {
            if case .glassmorphism(let fill) = self { return fill }
            return nil
        }
    }
    
    struct SolidFillData: Codable {
        let color: CodableColorData
        var opacity: Double?
    }
    
    struct GradientFillData: Codable {
        var type: String?
        var stops: [GradientStopData]
        var startPoint: String  // GradientPoint is a String enum
        var endPoint: String
        var angle: Double?
        
        var startUnitPoint: UnitPoint {
            GradientPointHelper.unitPoint(from: startPoint)
        }
        
        var endUnitPoint: UnitPoint {
            GradientPointHelper.unitPoint(from: endPoint)
        }
    }
    
    struct GradientStopData: Codable {
        let color: CodableColorData
        let location: Double
    }
    
    struct ImageFillData: Codable {
        var imageId: String
        var contentMode: String?
        var blurRadius: Double?
    }
    
    struct GlassmorphismFillData: Codable {
        var preset: String  // GlassmorphismPreset is a String enum
        var blurRadius: Double
        var tintColor: CodableColorData
        var tintOpacity: Double
        var noiseOpacity: Double?
        var borderOpacity: Double?
    }
    
    struct CodableColorData: Codable {
        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double
        
        var color: Color {
            Color(red: red, green: green, blue: blue, opacity: opacity)
        }
    }
    
    struct LayerData: Codable {
        var element: LayerElementData?
    }
    
    struct LayerElementData: Codable {
        var text: TextElementData?
        var icon: IconElementData?
    }
    
    struct TextElementData: Codable {
        var textColor: CodableColorData?
        var fontId: String?
        var fontSize: Double?
    }
    
    struct IconElementData: Codable {
        var primaryColor: CodableColorData?
    }
}

// MARK: - Gradient Point Helper

enum GradientPointHelper {
    static func unitPoint(from string: String) -> UnitPoint {
        switch string {
        case "topLeading": return .topLeading
        case "top": return .top
        case "topTrailing": return .topTrailing
        case "leading": return .leading
        case "center": return .center
        case "trailing": return .trailing
        case "bottomLeading": return .bottomLeading
        case "bottom": return .bottom
        case "bottomTrailing": return .bottomTrailing
        default: return .center
        }
    }
}

// MARK: - WidgetStyleConfig Factory

extension WidgetProjectLoader {
    /// Create style config from saved project data
    static func createStyleConfig(from project: SavedProjectData) -> WidgetStyleConfig {
        var textColor: Color = .primary
        var secondaryTextColor: Color = .secondary
        var accentColor: Color = .blue
        var background: AnyView
        
        // Extract background based on enum case
        if let solid = project.background.solidFill {
            let opacity = solid.opacity ?? 1.0
            background = AnyView(solid.color.color.opacity(opacity))
            let brightness = calculateBrightness(solid.color)
            textColor = brightness > 0.5 ? .black : .white
            secondaryTextColor = (brightness > 0.5 ? Color.black : Color.white).opacity(0.7)
            accentColor = brightness > 0.5 ? Color(red: 0.2, green: 0.45, blue: 0.75) : Color(red: 0.4, green: 0.65, blue: 0.95)
        } else if let gradient = project.background.gradientFill {
            let colors = gradient.stops.map { $0.color.color }
            let gradientView = LinearGradient(
                colors: colors,
                startPoint: gradient.startUnitPoint,
                endPoint: gradient.endUnitPoint
            )
            background = AnyView(gradientView)
            
            // Use average brightness for text contrast
            if let firstColor = gradient.stops.first?.color {
                let brightness = calculateBrightness(firstColor)
                textColor = brightness > 0.5 ? .black : .white
                secondaryTextColor = (brightness > 0.5 ? Color.black : Color.white).opacity(0.7)
                accentColor = brightness > 0.5 ? Color(red: 0.2, green: 0.45, blue: 0.75) : Color.white.opacity(0.9)
            }
        } else if let glass = project.background.glassmorphismFill {
            // Glassmorphism - use frosted glass effect
            let tintColor = glass.tintColor.color
            let tintOpacity = glass.tintOpacity
            background = AnyView(
                ZStack {
                    tintColor.opacity(tintOpacity)
                    Color.white.opacity(0.1)
                }
            )
            // Determine text color based on glass tint brightness
            let brightness = calculateBrightness(glass.tintColor)
            textColor = brightness > 0.5 ? Color.black.opacity(0.85) : Color.white.opacity(0.95)
            secondaryTextColor = brightness > 0.5 ? Color.black.opacity(0.6) : Color.white.opacity(0.7)
            accentColor = brightness > 0.5 ? Color(red: 0.2, green: 0.45, blue: 0.75) : Color.white.opacity(0.9)
        } else if project.background.imageFill != nil {
            // Image background - use semi-transparent overlay
            background = AnyView(Color.black.opacity(0.3))
            textColor = .white
            secondaryTextColor = Color.white.opacity(0.8)
            accentColor = Color.white.opacity(0.9)
        } else {
            // Default
            background = AnyView(Color.white)
        }
        
        // Try to get text color from first text layer
        if let layers = project.layers,
           let textLayer = layers.first(where: { $0.element?.text != nil }),
           let layerTextColor = textLayer.element?.text?.textColor {
            textColor = layerTextColor.color
        }
        
        return WidgetStyleConfig(
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
            background: background
        )
    }
    
    private static func calculateBrightness(_ color: SavedProjectData.CodableColorData) -> Double {
        // Calculate perceived brightness using luminance formula
        return 0.299 * color.red + 0.587 * color.green + 0.114 * color.blue
    }
}

extension WidgetProjectLoader {
    /// Load and create style config for a project ID
    func loadStyleConfig(for projectId: String) -> WidgetStyleConfig? {
        // Handle "default" special case
        if projectId == "default" {
            return nil
        }
        
        guard let uuid = UUID(uuidString: projectId),
              let folder = projectsFolder else {
            print("[WidgetProjectLoader] Failed to get projects folder for ID: \(projectId)")
            return nil
        }
        
        let projectURL = folder.appendingPathComponent("\(uuid.uuidString).json")
        
        // Check if file exists
        guard fileManager.fileExists(atPath: projectURL.path) else {
            print("[WidgetProjectLoader] Project file not found at: \(projectURL.path)")
            return nil
        }
        
        guard let data = try? Data(contentsOf: projectURL) else {
            print("[WidgetProjectLoader] Failed to read data from: \(projectURL.path)")
            return nil
        }
        
        do {
            let project = try JSONDecoder().decode(SavedProjectData.self, from: data)
            print("[WidgetProjectLoader] Successfully loaded project: \(project.name)")
            return WidgetProjectLoader.createStyleConfig(from: project)
        } catch {
            print("[WidgetProjectLoader] Failed to decode project: \(error)")
            return nil
        }
    }
}

