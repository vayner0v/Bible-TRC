//
//  WidgetLayerConfiguration.swift
//  Bible v1
//
//  Layer-based widget configuration system for Widgy-style editor
//

import Foundation
import SwiftUI

// MARK: - Widget Project

/// Root container for a widget design with multiple layers
struct WidgetProject: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var widgetType: BibleWidgetType
    var size: WidgetSize
    var layers: [WidgetLayer]
    var background: ProjectBackground
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool
    var templateId: String?
    
    init(
        id: UUID = UUID(),
        name: String = "My Widget",
        widgetType: BibleWidgetType = .verseOfDay,
        size: WidgetSize = .medium,
        layers: [WidgetLayer] = [],
        background: ProjectBackground = .default,
        isFavorite: Bool = false,
        templateId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.widgetType = widgetType
        self.size = size
        self.layers = layers
        self.background = background
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isFavorite = isFavorite
        self.templateId = templateId
    }
    
    /// Add a new layer at the top
    mutating func addLayer(_ layer: WidgetLayer) {
        var newLayer = layer
        newLayer.zIndex = (layers.map(\.zIndex).max() ?? -1) + 1
        layers.append(newLayer)
    }
    
    /// Remove a layer by ID
    mutating func removeLayer(id: UUID) {
        layers.removeAll { $0.id == id }
    }
    
    /// Move layer to new z-index
    mutating func moveLayer(id: UUID, to newIndex: Int) {
        guard let layerIndex = layers.firstIndex(where: { $0.id == id }) else { return }
        let layer = layers.remove(at: layerIndex)
        let insertIndex = min(max(0, newIndex), layers.count)
        layers.insert(layer, at: insertIndex)
        // Recalculate z-indices
        for (index, _) in layers.enumerated() {
            layers[index].zIndex = index
        }
    }
    
    /// Get layers sorted by z-index for rendering
    var sortedLayers: [WidgetLayer] {
        layers.sorted { $0.zIndex < $1.zIndex }
    }
}

// MARK: - Project Background

/// Background configuration for the entire widget
enum ProjectBackground: Codable, Equatable {
    case solid(SolidFill)
    case gradient(GradientFill)
    case image(ImageFill)
    case glassmorphism(GlassmorphismFill)
    
    static var `default`: ProjectBackground {
        .solid(SolidFill(color: CodableColor(color: .white)))
    }
}

/// Solid color fill
struct SolidFill: Codable, Equatable {
    var color: CodableColor
    var opacity: Double = 1.0
}

/// Advanced gradient fill with multiple stops
struct GradientFill: Codable, Equatable {
    var type: GradientType
    var stops: [GradientStop]
    var startPoint: GradientPoint
    var endPoint: GradientPoint
    var angle: Double // For angular gradients (0-360)
    
    init(
        type: GradientType = .linear,
        stops: [GradientStop] = [
            GradientStop(color: CodableColor(color: .blue), location: 0),
            GradientStop(color: CodableColor(color: .purple), location: 1)
        ],
        startPoint: GradientPoint = .topLeading,
        endPoint: GradientPoint = .bottomTrailing,
        angle: Double = 45
    ) {
        self.type = type
        self.stops = stops
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.angle = angle
    }
    
    /// Convert to SwiftUI gradient
    var colors: [Color] {
        stops.sorted { $0.location < $1.location }.map { $0.color.color }
    }
    
    var gradientStops: [Gradient.Stop] {
        stops.sorted { $0.location < $1.location }.map {
            Gradient.Stop(color: $0.color.color, location: $0.location)
        }
    }
}

enum GradientType: String, Codable, CaseIterable {
    case linear
    case radial
    case angular
    
    var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .radial: return "Radial"
        case .angular: return "Angular"
        }
    }
    
    var icon: String {
        switch self {
        case .linear: return "arrow.up.right"
        case .radial: return "circle.dotted"
        case .angular: return "rotate.right"
        }
    }
}

struct GradientStop: Codable, Equatable, Identifiable {
    let id: UUID
    var color: CodableColor
    var location: Double // 0.0 to 1.0
    
    init(id: UUID = UUID(), color: CodableColor, location: Double) {
        self.id = id
        self.color = color
        self.location = max(0, min(1, location))
    }
}

