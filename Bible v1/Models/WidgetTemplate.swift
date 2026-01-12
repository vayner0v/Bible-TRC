//
//  WidgetTemplate.swift
//  Bible v1
//
//  Curated widget templates for quick design starts
//

import Foundation
import SwiftUI

// MARK: - Widget Template

/// Pre-designed widget template that can be customized
struct WidgetTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let category: TemplateCategory
    let tags: [String]
    let supportedWidgetTypes: [BibleWidgetType]
    let supportedSizes: [WidgetSize]
    let previewColors: [Color] // For thumbnail gradient
    let project: WidgetProject
    let isPremium: Bool
    let seasonalEndDate: Date? // For seasonal templates
    
    init(
        id: String,
        name: String,
        description: String,
        category: TemplateCategory,
        tags: [String] = [],
        supportedWidgetTypes: [BibleWidgetType] = BibleWidgetType.allCases,
        supportedSizes: [WidgetSize] = WidgetSize.allCases,
        previewColors: [Color],
        project: WidgetProject,
        isPremium: Bool = false,
        seasonalEndDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.tags = tags
        self.supportedWidgetTypes = supportedWidgetTypes
        self.supportedSizes = supportedSizes
        self.previewColors = previewColors
        self.project = project
        self.isPremium = isPremium
        self.seasonalEndDate = seasonalEndDate
    }
    
    /// Whether this seasonal template is currently active
    var isSeasonalActive: Bool {
        guard let endDate = seasonalEndDate else { return true }
        return Date() < endDate
    }
    
    /// Create a new project from this template
    func createProject(widgetType: BibleWidgetType, size: WidgetSize) -> WidgetProject {
        // Generate new UUID and reset metadata
        return WidgetProject(
            id: UUID(),
            name: "\(name) - \(widgetType.displayName)",
            widgetType: widgetType,
            size: size,
            layers: project.layers,
            background: project.background,
            isFavorite: false,
            templateId: id
        )
    }
}

// MARK: - Template Category

enum TemplateCategory: String, CaseIterable, Identifiable {
    case featured = "Featured"
    case minimal = "Minimal"
    case elegant = "Elegant"
    case nature = "Nature"
    case typography = "Typography"
    case dark = "Dark Mode"
    case seasonal = "Seasonal"
    case glass = "Glass"
    case gradient = "Gradient"
    case photo = "Photo"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .minimal: return "minus.circle"
        case .elegant: return "crown.fill"
        case .nature: return "leaf.fill"
        case .typography: return "textformat"
        case .dark: return "moon.fill"
        case .seasonal: return "calendar"
        case .glass: return "rectangle.on.rectangle"
        case .gradient: return "paintpalette.fill"
        case .photo: return "photo.fill"
        }
    }
    
    var description: String {
        switch self {
        case .featured: return "Hand-picked designs"
        case .minimal: return "Clean and simple"
        case .elegant: return "Sophisticated style"
        case .nature: return "Inspired by nature"
        case .typography: return "Bold text focus"
        case .dark: return "Perfect for dark mode"
        case .seasonal: return "Holiday & seasonal"
        case .glass: return "Frosted glass effects"
        case .gradient: return "Beautiful gradients"
        case .photo: return "Photo backgrounds"
        }
    }
}

// MARK: - Template Library

/// Central repository of all widget templates
final class WidgetTemplateLibrary {
    static let shared = WidgetTemplateLibrary()
    
    private(set) var templates: [WidgetTemplate] = []
    private(set) var recentlyUsed: [String] = [] // Template IDs
    private(set) var favorites: [String] = [] // Template IDs
    
    private let userDefaults = UserDefaults.standard
    private let recentlyUsedKey = "widget_templates_recent"
    private let favoritesKey = "widget_templates_favorites"
    
    private init() {
        loadUserPreferences()
        buildTemplateLibrary()
    }
    
    // MARK: - Public Methods
    