/// Image background fill
struct ImageFill: Codable, Equatable {
    var imageId: String // Reference to stored image
    var contentMode: ImageContentMode
    var blurRadius: Double
    var overlayColor: CodableColor?
    var overlayOpacity: Double
    var brightness: Double // -1.0 to 1.0
    var saturation: Double // 0.0 to 2.0
    
    init(
        imageId: String,
        contentMode: ImageContentMode = .fill,
        blurRadius: Double = 0,
        overlayColor: CodableColor? = nil,
        overlayOpacity: Double = 0.3,
        brightness: Double = 0,
        saturation: Double = 1.0
    ) {
        self.imageId = imageId
        self.contentMode = contentMode
        self.blurRadius = blurRadius
        self.overlayColor = overlayColor
        self.overlayOpacity = overlayOpacity
        self.brightness = brightness
        self.saturation = saturation
    }
}

enum ImageContentMode: String, Codable, CaseIterable {
    case fill
    case fit
    case stretch
    case tile
    
    var displayName: String {
        switch self {
        case .fill: return "Fill"
        case .fit: return "Fit"
        case .stretch: return "Stretch"
        case .tile: return "Tile"
        }
    }
}

/// Glassmorphism effect fill
struct GlassmorphismFill: Codable, Equatable {
    var preset: GlassmorphismPreset
    var blurRadius: Double
    var tintColor: CodableColor
    var tintOpacity: Double
    var noiseOpacity: Double
    var borderOpacity: Double
    
    init(
        preset: GlassmorphismPreset = .lightGlass,
        blurRadius: Double = 20,
        tintColor: CodableColor = CodableColor(color: .white),
        tintOpacity: Double = 0.7,
        noiseOpacity: Double = 0.05,
        borderOpacity: Double = 0.3
    ) {
        self.preset = preset
        self.blurRadius = blurRadius
        self.tintColor = tintColor
        self.tintOpacity = tintOpacity
        self.noiseOpacity = noiseOpacity
        self.borderOpacity = borderOpacity
    }
}

enum GlassmorphismPreset: String, Codable, CaseIterable {
    case lightGlass
    case darkGlass
    case frosted
    case vibrant
    case subtle
    
    var displayName: String {
        switch self {
        case .lightGlass: return "Light Glass"
        case .darkGlass: return "Dark Glass"
        case .frosted: return "Frosted"
        case .vibrant: return "Vibrant"
        case .subtle: return "Subtle"
        }
    }
    
    var defaultConfig: GlassmorphismFill {
        switch self {
        case .lightGlass:
            return GlassmorphismFill(
                preset: .lightGlass,
                blurRadius: 20,
                tintColor: CodableColor(color: .white),
                tintOpacity: 0.7,
                noiseOpacity: 0.05,
                borderOpacity: 0.3
            )
        case .darkGlass:
            return GlassmorphismFill(
                preset: .darkGlass,
                blurRadius: 24,
                tintColor: CodableColor(red: 0.1, green: 0.1, blue: 0.12),
                tintOpacity: 0.8,
                noiseOpacity: 0.03,
                borderOpacity: 0.2
            )
        case .frosted:
            return GlassmorphismFill(
                preset: .frosted,
                blurRadius: 30,
                tintColor: CodableColor(color: .white),
                tintOpacity: 0.85,
                noiseOpacity: 0.08,
                borderOpacity: 0.15
            )
        case .vibrant:
            return GlassmorphismFill(
                preset: .vibrant,
                blurRadius: 16,
                tintColor: CodableColor(color: .white),
                tintOpacity: 0.5,
                noiseOpacity: 0.02,
                borderOpacity: 0.4
            )
        case .subtle:
            return GlassmorphismFill(
                preset: .subtle,
                blurRadius: 12,
                tintColor: CodableColor(color: .white),
                tintOpacity: 0.9,
                noiseOpacity: 0.01,
                borderOpacity: 0.1
            )
        }
    }
}

// MARK: - Widget Layer