    /// Get templates by category
    func templates(for category: TemplateCategory) -> [WidgetTemplate] {
        templates.filter { $0.category == category && $0.isSeasonalActive }
    }
    
    /// Get featured templates
    var featuredTemplates: [WidgetTemplate] {
        templates.filter { $0.category == .featured && $0.isSeasonalActive }
    }
    
    /// Get recently used templates
    var recentTemplates: [WidgetTemplate] {
        recentlyUsed.compactMap { id in
            templates.first { $0.id == id }
        }
    }
    
    /// Get favorite templates
    var favoriteTemplates: [WidgetTemplate] {
        favorites.compactMap { id in
            templates.first { $0.id == id }
        }
    }
    
    /// Search templates
    func search(query: String) -> [WidgetTemplate] {
        let lowercased = query.lowercased()
        return templates.filter { template in
            template.name.lowercased().contains(lowercased) ||
            template.description.lowercased().contains(lowercased) ||
            template.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }
    
    /// Mark template as recently used
    func markAsUsed(_ templateId: String) {
        recentlyUsed.removeAll { $0 == templateId }
        recentlyUsed.insert(templateId, at: 0)
        if recentlyUsed.count > 10 {
            recentlyUsed = Array(recentlyUsed.prefix(10))
        }
        saveUserPreferences()
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ templateId: String) {
        if favorites.contains(templateId) {
            favorites.removeAll { $0 == templateId }
        } else {
            favorites.append(templateId)
        }
        saveUserPreferences()
    }
    
    /// Check if template is favorited
    func isFavorite(_ templateId: String) -> Bool {
        favorites.contains(templateId)
    }
    
    // MARK: - Private Methods
    
    private func loadUserPreferences() {
        recentlyUsed = userDefaults.stringArray(forKey: recentlyUsedKey) ?? []
        favorites = userDefaults.stringArray(forKey: favoritesKey) ?? []
    }
    
    private func saveUserPreferences() {
        userDefaults.set(recentlyUsed, forKey: recentlyUsedKey)
        userDefaults.set(favorites, forKey: favoritesKey)
    }
    
    private func buildTemplateLibrary() {
        templates = [
            // MARK: Featured Templates
            createClassicWhiteTemplate(),
            createMidnightGoldTemplate(),
            createAuroraGlowTemplate(),
            
            // MARK: Minimal Templates
            createPureMinimalTemplate(),
            createMonoTemplate(),
            createCleanSlateTemplate(),
            
            // MARK: Elegant Templates
            createVelvetTemplate(),
            createRoyalTemplate(),
            createMarbleTemplate(),
            
            // MARK: Nature Templates
            createForestTemplate(),
            createOceanTemplate(),
            createSunsetTemplate(),
            
            // MARK: Typography Templates
            createBoldStatementTemplate(),
            createSerifClassicTemplate(),
            createModernSansTemplate(),
            
            // MARK: Dark Mode Templates
            createTrueDarkTemplate(),
            createCharcoalTemplate(),
            createNightSkyTemplate(),
            
            // MARK: Glass Templates
            createFrostedLightTemplate(),
            createFrostedDarkTemplate(),
            createVibrantGlassTemplate(),
            
            // MARK: Gradient Templates
            createSunriseGradientTemplate(),
            createOceanGradientTemplate(),
            createNeonTemplate()
        ]
    }
    
    // MARK: - Template Builders
    
    private func createClassicWhiteTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Title",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 14,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.3, green: 0.5, blue: 0.8)
                    )
                )),
                frame: LayerFrame(x: 5, y: 8, width: 90, height: 12, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 16,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.15, green: 0.15, blue: 0.15),
                        alignment: .leading,
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 25, width: 90, height: 60, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "classic_white",
            name: "Classic White",
            description: "Clean, timeless design",
            category: .featured,
            tags: ["clean", "white", "classic", "light"],
            previewColors: [.white, Color(red: 0.96, green: 0.96, blue: 0.98)],
            project: WidgetProject(
                name: "Classic White",
                layers: layers,
                background: .solid(SolidFill(color: CodableColor(color: .white)))
            )
        )
    }
    
    private func createMidnightGoldTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Icon",
                element: .icon(IconElementConfig(
                    symbolName: "sparkles",
                    primaryColor: CodableColor(red: 0.85, green: 0.7, blue: 0.45),
                    size: 16
                )),
                frame: LayerFrame(x: 5, y: 8, width: 10, height: 10, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Title",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "palatino",
                        fontSize: 13,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.85, green: 0.7, blue: 0.45)
                    )
                )),
                frame: LayerFrame(x: 15, y: 8, width: 80, height: 10, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "newYork",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.95, green: 0.93, blue: 0.88),
                        lineSpacing: 1.5
                    )
                )),
                frame: LayerFrame(x: 5, y: 22, width: 90, height: 65, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "midnight_gold",
            name: "Midnight Gold",
            description: "Luxurious dark with gold accents",
            category: .featured,
            tags: ["dark", "gold", "luxury", "elegant"],
            previewColors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.10, blue: 0.15)],
            project: WidgetProject(
                name: "Midnight Gold",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.08, green: 0.08, blue: 0.12), location: 0),
                        GradientStop(color: CodableColor(red: 0.12, green: 0.10, blue: 0.15), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            )
        )
    }
    
    private func createAuroraGlowTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 16,
                        fontWeight: .medium,
                        textColor: CodableColor(color: .white),
                        alignment: .center,
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 20, width: 90, height: 50, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 12,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 1, green: 1, blue: 1, opacity: 0.8),
                        alignment: .center
                    )
                )),
                frame: LayerFrame(x: 5, y: 75, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "aurora_glow",
            name: "Aurora Glow",
            description: "Vibrant teal to violet gradient",
            category: .featured,
            tags: ["aurora", "gradient", "vibrant", "colorful"],
            previewColors: [Color(red: 0.2, green: 0.72, blue: 0.65), Color(red: 0.66, green: 0.33, blue: 0.96)],
            project: WidgetProject(
                name: "Aurora Glow",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.2, green: 0.72, blue: 0.65), location: 0),
                        GradientStop(color: CodableColor(red: 0.66, green: 0.33, blue: 0.96), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            )
        )
    }
    
    private func createPureMinimalTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 18,
                        fontWeight: .light,
                        textColor: CodableColor(red: 0.1, green: 0.1, blue: 0.1),
                        alignment: .center,
                        lineSpacing: 1.6
                    )
                )),
                frame: LayerFrame(x: 8, y: 30, width: 84, height: 50, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "pure_minimal",
            name: "Pure Minimal",
            description: "Just the verse, nothing else",
            category: .minimal,
            tags: ["minimal", "clean", "simple", "white"],
            previewColors: [Color(red: 0.99, green: 0.99, blue: 0.99), Color(red: 0.97, green: 0.97, blue: 0.97)],
            project: WidgetProject(
                name: "Pure Minimal",
                layers: layers,
                background: .solid(SolidFill(color: CodableColor(red: 0.99, green: 0.99, blue: 0.99)))
            )
        )
    }
    
    private func createMonoTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Line",
                element: .shape(ShapeElementConfig(
                    type: .rectangle,
                    fill: .solid(CodableColor(red: 0.1, green: 0.1, blue: 0.1)),
                    cornerRadius: .uniform(0)
                )),
                frame: LayerFrame(x: 5, y: 5, width: 1, height: 90, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 14,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.15, green: 0.15, blue: 0.15),
                        alignment: .leading
                    )
                )),
                frame: LayerFrame(x: 10, y: 15, width: 85, height: 55, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.4, green: 0.4, blue: 0.4)
                    )
                )),
                frame: LayerFrame(x: 10, y: 78, width: 85, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "mono",
            name: "Mono",
            description: "Editorial monochrome style",
            category: .minimal,
            tags: ["mono", "editorial", "black", "line"],
            previewColors: [.white, Color(red: 0.95, green: 0.95, blue: 0.95)],
            project: WidgetProject(
                name: "Mono",
                layers: layers,
                background: .solid(SolidFill(color: CodableColor(color: .white)))
            )
        )
    }
    
    private func createCleanSlateTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Background Shape",
                element: .shape(ShapeElementConfig(
                    type: .roundedRectangle,
                    fill: .solid(CodableColor(red: 0.96, green: 0.96, blue: 0.98)),
                    cornerRadius: .uniform(16)
                )),
                frame: LayerFrame(x: 3, y: 3, width: 94, height: 94, rotation: 0),
                zIndex: 0
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.2, green: 0.2, blue: 0.2),
                        alignment: .center
                    )
                )),
                frame: LayerFrame(x: 8, y: 25, width: 84, height: 50, rotation: 0),
                zIndex: 1
            )
        ]
        
        return WidgetTemplate(
            id: "clean_slate",
            name: "Clean Slate",
            description: "Subtle card with soft edges",
            category: .minimal,
            tags: ["card", "soft", "clean", "rounded"],
            previewColors: [.white, Color(red: 0.96, green: 0.96, blue: 0.98)],
            project: WidgetProject(
                name: "Clean Slate",
                layers: layers,
                background: .solid(SolidFill(color: CodableColor(color: .white)))
            )
        )
    }
    
    private func createVelvetTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Icon",
                element: .icon(IconElementConfig(
                    symbolName: "book.fill",
                    primaryColor: CodableColor(red: 0.79, green: 0.64, blue: 0.3),
                    size: 18
                )),
                frame: LayerFrame(x: 5, y: 8, width: 12, height: 12, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.96, green: 0.94, blue: 0.9),
                        lineSpacing: 1.5
                    )
                )),
                frame: LayerFrame(x: 5, y: 25, width: 90, height: 55, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 11,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.79, green: 0.64, blue: 0.3)
                    )
                )),
                frame: LayerFrame(x: 5, y: 85, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "velvet",
            name: "Velvet",
            description: "Rich, luxurious dark velvet",
            category: .elegant,
            tags: ["velvet", "dark", "gold", "luxury"],
            previewColors: [Color(red: 0.07, green: 0.07, blue: 0.1), Color(red: 0.1, green: 0.08, blue: 0.13)],
            project: WidgetProject(
                name: "Velvet",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.07, green: 0.07, blue: 0.1), location: 0),
                        GradientStop(color: CodableColor(red: 0.1, green: 0.08, blue: 0.13), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            )
        )
    }
    
    private func createRoyalTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Crown",
                element: .icon(IconElementConfig(
                    symbolName: "crown.fill",
                    primaryColor: CodableColor(red: 0.85, green: 0.75, blue: 0.55),
                    size: 20
                )),
                frame: LayerFrame(x: 42, y: 5, width: 16, height: 12, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "palatino",
                        fontSize: 16,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.95, green: 0.92, blue: 0.88),
                        alignment: .center,
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 22, width: 90, height: 55, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "palatino",
                        fontSize: 11,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.85, green: 0.75, blue: 0.55),
                        alignment: .center
                    )
                )),
                frame: LayerFrame(x: 5, y: 82, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "royal",
            name: "Royal",
            description: "Regal purple with gold accents",
            category: .elegant,
            tags: ["royal", "purple", "gold", "regal"],
            previewColors: [Color(red: 0.15, green: 0.08, blue: 0.25), Color(red: 0.25, green: 0.12, blue: 0.35)],
            project: WidgetProject(
                name: "Royal",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.15, green: 0.08, blue: 0.25), location: 0),
                        GradientStop(color: CodableColor(red: 0.25, green: 0.12, blue: 0.35), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            )
        )
    }
    
    private func createMarbleTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "palatino",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.25, green: 0.22, blue: 0.2),
                        alignment: .center,
                        lineSpacing: 1.5
                    )
                )),
                frame: LayerFrame(x: 8, y: 25, width: 84, height: 50, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "palatino",
                        fontSize: 11,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.5, green: 0.45, blue: 0.4),
                        alignment: .center
                    )
                )),
                frame: LayerFrame(x: 8, y: 80, width: 84, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "marble",
            name: "Marble",
            description: "Classic marble elegance",
            category: .elegant,
            tags: ["marble", "classic", "cream", "elegant"],
            previewColors: [Color(red: 0.97, green: 0.95, blue: 0.92), Color(red: 0.93, green: 0.9, blue: 0.86)],
            project: WidgetProject(
                name: "Marble",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.97, green: 0.95, blue: 0.92), location: 0),
                        GradientStop(color: CodableColor(red: 0.93, green: 0.9, blue: 0.86), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            )
        )
    }
    
    private func createForestTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Leaf Icon",
                element: .icon(IconElementConfig(
                    symbolName: "leaf.fill",
                    primaryColor: CodableColor(red: 0.5, green: 0.75, blue: 0.55),
                    size: 16
                )),
                frame: LayerFrame(x: 5, y: 8, width: 10, height: 10, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.95, green: 0.96, blue: 0.93),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 22, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 11,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.6, green: 0.8, blue: 0.65)
                    )
                )),
                frame: LayerFrame(x: 5, y: 85, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "forest",
            name: "Forest",
            description: "Deep forest greens",
            category: .nature,
            tags: ["forest", "green", "nature", "earth"],
            previewColors: [Color(red: 0.12, green: 0.25, blue: 0.15), Color(red: 0.08, green: 0.18, blue: 0.1)],
            project: WidgetProject(
                name: "Forest",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.12, green: 0.25, blue: 0.15), location: 0),
                        GradientStop(color: CodableColor(red: 0.08, green: 0.18, blue: 0.1), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            )
        )
    }
    
    private func createOceanTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Wave Icon",
                element: .icon(IconElementConfig(
                    symbolName: "water.waves",
                    primaryColor: CodableColor(red: 0.6, green: 0.85, blue: 0.95),
                    size: 18
                )),
                frame: LayerFrame(x: 5, y: 8, width: 12, height: 10, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(color: .white),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 22, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.7, green: 0.9, blue: 1.0)
                    )
                )),
                frame: LayerFrame(x: 5, y: 85, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "ocean",
            name: "Ocean",
            description: "Deep blue ocean depths",
            category: .nature,
            tags: ["ocean", "blue", "sea", "water"],
            previewColors: [Color(red: 0.1, green: 0.35, blue: 0.55), Color(red: 0.05, green: 0.18, blue: 0.35)],
            project: WidgetProject(
                name: "Ocean",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.1, green: 0.35, blue: 0.55), location: 0),
                        GradientStop(color: CodableColor(red: 0.05, green: 0.18, blue: 0.35), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            )
        )
    }
    
    private func createSunsetTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Sun Icon",
                element: .icon(IconElementConfig(
                    symbolName: "sun.max.fill",
                    primaryColor: CodableColor(red: 1.0, green: 0.85, blue: 0.5),
                    size: 18
                )),
                frame: LayerFrame(x: 5, y: 8, width: 12, height: 10, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 15,
                        fontWeight: .medium,
                        textColor: CodableColor(color: .white),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 22, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 11,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 1.0, green: 0.9, blue: 0.7)
                    )
                )),
                frame: LayerFrame(x: 5, y: 85, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "sunset",
            name: "Sunset",
            description: "Warm sunset colors",
            category: .nature,
            tags: ["sunset", "warm", "orange", "golden"],
            previewColors: [Color(red: 0.95, green: 0.6, blue: 0.4), Color(red: 0.85, green: 0.35, blue: 0.45)],
            project: WidgetProject(
                name: "Sunset",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.98, green: 0.75, blue: 0.45), location: 0),
                        GradientStop(color: CodableColor(red: 0.95, green: 0.55, blue: 0.4), location: 0.5),
                        GradientStop(color: CodableColor(red: 0.85, green: 0.35, blue: 0.45), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            )
        )
    }
    
    private func createBoldStatementTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 22,
                        fontWeight: .bold,
                        textColor: CodableColor(red: 0.1, green: 0.1, blue: 0.1),
                        alignment: .center,
                        lineSpacing: 1.2
                    )
                )),
                frame: LayerFrame(x: 5, y: 20, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 12,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.4, green: 0.4, blue: 0.4),
                        alignment: .center
                    )
                )),
                frame: LayerFrame(x: 5, y: 85, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "bold_statement",
            name: "Bold Statement",
            description: "Large, impactful typography",
            category: .typography,
            tags: ["bold", "typography", "statement", "big"],
            previewColors: [.white, Color(red: 0.98, green: 0.98, blue: 0.98)],
            project: WidgetProject(
                name: "Bold Statement",
                layers: layers,
                background: .solid(SolidFill(color: CodableColor(color: .white)))
            )
        )
    }
    
    private func createSerifClassicTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Quote Open",
                element: .text(TextElementConfig(
                    text: "\u{201C}",
                    fontId: "georgia",
                    fontSize: 48,
                    fontWeight: .regular,
                    textColor: CodableColor(red: 0.8, green: 0.75, blue: 0.7, opacity: 0.3)
                )),
                frame: LayerFrame(x: 3, y: 2, width: 15, height: 20, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 17,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.25, green: 0.22, blue: 0.18),
                        alignment: .center,
                        lineSpacing: 1.5
                    )
                )),
                frame: LayerFrame(x: 8, y: 20, width: 84, height: 55, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 12,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.55, green: 0.45, blue: 0.35),
                        alignment: .center
                    )
                )),
                frame: LayerFrame(x: 8, y: 80, width: 84, height: 12, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "serif_classic",
            name: "Serif Classic",
            description: "Timeless serif typography",
            category: .typography,
            tags: ["serif", "classic", "georgia", "quote"],
            previewColors: [Color(red: 0.97, green: 0.94, blue: 0.9), Color(red: 0.94, green: 0.9, blue: 0.85)],
            project: WidgetProject(
                name: "Serif Classic",
                layers: layers,
                background: .solid(SolidFill(color: CodableColor(red: 0.97, green: 0.94, blue: 0.9)))
            )
        )
    }
    
    private func createModernSansTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Accent Line",
                element: .shape(ShapeElementConfig(
                    type: .rectangle,
                    fill: .solid(CodableColor(red: 0.2, green: 0.5, blue: 0.9)),
                    cornerRadius: .uniform(2)
                )),
                frame: LayerFrame(x: 5, y: 5, width: 15, height: 1, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.15, green: 0.15, blue: 0.18),
                        alignment: .leading,
                        letterSpacing: 0.3,
                        lineSpacing: 1.5
                    )
                )),
                frame: LayerFrame(x: 5, y: 15, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.2, green: 0.5, blue: 0.9),
                        letterSpacing: 1.0
                    )
                )),
                frame: LayerFrame(x: 5, y: 82, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "modern_sans",
            name: "Modern Sans",
            description: "Contemporary sans-serif style",
            category: .typography,
            tags: ["modern", "sans", "clean", "contemporary"],
            previewColors: [.white, Color(red: 0.97, green: 0.97, blue: 0.98)],
            project: WidgetProject(
                name: "Modern Sans",
                layers: layers,
                background: .solid(SolidFill(color: CodableColor(color: .white)))
            )
        )
    }
    
    private func createTrueDarkTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.9, green: 0.9, blue: 0.92),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 15, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.5, green: 0.5, blue: 0.55)
                    )
                )),
                frame: LayerFrame(x: 5, y: 82, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "true_dark",
            name: "True Dark",
            description: "Pure black for OLED displays",
            category: .dark,
            tags: ["dark", "black", "oled", "pure"],
            previewColors: [.black, Color(red: 0.05, green: 0.05, blue: 0.05)],
            project: WidgetProject(
                name: "True Dark",
                layers: layers,
                background: .solid(SolidFill(color: CodableColor(color: .black)))
            )
        )
    }
    
    private func createCharcoalTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.92, green: 0.92, blue: 0.94),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 15, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.55, green: 0.55, blue: 0.6)
                    )
                )),
                frame: LayerFrame(x: 5, y: 82, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "charcoal",
            name: "Charcoal",
            description: "Soft dark gray",
            category: .dark,
            tags: ["charcoal", "gray", "dark", "soft"],
            previewColors: [Color(red: 0.15, green: 0.15, blue: 0.17), Color(red: 0.12, green: 0.12, blue: 0.14)],
            project: WidgetProject(
                name: "Charcoal",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.15, green: 0.15, blue: 0.17), location: 0),
                        GradientStop(color: CodableColor(red: 0.12, green: 0.12, blue: 0.14), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            )
        )
    }
    
    private func createNightSkyTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Stars Icon",
                element: .icon(IconElementConfig(
                    symbolName: "sparkles",
                    primaryColor: CodableColor(red: 0.9, green: 0.85, blue: 0.6),
                    size: 14
                )),
                frame: LayerFrame(x: 5, y: 8, width: 10, height: 10, rotation: 0),
                zIndex: 2
            ),
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .regular,
                        textColor: CodableColor(red: 0.95, green: 0.95, blue: 0.97),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 22, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.6, green: 0.65, blue: 0.85)
                    )
                )),
                frame: LayerFrame(x: 5, y: 85, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "night_sky",
            name: "Night Sky",
            description: "Deep blue night sky",
            category: .dark,
            tags: ["night", "sky", "blue", "stars"],
            previewColors: [Color(red: 0.08, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.06, blue: 0.12)],
            project: WidgetProject(
                name: "Night Sky",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.08, green: 0.1, blue: 0.2), location: 0),
                        GradientStop(color: CodableColor(red: 0.05, green: 0.06, blue: 0.12), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            )
        )
    }
    
    private func createFrostedLightTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.1, green: 0.12, blue: 0.18),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 15, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.0, green: 0.41, blue: 1.0)
                    )
                )),
                frame: LayerFrame(x: 5, y: 82, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "frosted_light",
            name: "Frosted Light",
            description: "iOS-style frosted glass",
            category: .glass,
            tags: ["glass", "frosted", "blur", "light"],
            previewColors: [Color(red: 0.96, green: 0.97, blue: 1.0), Color(red: 0.97, green: 0.96, blue: 1.0)],
            project: WidgetProject(
                name: "Frosted Light",
                layers: layers,
                background: .glassmorphism(GlassmorphismPreset.lightGlass.defaultConfig)
            )
        )
    }
    
    private func createFrostedDarkTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .medium,
                        textColor: CodableColor(red: 0.92, green: 0.94, blue: 1.0),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 15, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.04, green: 0.52, blue: 1.0)
                    )
                )),
                frame: LayerFrame(x: 5, y: 82, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "frosted_dark",
            name: "Frosted Dark",
            description: "Dark mode frosted glass",
            category: .glass,
            tags: ["glass", "frosted", "blur", "dark"],
            previewColors: [Color(red: 0.06, green: 0.1, blue: 0.16), Color(red: 0.1, green: 0.14, blue: 0.2)],
            project: WidgetProject(
                name: "Frosted Dark",
                layers: layers,
                background: .glassmorphism(GlassmorphismPreset.darkGlass.defaultConfig)
            )
        )
    }
    
    private func createVibrantGlassTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .semibold,
                        textColor: CodableColor(color: .white),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 15, width: 90, height: 60, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .bold,
                        textColor: CodableColor(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.8)
                    )
                )),
                frame: LayerFrame(x: 5, y: 82, width: 90, height: 10, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "vibrant_glass",
            name: "Vibrant Glass",
            description: "Translucent with color punch",
            category: .glass,
            tags: ["glass", "vibrant", "color", "translucent"],
            previewColors: [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.3, green: 0.5, blue: 0.9)],
            project: WidgetProject(
                name: "Vibrant Glass",
                layers: layers,
                background: .glassmorphism(GlassmorphismPreset.vibrant.defaultConfig)
            )
        )
    }
    
    private func createSunriseGradientTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 16,
                        fontWeight: .medium,
                        textColor: CodableColor(color: .white),
                        alignment: .center,
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 20, width: 90, height: 55, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 12,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 1.0, green: 0.95, blue: 0.85),
                        alignment: .center
                    )
                )),
                frame: LayerFrame(x: 5, y: 80, width: 90, height: 12, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "sunrise_gradient",
            name: "Sunrise",
            description: "Warm morning gradient",
            category: .gradient,
            tags: ["sunrise", "warm", "gradient", "morning"],
            previewColors: [Color(red: 0.98, green: 0.75, blue: 0.45), Color(red: 0.9, green: 0.4, blue: 0.5)],
            project: WidgetProject(
                name: "Sunrise",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.98, green: 0.75, blue: 0.45), location: 0),
                        GradientStop(color: CodableColor(red: 0.95, green: 0.55, blue: 0.4), location: 0.5),
                        GradientStop(color: CodableColor(red: 0.9, green: 0.4, blue: 0.5), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            )
        )
    }
    
    private func createOceanGradientTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 15,
                        fontWeight: .medium,
                        textColor: CodableColor(color: .white),
                        lineSpacing: 1.4
                    )
                )),
                frame: LayerFrame(x: 5, y: 20, width: 90, height: 55, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 11,
                        fontWeight: .semibold,
                        textColor: CodableColor(red: 0.8, green: 0.95, blue: 1.0)
                    )
                )),
                frame: LayerFrame(x: 5, y: 80, width: 90, height: 12, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "ocean_gradient",
            name: "Ocean Wave",
            description: "Cool blue gradient",
            category: .gradient,
            tags: ["ocean", "blue", "gradient", "cool"],
            previewColors: [Color(red: 0.2, green: 0.7, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.7)],
            project: WidgetProject(
                name: "Ocean Wave",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.2, green: 0.7, blue: 0.9), location: 0),
                        GradientStop(color: CodableColor(red: 0.1, green: 0.4, blue: 0.7), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            )
        )
    }
    
    private func createNeonTemplate() -> WidgetTemplate {
        let layers = [
            WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 16,
                        fontWeight: .bold,
                        textColor: CodableColor(color: .white),
                        alignment: .center,
                        lineSpacing: 1.3
                    )
                )),
                frame: LayerFrame(x: 5, y: 20, width: 90, height: 55, rotation: 0),
                zIndex: 1
            ),
            WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 12,
                        fontWeight: .bold,
                        textColor: CodableColor(red: 1.0, green: 0.85, blue: 1.0),
                        alignment: .center
                    )
                )),
                frame: LayerFrame(x: 5, y: 80, width: 90, height: 12, rotation: 0),
                zIndex: 0
            )
        ]
        
        return WidgetTemplate(
            id: "neon",
            name: "Neon Nights",
            description: "Vibrant neon gradient",
            category: .gradient,
            tags: ["neon", "vibrant", "gradient", "pink", "purple"],
            previewColors: [Color(red: 0.95, green: 0.2, blue: 0.5), Color(red: 0.4, green: 0.2, blue: 0.9)],
            project: WidgetProject(
                name: "Neon Nights",
                layers: layers,
                background: .gradient(GradientFill(
                    type: .linear,
                    stops: [
                        GradientStop(color: CodableColor(red: 0.95, green: 0.2, blue: 0.5), location: 0),
                        GradientStop(color: CodableColor(red: 0.4, green: 0.2, blue: 0.9), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            )
        )
    }
}