/// Individual layer within a widget project
struct WidgetLayer: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var element: LayerElement
    var frame: LayerFrame
    var style: LayerStyle
    var zIndex: Int
    var isVisible: Bool
    var isLocked: Bool
    var opacity: Double
    var blendMode: LayerBlendMode
    
    init(
        id: UUID = UUID(),
        name: String = "Layer",
        element: LayerElement,
        frame: LayerFrame = .default,
        style: LayerStyle = .default,
        zIndex: Int = 0,
        isVisible: Bool = true,
        isLocked: Bool = false,
        opacity: Double = 1.0,
        blendMode: LayerBlendMode = .normal
    ) {
        self.id = id
        self.name = name
        self.element = element
        self.frame = frame
        self.style = style
        self.zIndex = zIndex
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.opacity = opacity
        self.blendMode = blendMode
    }
    
    /// Auto-generate layer name based on element type
    static func autoName(for element: LayerElement) -> String {
        switch element {
        case .text(let config): return config.text.prefix(20).isEmpty ? "Text" : String(config.text.prefix(20))
        case .icon(let config): return "Icon: \(config.symbolName)"
        case .shape(let config): return "Shape: \(config.type.displayName)"
        case .image: return "Image"
        case .dataBinding(let config): return config.dataType.displayName
        }
    }
}

/// Layer position and size
struct LayerFrame: Codable, Equatable {
    var x: Double // Percentage from left (0-100)
    var y: Double // Percentage from top (0-100)
    var width: Double // Percentage of widget width (0-100)
    var height: Double // Percentage of widget height (0-100)
    var rotation: Double // Degrees
    
    static var `default`: LayerFrame {
        LayerFrame(x: 10, y: 10, width: 80, height: 20, rotation: 0)
    }
    
    static var centered: LayerFrame {
        LayerFrame(x: 10, y: 40, width: 80, height: 20, rotation: 0)
    }
    
    static var fullWidth: LayerFrame {
        LayerFrame(x: 5, y: 10, width: 90, height: 15, rotation: 0)
    }
}

enum LayerBlendMode: String, Codable, CaseIterable {
    case normal
    case multiply
    case screen
    case overlay
    case darken
    case lighten
    case colorDodge
    case colorBurn
    case softLight
    case hardLight
    case difference
    case exclusion
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .multiply: return "Multiply"
        case .screen: return "Screen"
        case .overlay: return "Overlay"
        case .darken: return "Darken"
        case .lighten: return "Lighten"
        case .colorDodge: return "Color Dodge"
        case .colorBurn: return "Color Burn"
        case .softLight: return "Soft Light"
        case .hardLight: return "Hard Light"
        case .difference: return "Difference"
        case .exclusion: return "Exclusion"
        }
    }
    
    var swiftUIBlendMode: BlendMode {
        switch self {
        case .normal: return .normal
        case .multiply: return .multiply
        case .screen: return .screen
        case .overlay: return .overlay
        case .darken: return .darken
        case .lighten: return .lighten
        case .colorDodge: return .colorDodge
        case .colorBurn: return .colorBurn
        case .softLight: return .softLight
        case .hardLight: return .hardLight
        case .difference: return .difference
        case .exclusion: return .exclusion
        }
    }
}

// MARK: - Layer Elements

/// Type of content within a layer
enum LayerElement: Codable, Equatable {
    case text(TextElementConfig)
    case icon(IconElementConfig)
    case shape(ShapeElementConfig)
    case image(ImageElementConfig)
    case dataBinding(DataBindingConfig)
    
    var elementType: ElementType {
        switch self {
        case .text: return .text
        case .icon: return .icon
        case .shape: return .shape
        case .image: return .image
        case .dataBinding: return .dataBinding
        }
    }
}

enum ElementType: String, Codable, CaseIterable {
    case text
    case icon
    case shape
    case image
    case dataBinding
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .icon: return "Icon"
        case .shape: return "Shape"
        case .image: return "Image"
        case .dataBinding: return "Data"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .text: return "textformat"
        case .icon: return "star.fill"
        case .shape: return "square.on.circle"
        case .image: return "photo"
        case .dataBinding: return "link"
        }
    }
}

/// Text element configuration
struct TextElementConfig: Codable, Equatable {
    var text: String
    var fontId: String // Reference to WidgetFontRegistry
    var fontSize: Double
    var fontWeight: WidgetFontWeight
    var textColor: CodableColor
    var gradientFill: GradientFill?
    var alignment: WidgetTextAlignment
    var letterSpacing: Double
    var lineSpacing: Double
    var maxLines: Int
    var shadow: TextShadow?
    var outline: TextOutline?
    
    init(
        text: String = "Text",
        fontId: String = "system",
        fontSize: Double = 16,
        fontWeight: WidgetFontWeight = .regular,
        textColor: CodableColor = CodableColor(color: .primary),
        gradientFill: GradientFill? = nil,
        alignment: WidgetTextAlignment = .leading,
        letterSpacing: Double = 0,
        lineSpacing: Double = 1.2,
        maxLines: Int = 0,
        shadow: TextShadow? = nil,
        outline: TextOutline? = nil
    ) {
        self.text = text
        self.fontId = fontId
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.textColor = textColor
        self.gradientFill = gradientFill
        self.alignment = alignment
        self.letterSpacing = letterSpacing
        self.lineSpacing = lineSpacing
        self.maxLines = maxLines
        self.shadow = shadow
        self.outline = outline
    }
}

struct TextShadow: Codable, Equatable {
    var color: CodableColor
    var radius: Double
    var offsetX: Double
    var offsetY: Double
    
    static var `default`: TextShadow {
        TextShadow(
            color: CodableColor(red: 0, green: 0, blue: 0, opacity: 0.3),
            radius: 4,
            offsetX: 0,
            offsetY: 2
        )
    }
}

struct TextOutline: Codable, Equatable {
    var color: CodableColor
    var width: Double
    
    static var `default`: TextOutline {
        TextOutline(
            color: CodableColor(color: .black),
            width: 1
        )
    }
}

/// Icon (SF Symbol) element configuration
struct IconElementConfig: Codable, Equatable {
    var symbolName: String
    var renderingMode: IconRenderingMode
    var primaryColor: CodableColor
    var secondaryColor: CodableColor?
    var tertiaryColor: CodableColor?
    var size: Double
    var weight: IconWeight
    var shadow: TextShadow?
    
    init(
        symbolName: String = "star.fill",
        renderingMode: IconRenderingMode = .monochrome,
        primaryColor: CodableColor = CodableColor(color: .primary),
        secondaryColor: CodableColor? = nil,
        tertiaryColor: CodableColor? = nil,
        size: Double = 24,
        weight: IconWeight = .regular,
        shadow: TextShadow? = nil
    ) {
        self.symbolName = symbolName
        self.renderingMode = renderingMode
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
        self.size = size
        self.weight = weight
        self.shadow = shadow
    }
}

enum IconRenderingMode: String, Codable, CaseIterable {
    case monochrome
    case hierarchical
    case palette
    case multicolor
    
    var displayName: String {
        switch self {
        case .monochrome: return "Monochrome"
        case .hierarchical: return "Hierarchical"
        case .palette: return "Palette"
        case .multicolor: return "Multicolor"
        }
    }
}

enum IconWeight: String, Codable, CaseIterable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black
    
    var displayName: String { rawValue.capitalized }
    
    var fontWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

/// Shape element configuration
struct ShapeElementConfig: Codable, Equatable {
    var type: ShapeType
    var fill: ShapeFill
    var stroke: ShapeStroke?
    var cornerRadius: CornerRadiusConfig
    var shadow: ShapeShadow?
    
    init(
        type: ShapeType = .rectangle,
        fill: ShapeFill = .solid(CodableColor(color: .blue)),
        stroke: ShapeStroke? = nil,
        cornerRadius: CornerRadiusConfig = .uniform(12),
        shadow: ShapeShadow? = nil
    ) {
        self.type = type
        self.fill = fill
        self.stroke = stroke
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
}

enum ShapeType: String, Codable, CaseIterable {
    case rectangle
    case circle
    case ellipse
    case roundedRectangle
    case capsule
    case line
    case triangle
    case star
    
    var displayName: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .circle: return "Circle"
        case .ellipse: return "Ellipse"
        case .roundedRectangle: return "Rounded Rect"
        case .capsule: return "Capsule"
        case .line: return "Line"
        case .triangle: return "Triangle"
        case .star: return "Star"
        }
    }
    
    var icon: String {
        switch self {
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .ellipse: return "oval"
        case .roundedRectangle: return "rectangle.roundedtop"
        case .capsule: return "capsule"
        case .line: return "line.diagonal"
        case .triangle: return "triangle"
        case .star: return "star"
        }
    }
}

enum ShapeFill: Codable, Equatable {
    case none
    case solid(CodableColor)
    case gradient(GradientFill)
}

struct ShapeStroke: Codable, Equatable {
    var color: CodableColor
    var width: Double
    var style: StrokeStyle
    var dashPattern: [Double]?
    
    enum StrokeStyle: String, Codable, CaseIterable {
        case solid
        case dashed
        case dotted
        
        var displayName: String { rawValue.capitalized }
    }
    
    static var `default`: ShapeStroke {
        ShapeStroke(color: CodableColor(color: .gray), width: 1, style: .solid, dashPattern: nil)
    }
}

enum CornerRadiusConfig: Codable, Equatable {
    case uniform(Double)
    case individual(topLeading: Double, topTrailing: Double, bottomLeading: Double, bottomTrailing: Double)
    
    var topLeading: Double {
        switch self {
        case .uniform(let r): return r
        case .individual(let tl, _, _, _): return tl
        }
    }
    
    var topTrailing: Double {
        switch self {
        case .uniform(let r): return r
        case .individual(_, let tr, _, _): return tr
        }
    }
    
    var bottomLeading: Double {
        switch self {
        case .uniform(let r): return r
        case .individual(_, _, let bl, _): return bl
        }
    }
    
    var bottomTrailing: Double {
        switch self {
        case .uniform(let r): return r
        case .individual(_, _, _, let br): return br
        }
    }
}

struct ShapeShadow: Codable, Equatable {
    var color: CodableColor
    var radius: Double
    var offsetX: Double
    var offsetY: Double
    var isInner: Bool
    
    static var `default`: ShapeShadow {
        ShapeShadow(
            color: CodableColor(red: 0, green: 0, blue: 0, opacity: 0.2),
            radius: 8,
            offsetX: 0,
            offsetY: 4,
            isInner: false
        )
    }
    
    static var inner: ShapeShadow {
        ShapeShadow(
            color: CodableColor(red: 0, green: 0, blue: 0, opacity: 0.15),
            radius: 4,
            offsetX: 0,
            offsetY: 2,
            isInner: true
        )
    }
}

/// Image element configuration
struct ImageElementConfig: Codable, Equatable {
    var imageId: String
    var contentMode: ImageContentMode
    var cornerRadius: Double
    var opacity: Double
    var blurRadius: Double
    var grayscale: Bool
    var tintColor: CodableColor?
    
    init(
        imageId: String,
        contentMode: ImageContentMode = .fill,
        cornerRadius: Double = 0,
        opacity: Double = 1.0,
        blurRadius: Double = 0,
        grayscale: Bool = false,
        tintColor: CodableColor? = nil
    ) {
        self.imageId = imageId
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.blurRadius = blurRadius
        self.grayscale = grayscale
        self.tintColor = tintColor
    }
}

/// Data binding element configuration
struct DataBindingConfig: Codable, Equatable {
    var dataType: WidgetDataType
    var textStyle: TextElementConfig
    var prefix: String
    var suffix: String
    var emptyText: String
    var formatStyle: DataFormatStyle
    
    init(
        dataType: WidgetDataType = .verseText,
        textStyle: TextElementConfig = TextElementConfig(),
        prefix: String = "",
        suffix: String = "",
        emptyText: String = "—",
        formatStyle: DataFormatStyle = .default
    ) {
        self.dataType = dataType
        self.textStyle = textStyle
        self.prefix = prefix
        self.suffix = suffix
        self.emptyText = emptyText
        self.formatStyle = formatStyle
    }
}

enum WidgetDataType: String, Codable, CaseIterable {
    // Verse data
    case verseText
    case verseReference
    case verseBook
    case verseChapter
    case verseNumber
    
    // Progress data
    case readingProgress
    case readingStreak
    case currentPlanDay
    case totalPlanDays
    case planName
    
    // Prayer data
    case activePrayerCount
    case answeredPrayerCount
    
    // Habit data
    case habitProgress
    case completedHabits
    case totalHabits
    case habitStreak
    
    // Date/Time
    case currentDate
    case currentTime
    case dayOfWeek
    case monthYear
    
    // Countdown
    case daysRemaining
    case countdownTitle
    
    // Mood/Gratitude
    case lastMood
    case gratitudeStreak
    
    var displayName: String {
        switch self {
        case .verseText: return "Verse Text"
        case .verseReference: return "Verse Reference"
        case .verseBook: return "Book Name"
        case .verseChapter: return "Chapter"
        case .verseNumber: return "Verse Number"
        case .readingProgress: return "Reading Progress"
        case .readingStreak: return "Reading Streak"
        case .currentPlanDay: return "Current Day"
        case .totalPlanDays: return "Total Days"
        case .planName: return "Plan Name"
        case .activePrayerCount: return "Active Prayers"
        case .answeredPrayerCount: return "Answered Prayers"
        case .habitProgress: return "Habit Progress"
        case .completedHabits: return "Completed Habits"
        case .totalHabits: return "Total Habits"
        case .habitStreak: return "Habit Streak"
        case .currentDate: return "Current Date"
        case .currentTime: return "Current Time"
        case .dayOfWeek: return "Day of Week"
        case .monthYear: return "Month & Year"
        case .daysRemaining: return "Days Remaining"
        case .countdownTitle: return "Countdown Title"
        case .lastMood: return "Last Mood"
        case .gratitudeStreak: return "Gratitude Streak"
        }
    }
    
    var category: DataCategory {
        switch self {
        case .verseText, .verseReference, .verseBook, .verseChapter, .verseNumber:
            return .scripture
        case .readingProgress, .readingStreak, .currentPlanDay, .totalPlanDays, .planName:
            return .reading
        case .activePrayerCount, .answeredPrayerCount:
            return .prayer
        case .habitProgress, .completedHabits, .totalHabits, .habitStreak:
            return .habits
        case .currentDate, .currentTime, .dayOfWeek, .monthYear:
            return .dateTime
        case .daysRemaining, .countdownTitle:
            return .countdown
        case .lastMood, .gratitudeStreak:
            return .mood
        }
    }
    
    enum DataCategory: String, CaseIterable {
        case scripture = "Scripture"
        case reading = "Reading"
        case prayer = "Prayer"
        case habits = "Habits"
        case dateTime = "Date & Time"
        case countdown = "Countdown"
        case mood = "Mood"
        
        var icon: String {
            switch self {
            case .scripture: return "book.fill"
            case .reading: return "bookmark.fill"
            case .prayer: return "hands.sparkles"
            case .habits: return "checkmark.circle.fill"
            case .dateTime: return "calendar"
            case .countdown: return "timer"
            case .mood: return "heart.fill"
            }
        }
    }
}

enum DataFormatStyle: String, Codable, CaseIterable {
    case `default`
    case short
    case long
    case numeric
    case percentage
    
    var displayName: String {
        switch self {
        case .default: return "Default"
        case .short: return "Short"
        case .long: return "Long"
        case .numeric: return "Numeric"
        case .percentage: return "Percentage"
        }
    }
}

// MARK: - Layer Style

/// Overall style configuration for a layer
struct LayerStyle: Codable, Equatable {
    var shadow: ShapeShadow?
    var blur: Double
    var border: BorderConfig?
    
    static var `default`: LayerStyle {
        LayerStyle(shadow: nil, blur: 0, border: nil)
    }
}

/// Border configuration
struct BorderConfig: Codable, Equatable {
    var color: CodableColor
    var width: Double
    var style: ShapeStroke.StrokeStyle
    var cornerRadius: CornerRadiusConfig
    
    static var `default`: BorderConfig {
        BorderConfig(
            color: CodableColor(color: .gray),
            width: 1,
            style: .solid,
            cornerRadius: .uniform(8)
        )
    }
}

// MARK: - Preset Gradients

/// Library of preset gradients
struct GradientPreset: Identifiable {
    let id: String
    let name: String
    let category: GradientCategory
    let fill: GradientFill
    
    enum GradientCategory: String, CaseIterable {
        case sunrise = "Sunrise"
        case ocean = "Ocean"
        case nature = "Nature"
        case vibrant = "Vibrant"
        case dark = "Dark"
        case pastel = "Pastel"
    }
}

extension GradientPreset {
    static let presets: [GradientPreset] = [
        // Sunrise
        GradientPreset(
            id: "sunrise_gold",
            name: "Golden Hour",
            category: .sunrise,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.98, green: 0.75, blue: 0.4), location: 0),
                    GradientStop(color: CodableColor(red: 0.95, green: 0.55, blue: 0.35), location: 0.5),
                    GradientStop(color: CodableColor(red: 0.85, green: 0.35, blue: 0.45), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        ),
        GradientPreset(
            id: "sunrise_rose",
            name: "Rose Dawn",
            category: .sunrise,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 1.0, green: 0.85, blue: 0.75), location: 0),
                    GradientStop(color: CodableColor(red: 0.95, green: 0.6, blue: 0.65), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        
        // Ocean
        GradientPreset(
            id: "ocean_deep",
            name: "Deep Sea",
            category: .ocean,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.1, green: 0.3, blue: 0.5), location: 0),
                    GradientStop(color: CodableColor(red: 0.05, green: 0.15, blue: 0.35), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        ),
        GradientPreset(
            id: "ocean_tropical",
            name: "Tropical Wave",
            category: .ocean,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.2, green: 0.8, blue: 0.9), location: 0),
                    GradientStop(color: CodableColor(red: 0.1, green: 0.5, blue: 0.8), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        
        // Nature
        GradientPreset(
            id: "nature_forest",
            name: "Forest",
            category: .nature,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.2, green: 0.5, blue: 0.3), location: 0),
                    GradientStop(color: CodableColor(red: 0.1, green: 0.35, blue: 0.2), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        ),
        GradientPreset(
            id: "nature_lavender",
            name: "Lavender Field",
            category: .nature,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.7, green: 0.6, blue: 0.9), location: 0),
                    GradientStop(color: CodableColor(red: 0.5, green: 0.4, blue: 0.75), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        
        // Vibrant
        GradientPreset(
            id: "vibrant_aurora",
            name: "Aurora",
            category: .vibrant,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.2, green: 0.9, blue: 0.7), location: 0),
                    GradientStop(color: CodableColor(red: 0.5, green: 0.3, blue: 0.9), location: 0.5),
                    GradientStop(color: CodableColor(red: 0.9, green: 0.3, blue: 0.6), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        GradientPreset(
            id: "vibrant_neon",
            name: "Neon Nights",
            category: .vibrant,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.95, green: 0.2, blue: 0.5), location: 0),
                    GradientStop(color: CodableColor(red: 0.4, green: 0.2, blue: 0.95), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        ),
        
        // Dark
        GradientPreset(
            id: "dark_midnight",
            name: "Midnight",
            category: .dark,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.08, green: 0.08, blue: 0.15), location: 0),
                    GradientStop(color: CodableColor(red: 0.02, green: 0.02, blue: 0.08), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        ),
        GradientPreset(
            id: "dark_charcoal",
            name: "Charcoal",
            category: .dark,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.2, green: 0.2, blue: 0.22), location: 0),
                    GradientStop(color: CodableColor(red: 0.1, green: 0.1, blue: 0.12), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        
        // Pastel
        GradientPreset(
            id: "pastel_cotton",
            name: "Cotton Candy",
            category: .pastel,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.95, green: 0.8, blue: 0.9), location: 0),
                    GradientStop(color: CodableColor(red: 0.8, green: 0.85, blue: 0.98), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        GradientPreset(
            id: "pastel_mint",
            name: "Mint Dream",
            category: .pastel,
            fill: GradientFill(
                type: .linear,
                stops: [
                    GradientStop(color: CodableColor(red: 0.85, green: 0.98, blue: 0.92), location: 0),
                    GradientStop(color: CodableColor(red: 0.75, green: 0.92, blue: 0.98), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    ]
    
    static func presets(for category: GradientCategory) -> [GradientPreset] {
        presets.filter { $0.category == category }
    }
}




