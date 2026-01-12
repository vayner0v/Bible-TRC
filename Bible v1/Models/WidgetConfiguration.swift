//
//  WidgetConfiguration.swift
//  Bible v1
//
//  Shared widget configuration models for App Group data sharing
//

import Foundation
import SwiftUI

// MARK: - Widget Types

/// All available widget types
enum BibleWidgetType: String, Codable, CaseIterable, Identifiable {
    case verseOfDay = "verse_of_day"
    case readingProgress = "reading_progress"
    case prayerReminder = "prayer_reminder"
    case habitTracker = "habit_tracker"
    case scriptureQuote = "scripture_quote"
    case countdown = "countdown"
    case moodGratitude = "mood_gratitude"
    case favorites = "favorites"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .verseOfDay: return "Verse of the Day"
        case .readingProgress: return "Reading Progress"
        case .prayerReminder: return "Prayer Reminder"
        case .habitTracker: return "Habit Tracker"
        case .scriptureQuote: return "Scripture Quote"
        case .countdown: return "Countdown"
        case .moodGratitude: return "Mood & Gratitude"
        case .favorites: return "Favorites"
        }
    }
    
    var description: String {
        switch self {
        case .verseOfDay: return "Daily scripture to inspire your day"
        case .readingProgress: return "Track your Bible reading plan"
        case .prayerReminder: return "Quick access to your prayers"
        case .habitTracker: return "Monitor your daily spiritual habits"
        case .scriptureQuote: return "Display your favorite verse"
        case .countdown: return "Days until your event or fasting end"
        case .moodGratitude: return "Check in with mood & gratitude"
        case .favorites: return "Quick access to saved verses"
        }
    }
    
    var icon: String {
        switch self {
        case .verseOfDay: return "sparkles"
        case .readingProgress: return "book.fill"
        case .prayerReminder: return "hands.sparkles"
        case .habitTracker: return "checkmark.circle.fill"
        case .scriptureQuote: return "quote.opening"
        case .countdown: return "calendar.badge.clock"
        case .moodGratitude: return "heart.fill"
        case .favorites: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .verseOfDay: return .yellow
        case .readingProgress: return .blue
        case .prayerReminder: return .teal
        case .habitTracker: return .green
        case .scriptureQuote: return .purple
        case .countdown: return .orange
        case .moodGratitude: return .pink
        case .favorites: return .red
        }
    }
    
    /// Supported sizes for this widget type
    var supportedSizes: [WidgetSize] {
        switch self {
        case .moodGratitude:
            return [.small, .medium]
        case .favorites:
            return [.medium, .large]
        default:
            return [.small, .medium, .large]
        }
    }
}

/// Widget sizes matching iOS WidgetFamily
enum WidgetSize: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var gridDescription: String {
        switch self {
        case .small: return "2×2"
        case .medium: return "4×2"
        case .large: return "4×4"
        }
    }
    
    /// Approximate dimensions for preview
    var previewSize: CGSize {
        switch self {
        case .small: return CGSize(width: 155, height: 155)
        case .medium: return CGSize(width: 329, height: 155)
        case .large: return CGSize(width: 329, height: 345)
        }
    }
}

// MARK: - Widget Styling

/// Background style options for widgets
enum WidgetBackgroundStyle: Codable, Equatable {
    case solid(color: CodableColor)
    case gradient(colors: [CodableColor], startPoint: GradientPoint, endPoint: GradientPoint)
    case pattern(patternName: String, baseColor: CodableColor)
    case image(imageName: String, opacity: Double)
    
    static var `default`: WidgetBackgroundStyle {
        .solid(color: CodableColor(color: .white))
    }
}

/// Gradient direction points
enum GradientPoint: String, Codable, CaseIterable {
    case topLeading, top, topTrailing
    case leading, center, trailing
    case bottomLeading, bottom, bottomTrailing
    
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

/// Font style configuration
struct WidgetFontStyle: Codable, Equatable {
    var family: WidgetFontFamily
    var size: WidgetFontSize
    var weight: WidgetFontWeight
    var color: CodableColor
    
    static var `default`: WidgetFontStyle {
        WidgetFontStyle(
            family: .system,
            size: .medium,
            weight: .regular,
            color: CodableColor(color: .primary)
        )
    }
}

enum WidgetFontFamily: String, Codable, CaseIterable {
    case system
    case serif
    case georgia
    case palatino
    case newYork
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Serif"
        case .georgia: return "Georgia"
        case .palatino: return "Palatino"
        case .newYork: return "New York"
        }
    }
    
    func font(size: CGFloat, weight: Font.Weight) -> Font {
        switch self {
        case .system:
            return .system(size: size, weight: weight)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        case .georgia:
            return .custom("Georgia", size: size)
        case .palatino:
            return .custom("Palatino", size: size)
        case .newYork:
            return .system(size: size, weight: weight, design: .serif)
        }
    }
}

enum WidgetFontSize: String, Codable, CaseIterable {
    case small
    case medium
    case large
    case extraLarge
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var pointSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        case .extraLarge: return 24
        }
    }
}

enum WidgetFontWeight: String, Codable, CaseIterable {
    case light
    case regular
    case medium
    case semibold
    case bold
    
    var displayName: String { rawValue.capitalized }
    
    var fontWeight: Font.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

/// Text alignment options
enum WidgetTextAlignment: String, Codable, CaseIterable {
    case leading
    case center
    case trailing
    
    var displayName: String { rawValue.capitalized }
    
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
}

/// Corner radius options
enum WidgetCornerStyle: String, Codable, CaseIterable {
    case sharp
    case rounded
    case extraRounded
    case circular
    
    var displayName: String {
        switch self {
        case .sharp: return "Sharp"
        case .rounded: return "Rounded"
        case .extraRounded: return "Extra Rounded"
        case .circular: return "Circular"
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .sharp: return 0
        case .rounded: return 16
        case .extraRounded: return 24
        case .circular: return 40
        }
    }
}

/// Padding options
enum WidgetPadding: String, Codable, CaseIterable {
    case compact
    case standard
    case comfortable
    case spacious
    
    var displayName: String { rawValue.capitalized }
    
    var value: CGFloat {
        switch self {
        case .compact: return 8
        case .standard: return 12
        case .comfortable: return 16
        case .spacious: return 20
        }
    }
}

// MARK: - Widget Configuration

/// Complete configuration for a single widget
struct WidgetConfig: Codable, Identifiable, Equatable {
    let id: UUID
    var widgetType: BibleWidgetType
    var size: WidgetSize
    var name: String
    
    // Styling
    var background: WidgetBackgroundStyle
    var titleStyle: WidgetFontStyle
    var bodyStyle: WidgetFontStyle
    var textAlignment: WidgetTextAlignment
    var cornerStyle: WidgetCornerStyle
    var padding: WidgetPadding
    var showShadow: Bool
    
    // Content-specific configuration
    var contentConfig: WidgetContentConfig
    
    // Metadata
    var isPreset: Bool
    var presetId: String?
    var createdAt: Date
    var modifiedAt: Date
    
    init(
        id: UUID = UUID(),
        widgetType: BibleWidgetType,
        size: WidgetSize = .medium,
        name: String? = nil,
        background: WidgetBackgroundStyle = .default,
        titleStyle: WidgetFontStyle = .default,
        bodyStyle: WidgetFontStyle = .default,
        textAlignment: WidgetTextAlignment = .leading,
        cornerStyle: WidgetCornerStyle = .rounded,
        padding: WidgetPadding = .standard,
        showShadow: Bool = true,
        contentConfig: WidgetContentConfig = .default,
        isPreset: Bool = false,
        presetId: String? = nil
    ) {
        self.id = id
        self.widgetType = widgetType
        self.size = size
        self.name = name ?? widgetType.displayName
        self.background = background
        self.titleStyle = titleStyle
        self.bodyStyle = bodyStyle
        self.textAlignment = textAlignment
        self.cornerStyle = cornerStyle
        self.padding = padding
        self.showShadow = showShadow
        self.contentConfig = contentConfig
        self.isPreset = isPreset
        self.presetId = presetId
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

/// Content-specific configuration (varies by widget type)
struct WidgetContentConfig: Codable, Equatable {
    // Verse of Day / Scripture Quote
    var selectedVerseReference: String?
    var translationId: String?
    
    // Reading Progress
    var showPercentage: Bool
    var showStreak: Bool
    
    // Prayer
    var prayerCategoryFilter: String?
    var showPrayerCount: Bool
    
    // Habits
    var habitIds: [String]
    var showCompletionRing: Bool
    
    // Countdown
    var countdownTitle: String?
    var countdownDate: Date?
    var countdownEventType: String?
    
    // Mood/Gratitude
    var showMoodHistory: Bool
    var showGratitudePrompt: Bool
    
    // Favorites
    var maxFavoritesToShow: Int
    var showBookmarks: Bool
    
    static var `default`: WidgetContentConfig {
        WidgetContentConfig(
            selectedVerseReference: nil,
            translationId: nil,
            showPercentage: true,
            showStreak: true,
            prayerCategoryFilter: nil,
            showPrayerCount: true,
            habitIds: [],
            showCompletionRing: true,
            countdownTitle: nil,
            countdownDate: nil,
            countdownEventType: nil,
            showMoodHistory: false,
            showGratitudePrompt: true,
            maxFavoritesToShow: 3,
            showBookmarks: true
        )
    }
}

// MARK: - Codable Color Helper

/// A Codable wrapper for SwiftUI Color
struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - Widget Data (for Timeline)

/// Data passed from app to widget extension
struct WidgetData: Codable {
    // Verse of the Day
    var verseOfDayText: String?
    var verseOfDayReference: String?
    
    // Reading Progress
    var readingPlanName: String?
    var readingProgress: Double?
    var readingStreak: Int?
    var currentDay: Int?
    var totalDays: Int?
    
    // Prayer
    var activePrayerCount: Int?
    var answeredPrayerCount: Int?
    var lastPrayerTime: Date?
    
    // Habits
    var todayHabitProgress: Double?
    var completedHabits: Int?
    var totalHabits: Int?
    var habitStreak: Int?
    
    // Favorites
    var favoriteVerses: [FavoriteVerseData]?
    
    // Mood/Gratitude
    var lastMood: String?
    var moodHistory: [String]?
    var lastMoodDate: Date?
    var gratitudeStreak: Int?
    var todayGratitudeCompleted: Bool?
    
    // Countdown
    var countdownTargetDate: Date?
    var countdownTitle: String?
    
    // Sync metadata
    var lastUpdated: Date
    var appTheme: String?
    
    static var empty: WidgetData {
        WidgetData(lastUpdated: Date())
    }
}

/// Favorite verse data for widget display
struct FavoriteVerseData: Codable {
    let reference: String
    let text: String
    let bookName: String
    let chapter: Int
    let verse: Int
}

// MARK: - Widget Presets

/// Pre-designed widget themes
struct WidgetPreset: Identifiable {
    let id: String
    let name: String
    let description: String
    let thumbnailGradient: [Color]
    let config: WidgetConfig
    
    var thumbnailLinearGradient: LinearGradient {
        LinearGradient(
            colors: thumbnailGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension WidgetPreset {
    static let allPresets: [WidgetPreset] = [
        classicLight,
        classicDark,
        sepiaWarmth,
        minimal,
        gradientBliss,
        scriptureArt,
        midnightGold,
        sunriseHope
    ]
    
    static let classicLight = WidgetPreset(
        id: "classic_light",
        name: "Classic Light",
        description: "Clean white with accent color",
        thumbnailGradient: [Color.white, Color(red: 0.95, green: 0.95, blue: 0.97)],
        config: WidgetConfig(
            widgetType: .verseOfDay,
            background: .solid(color: CodableColor(red: 1, green: 1, blue: 1)),
            titleStyle: WidgetFontStyle(
                family: .system,
                size: .medium,
                weight: .semibold,
                color: CodableColor(red: 0.2, green: 0.45, blue: 0.75)
            ),
            bodyStyle: WidgetFontStyle(
                family: .serif,
                size: .medium,
                weight: .regular,
                color: CodableColor(red: 0.12, green: 0.12, blue: 0.12)
            ),
            cornerStyle: .rounded,
            isPreset: true,
            presetId: "classic_light"
        )
    )
    
    static let classicDark = WidgetPreset(
        id: "classic_dark",
        name: "Classic Dark",
        description: "Dark mode with subtle gradients",
        thumbnailGradient: [Color(red: 0.11, green: 0.11, blue: 0.12), Color(red: 0.17, green: 0.17, blue: 0.18)],
        config: WidgetConfig(
            widgetType: .verseOfDay,
            background: .gradient(
                colors: [
                    CodableColor(red: 0.11, green: 0.11, blue: 0.12),
                    CodableColor(red: 0.17, green: 0.17, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            titleStyle: WidgetFontStyle(
                family: .system,
                size: .medium,
                weight: .semibold,
                color: CodableColor(red: 0.4, green: 0.6, blue: 0.9)
            ),
            bodyStyle: WidgetFontStyle(
                family: .serif,
                size: .medium,
                weight: .regular,
                color: CodableColor(red: 0.92, green: 0.92, blue: 0.92)
            ),
            cornerStyle: .rounded,
            isPreset: true,
            presetId: "classic_dark"
        )
    )
    
    static let sepiaWarmth = WidgetPreset(
        id: "sepia_warmth",
        name: "Sepia Warmth",
        description: "Warm tones matching sepia theme",
        thumbnailGradient: [Color(red: 0.96, green: 0.93, blue: 0.87), Color(red: 0.94, green: 0.90, blue: 0.82)],
        config: WidgetConfig(
            widgetType: .verseOfDay,
            background: .solid(color: CodableColor(red: 0.96, green: 0.93, blue: 0.87)),
            titleStyle: WidgetFontStyle(
                family: .georgia,
                size: .medium,
                weight: .semibold,
                color: CodableColor(red: 0.55, green: 0.35, blue: 0.20)
            ),
            bodyStyle: WidgetFontStyle(
                family: .georgia,
                size: .medium,
                weight: .regular,
                color: CodableColor(red: 0.24, green: 0.20, blue: 0.15)
            ),
            cornerStyle: .rounded,
            isPreset: true,
            presetId: "sepia_warmth"
        )
    )
    
    static let minimal = WidgetPreset(
        id: "minimal",
        name: "Minimal",
        description: "Ultra-clean, typography-focused",
        thumbnailGradient: [Color(red: 0.98, green: 0.98, blue: 0.98), Color(red: 0.96, green: 0.96, blue: 0.96)],
        config: WidgetConfig(
            widgetType: .verseOfDay,
            background: .solid(color: CodableColor(red: 0.98, green: 0.98, blue: 0.98)),
            titleStyle: WidgetFontStyle(
                family: .system,
                size: .small,
                weight: .medium,
                color: CodableColor(red: 0.5, green: 0.5, blue: 0.5)
            ),
            bodyStyle: WidgetFontStyle(
                family: .newYork,
                size: .large,
                weight: .light,
                color: CodableColor(red: 0.1, green: 0.1, blue: 0.1)
            ),
            textAlignment: .center,
            cornerStyle: .sharp,
            padding: .spacious,
            showShadow: false,
            isPreset: true,
            presetId: "minimal"
        )
    )
    
    static let gradientBliss = WidgetPreset(
        id: "gradient_bliss",
        name: "Gradient Bliss",
        description: "Soft gradient backgrounds",
        thumbnailGradient: [Color(red: 0.6, green: 0.7, blue: 0.9), Color(red: 0.8, green: 0.7, blue: 0.9)],
        config: WidgetConfig(
            widgetType: .verseOfDay,
            background: .gradient(
                colors: [
                    CodableColor(red: 0.6, green: 0.7, blue: 0.9),
                    CodableColor(red: 0.8, green: 0.7, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            titleStyle: WidgetFontStyle(
                family: .system,
                size: .medium,
                weight: .bold,
                color: CodableColor(red: 1, green: 1, blue: 1, opacity: 0.9)
            ),
            bodyStyle: WidgetFontStyle(
                family: .serif,
                size: .medium,
                weight: .medium,
                color: CodableColor(red: 1, green: 1, blue: 1)
            ),
            cornerStyle: .extraRounded,
            isPreset: true,
            presetId: "gradient_bliss"
        )
    )
    
    static let scriptureArt = WidgetPreset(
        id: "scripture_art",
        name: "Scripture Art",
        description: "Decorative patterns with elegance",
        thumbnailGradient: [Color(red: 0.15, green: 0.25, blue: 0.35), Color(red: 0.2, green: 0.3, blue: 0.45)],
        config: WidgetConfig(
            widgetType: .verseOfDay,
            background: .pattern(
                patternName: "crosses",
                baseColor: CodableColor(red: 0.15, green: 0.25, blue: 0.35)
            ),
            titleStyle: WidgetFontStyle(
                family: .palatino,
                size: .small,
                weight: .semibold,
                color: CodableColor(red: 0.85, green: 0.75, blue: 0.55)
            ),
            bodyStyle: WidgetFontStyle(
                family: .palatino,
                size: .medium,
                weight: .regular,
                color: CodableColor(red: 0.95, green: 0.92, blue: 0.88)
            ),
            textAlignment: .center,
            cornerStyle: .rounded,
            isPreset: true,
            presetId: "scripture_art"
        )
    )
    
    static let midnightGold = WidgetPreset(
        id: "midnight_gold",
        name: "Midnight Gold",
        description: "Luxurious dark with gold accents",
        thumbnailGradient: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.12, green: 0.10, blue: 0.15)],
        config: WidgetConfig(
            widgetType: .verseOfDay,
            background: .gradient(
                colors: [
                    CodableColor(red: 0.08, green: 0.08, blue: 0.12),
                    CodableColor(red: 0.12, green: 0.10, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            titleStyle: WidgetFontStyle(
                family: .palatino,
                size: .medium,
                weight: .semibold,
                color: CodableColor(red: 0.85, green: 0.70, blue: 0.45)
            ),
            bodyStyle: WidgetFontStyle(
                family: .newYork,
                size: .medium,
                weight: .regular,
                color: CodableColor(red: 0.95, green: 0.93, blue: 0.88)
            ),
            cornerStyle: .rounded,
            isPreset: true,
            presetId: "midnight_gold"
        )
    )
    
    static let sunriseHope = WidgetPreset(
        id: "sunrise_hope",
        name: "Sunrise Hope",
        description: "Warm sunrise gradients",
        thumbnailGradient: [Color(red: 0.95, green: 0.65, blue: 0.45), Color(red: 0.98, green: 0.80, blue: 0.55)],
        config: WidgetConfig(
            widgetType: .verseOfDay,
            background: .gradient(
                colors: [
                    CodableColor(red: 0.95, green: 0.65, blue: 0.45),
                    CodableColor(red: 0.98, green: 0.80, blue: 0.55)
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ),
            titleStyle: WidgetFontStyle(
                family: .system,
                size: .medium,
                weight: .bold,
                color: CodableColor(red: 0.3, green: 0.15, blue: 0.1)
            ),
            bodyStyle: WidgetFontStyle(
                family: .georgia,
                size: .medium,
                weight: .regular,
                color: CodableColor(red: 0.25, green: 0.15, blue: 0.1)
            ),
            cornerStyle: .extraRounded,
            isPreset: true,
            presetId: "sunrise_hope"
        )
    )
}

// MARK: - App Group Constants

enum AppGroupConstants {
    static let suiteName = "group.vaynerov.Bible-v1"
    static let widgetDataKey = "widget_data"
    static let widgetConfigsKey = "widget_configs"
    static let activeWidgetsKey = "active_widgets"
    static let widgetImagesFolder = "widget_images"
    static let widgetProjectsKey = "widget_projects"
}

// MARK: - Enhanced Background System

/// Advanced background style with more options (v2)
enum EnhancedWidgetBackground: Codable, Equatable {
    case solid(EnhancedSolidBackground)
    case gradient(EnhancedGradientBackground)
    case image(EnhancedImageBackground)
    case glassmorphism(EnhancedGlassmorphismBackground)
    case pattern(EnhancedPatternBackground)
    
    static var `default`: EnhancedWidgetBackground {
        .solid(EnhancedSolidBackground())
    }
    
    /// Convert to SwiftUI View background
    @ViewBuilder
    func backgroundView(in size: CGSize) -> some View {
        switch self {
        case .solid(let config):
            config.color.color.opacity(config.opacity)
            
        case .gradient(let config):
            config.swiftUIGradient
            
        case .image(let config):
            EnhancedImageBackgroundView(config: config, size: size)
            
        case .glassmorphism(let config):
            GlassmorphismBackgroundView(config: config)
            
        case .pattern(let config):
            PatternBackgroundView(config: config)
        }
    }
}

/// Solid color background with opacity
struct EnhancedSolidBackground: Codable, Equatable {
    var color: CodableColor
    var opacity: Double
    
    init(color: CodableColor = CodableColor(color: .white), opacity: Double = 1.0) {
        self.color = color
        self.opacity = opacity
    }
}

/// Advanced gradient background with multiple types
struct EnhancedGradientBackground: Codable, Equatable {
    var type: EnhancedGradientType
    var stops: [EnhancedGradientStop]
    var startPoint: GradientPoint
    var endPoint: GradientPoint
    var angle: Double // For angular gradients (0-360)
    var centerPoint: GradientPoint // For radial gradients
    
    init(
        type: EnhancedGradientType = .linear,
        stops: [EnhancedGradientStop] = [
            EnhancedGradientStop(color: CodableColor(color: .blue), location: 0),
            EnhancedGradientStop(color: CodableColor(color: .purple), location: 1)
        ],
        startPoint: GradientPoint = .topLeading,
        endPoint: GradientPoint = .bottomTrailing,
        angle: Double = 45,
        centerPoint: GradientPoint = .center
    ) {
        self.type = type
        self.stops = stops
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.angle = angle
        self.centerPoint = centerPoint
    }
    
    /// SwiftUI gradient representation
    @ViewBuilder
    var swiftUIGradient: some View {
        let gradient = Gradient(stops: stops.map { 
            Gradient.Stop(color: $0.color.color, location: $0.location) 
        })
        
        switch type {
        case .linear:
            LinearGradient(
                gradient: gradient,
                startPoint: startPoint.unitPoint,
                endPoint: endPoint.unitPoint
            )
        case .radial:
            RadialGradient(
                gradient: gradient,
                center: centerPoint.unitPoint,
                startRadius: 0,
                endRadius: 300
            )
        case .angular:
            AngularGradient(
                gradient: gradient,
                center: centerPoint.unitPoint,
                angle: .degrees(angle)
            )
        }
    }
}

enum EnhancedGradientType: String, Codable, CaseIterable {
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

struct EnhancedGradientStop: Codable, Equatable, Identifiable {
    let id: UUID
    var color: CodableColor
    var location: Double // 0.0 to 1.0
    
    init(id: UUID = UUID(), color: CodableColor, location: Double) {
        self.id = id
        self.color = color
        self.location = max(0, min(1, location))
    }
}

/// Image background with effects
struct EnhancedImageBackground: Codable, Equatable {
    var imageId: String // Reference to stored image in App Group
    var contentMode: WidgetImageContentMode
    var blurRadius: Double
    var overlayColor: CodableColor?
    var overlayOpacity: Double
    var brightness: Double // -1.0 to 1.0
    var saturation: Double // 0.0 to 2.0
    var opacity: Double
    
    init(
        imageId: String,
        contentMode: WidgetImageContentMode = .fill,
        blurRadius: Double = 0,
        overlayColor: CodableColor? = nil,
        overlayOpacity: Double = 0.3,
        brightness: Double = 0,
        saturation: Double = 1.0,
        opacity: Double = 1.0
    ) {
        self.imageId = imageId
        self.contentMode = contentMode
        self.blurRadius = blurRadius
        self.overlayColor = overlayColor
        self.overlayOpacity = overlayOpacity
        self.brightness = brightness
        self.saturation = saturation
        self.opacity = opacity
    }
}

enum WidgetImageContentMode: String, Codable, CaseIterable {
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
    
    var icon: String {
        switch self {
        case .fill: return "arrow.up.left.and.arrow.down.right"
        case .fit: return "aspectratio"
        case .stretch: return "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left"
        case .tile: return "square.grid.3x3"
        }
    }
}

/// Glassmorphism (frosted glass) background
struct EnhancedGlassmorphismBackground: Codable, Equatable {
    var preset: WidgetGlassmorphismPreset
    var blurRadius: Double
    var tintColor: CodableColor
    var tintOpacity: Double
    var noiseOpacity: Double
    var borderWidth: Double
    var borderOpacity: Double
    
    init(
        preset: WidgetGlassmorphismPreset = .lightGlass,
        blurRadius: Double = 20,
        tintColor: CodableColor = CodableColor(color: .white),
        tintOpacity: Double = 0.7,
        noiseOpacity: Double = 0.05,
        borderWidth: Double = 1,
        borderOpacity: Double = 0.3
    ) {
        self.preset = preset
        self.blurRadius = blurRadius
        self.tintColor = tintColor
        self.tintOpacity = tintOpacity
        self.noiseOpacity = noiseOpacity
        self.borderWidth = borderWidth
        self.borderOpacity = borderOpacity
    }
    
    static func from(preset: WidgetGlassmorphismPreset) -> EnhancedGlassmorphismBackground {
        preset.defaultConfig
    }
}

enum WidgetGlassmorphismPreset: String, Codable, CaseIterable {
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
    
    var defaultConfig: EnhancedGlassmorphismBackground {
        switch self {
        case .lightGlass:
            return EnhancedGlassmorphismBackground(
                preset: .lightGlass,
                blurRadius: 20,
                tintColor: CodableColor(color: .white),
                tintOpacity: 0.7,
                noiseOpacity: 0.05,
                borderWidth: 1,
                borderOpacity: 0.3
            )
        case .darkGlass:
            return EnhancedGlassmorphismBackground(
                preset: .darkGlass,
                blurRadius: 24,
                tintColor: CodableColor(red: 0.1, green: 0.1, blue: 0.12),
                tintOpacity: 0.8,
                noiseOpacity: 0.03,
                borderWidth: 1,
                borderOpacity: 0.2
            )
        case .frosted:
            return EnhancedGlassmorphismBackground(
                preset: .frosted,
                blurRadius: 30,
                tintColor: CodableColor(color: .white),
                tintOpacity: 0.85,
                noiseOpacity: 0.08,
                borderWidth: 0.5,
                borderOpacity: 0.15
            )
        case .vibrant:
            return EnhancedGlassmorphismBackground(
                preset: .vibrant,
                blurRadius: 16,
                tintColor: CodableColor(color: .white),
                tintOpacity: 0.5,
                noiseOpacity: 0.02,
                borderWidth: 1.5,
                borderOpacity: 0.4
            )
        case .subtle:
            return EnhancedGlassmorphismBackground(
                preset: .subtle,
                blurRadius: 12,
                tintColor: CodableColor(color: .white),
                tintOpacity: 0.9,
                noiseOpacity: 0.01,
                borderWidth: 0,
                borderOpacity: 0.1
            )
        }
    }
}

/// Pattern background with customization
struct EnhancedPatternBackground: Codable, Equatable {
    var patternType: WidgetPatternType
    var baseColor: CodableColor
    var patternColor: CodableColor
    var patternOpacity: Double
    var patternScale: Double
    
    init(
        patternType: WidgetPatternType = .dots,
        baseColor: CodableColor = CodableColor(color: .white),
        patternColor: CodableColor = CodableColor(red: 0.5, green: 0.5, blue: 0.5),
        patternOpacity: Double = 0.1,
        patternScale: Double = 1.0
    ) {
        self.patternType = patternType
        self.baseColor = baseColor
        self.patternColor = patternColor
        self.patternOpacity = patternOpacity
        self.patternScale = patternScale
    }
}

enum WidgetPatternType: String, Codable, CaseIterable {
    case dots
    case lines
    case grid
    case crosses
    case waves
    case diagonals
    case chevrons
    case circles
    
    var displayName: String {
        switch self {
        case .dots: return "Dots"
        case .lines: return "Lines"
        case .grid: return "Grid"
        case .crosses: return "Crosses"
        case .waves: return "Waves"
        case .diagonals: return "Diagonals"
        case .chevrons: return "Chevrons"
        case .circles: return "Circles"
        }
    }
    
    var icon: String {
        switch self {
        case .dots: return "circle.grid.3x3"
        case .lines: return "line.3.horizontal"
        case .grid: return "square.grid.3x3"
        case .crosses: return "cross"
        case .waves: return "water.waves"
        case .diagonals: return "line.diagonal"
        case .chevrons: return "chevron.up.2"
        case .circles: return "circle"
        }
    }
}

// MARK: - Enhanced Border Configuration

struct EnhancedBorderConfig: Codable, Equatable {
    var width: Double
    var color: CodableColor
    var style: WidgetBorderStyle
    var cornerRadius: EnhancedCornerRadius
    var dashPattern: [Double]?
    
    init(
        width: Double = 1,
        color: CodableColor = CodableColor(color: .gray),
        style: WidgetBorderStyle = .solid,
        cornerRadius: EnhancedCornerRadius = .uniform(12),
        dashPattern: [Double]? = nil
    ) {
        self.width = width
        self.color = color
        self.style = style
        self.cornerRadius = cornerRadius
        self.dashPattern = dashPattern
    }
    
    static var `default`: EnhancedBorderConfig {
        EnhancedBorderConfig()
    }
}

enum WidgetBorderStyle: String, Codable, CaseIterable {
    case solid
    case dashed
    case dotted
    case double
    
    var displayName: String { rawValue.capitalized }
    
    var icon: String {
        switch self {
        case .solid: return "minus"
        case .dashed: return "line.3.horizontal"
        case .dotted: return "ellipsis"
        case .double: return "equal"
        }
    }
}

enum EnhancedCornerRadius: Codable, Equatable {
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
    
    var isUniform: Bool {
        switch self {
        case .uniform: return true
        case .individual: return false
        }
    }
    
    var uniformValue: Double? {
        switch self {
        case .uniform(let r): return r
        case .individual: return nil
        }
    }
}

// MARK: - Enhanced Shadow Configuration

struct EnhancedShadowConfig: Codable, Equatable {
    var color: CodableColor
    var radius: Double
    var offsetX: Double
    var offsetY: Double
    var opacity: Double
    var isInner: Bool
    
    init(
        color: CodableColor = CodableColor(red: 0, green: 0, blue: 0),
        radius: Double = 8,
        offsetX: Double = 0,
        offsetY: Double = 4,
        opacity: Double = 0.2,
        isInner: Bool = false
    ) {
        self.color = color
        self.radius = radius
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.opacity = opacity
        self.isInner = isInner
    }
    
    static var `default`: EnhancedShadowConfig {
        EnhancedShadowConfig()
    }
    
    static var subtle: EnhancedShadowConfig {
        EnhancedShadowConfig(radius: 4, offsetY: 2, opacity: 0.1)
    }
    
    static var elevated: EnhancedShadowConfig {
        EnhancedShadowConfig(radius: 16, offsetY: 8, opacity: 0.25)
    }
    
    static var inner: EnhancedShadowConfig {
        EnhancedShadowConfig(radius: 4, offsetX: 0, offsetY: 2, opacity: 0.15, isInner: true)
    }
}

// MARK: - Background View Components

/// Image background rendering view
struct EnhancedImageBackgroundView: View {
    let config: EnhancedImageBackground
    let size: CGSize
    
    @State private var loadedImage: UIImage?
    
    var body: some View {
        ZStack {
            if let image = loadedImage {
                imageContent(image)
            } else {
                // Placeholder while loading
                Color.gray.opacity(0.2)
            }
            
            // Overlay color
            if let overlayColor = config.overlayColor {
                overlayColor.color.opacity(config.overlayOpacity)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    @ViewBuilder
    private func imageContent(_ uiImage: UIImage) -> some View {
        let image = Image(uiImage: uiImage)
        
        switch config.contentMode {
        case .fill:
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .blur(radius: config.blurRadius)
                .brightness(config.brightness)
                .saturation(config.saturation)
                .opacity(config.opacity)
        case .fit:
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
                .blur(radius: config.blurRadius)
                .brightness(config.brightness)
                .saturation(config.saturation)
                .opacity(config.opacity)
        case .stretch:
            image
                .resizable()
                .frame(width: size.width, height: size.height)
                .blur(radius: config.blurRadius)
                .brightness(config.brightness)
                .saturation(config.saturation)
                .opacity(config.opacity)
        case .tile:
            // Tile pattern
            Canvas { context, canvasSize in
                let imageSize = uiImage.size
                let scale = min(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height) * 0.3
                let tileSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                
                for x in stride(from: 0, to: canvasSize.width, by: tileSize.width) {
                    for y in stride(from: 0, to: canvasSize.height, by: tileSize.height) {
                        context.draw(
                            Image(uiImage: uiImage),
                            in: CGRect(x: x, y: y, width: tileSize.width, height: tileSize.height)
                        )
                    }
                }
            }
            .blur(radius: config.blurRadius)
            .brightness(config.brightness)
            .saturation(config.saturation)
            .opacity(config.opacity)
        }
    }
    
    private func loadImage() {
        // Load from App Group container
        Task {
            if let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppGroupConstants.suiteName
            ) {
                let imagesFolder = containerURL.appendingPathComponent(AppGroupConstants.widgetImagesFolder)
                let imageURL = imagesFolder.appendingPathComponent("\(config.imageId).jpg")
                
                if let data = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.loadedImage = image
                    }
                }
            }
        }
    }
}

/// Glassmorphism background rendering view
struct GlassmorphismBackgroundView: View {
    let config: EnhancedGlassmorphismBackground
    
    var body: some View {
        ZStack {
            // Base blur effect using Material
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Tint overlay
            config.tintColor.color.opacity(config.tintOpacity)
            
            // Noise texture overlay (simulated)
            if config.noiseOpacity > 0 {
                NoiseTextureView(opacity: config.noiseOpacity)
            }
        }
        .overlay(
            // Border
            RoundedRectangle(cornerRadius: 0)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(config.borderOpacity),
                            Color.white.opacity(config.borderOpacity * 0.3),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: config.borderWidth
                )
        )
    }
}

/// Noise texture simulation
struct NoiseTextureView: View {
    let opacity: Double
    
    var body: some View {
        Canvas { context, size in
            for _ in 0..<Int(size.width * size.height * 0.01) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let brightness = CGFloat.random(in: 0..<1)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color(white: brightness, opacity: opacity))
                )
            }
        }
    }
}

/// Pattern background rendering view
struct PatternBackgroundView: View {
    let config: EnhancedPatternBackground
    
    var body: some View {
        ZStack {
            config.baseColor.color
            
            Canvas { context, size in
                let spacing: CGFloat = 20 * config.patternScale
                let patternColor = config.patternColor.color.opacity(config.patternOpacity)
                
                switch config.patternType {
                case .dots:
                    for x in stride(from: spacing / 2, to: size.width, by: spacing) {
                        for y in stride(from: spacing / 2, to: size.height, by: spacing) {
                            context.fill(
                                Circle().path(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)),
                                with: .color(patternColor)
                            )
                        }
                    }
                    
                case .lines:
                    for y in stride(from: 0, to: size.height, by: spacing) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            },
                            with: .color(patternColor),
                            lineWidth: 1
                        )
                    }
                    
                case .grid:
                    // Horizontal lines
                    for y in stride(from: 0, to: size.height, by: spacing) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            },
                            with: .color(patternColor),
                            lineWidth: 0.5
                        )
                    }
                    // Vertical lines
                    for x in stride(from: 0, to: size.width, by: spacing) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                            },
                            with: .color(patternColor),
                            lineWidth: 0.5
                        )
                    }
                    
                case .crosses:
                    for x in stride(from: spacing / 2, to: size.width, by: spacing) {
                        for y in stride(from: spacing / 2, to: size.height, by: spacing) {
                            let crossSize: CGFloat = 6 * config.patternScale
                            context.stroke(
                                Path { path in
                                    path.move(to: CGPoint(x: x, y: y - crossSize / 2))
                                    path.addLine(to: CGPoint(x: x, y: y + crossSize / 2))
                                    path.move(to: CGPoint(x: x - crossSize / 2, y: y))
                                    path.addLine(to: CGPoint(x: x + crossSize / 2, y: y))
                                },
                                with: .color(patternColor),
                                lineWidth: 1
                            )
                        }
                    }
                    
                case .waves:
                    for y in stride(from: spacing, to: size.height, by: spacing * 1.5) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                for x in stride(from: 0, to: size.width, by: 20) {
                                    let controlY = y + (x.truncatingRemainder(dividingBy: 40) == 0 ? -8 : 8)
                                    path.addQuadCurve(
                                        to: CGPoint(x: x + 20, y: y),
                                        control: CGPoint(x: x + 10, y: controlY)
                                    )
                                }
                            },
                            with: .color(patternColor),
                            lineWidth: 1
                        )
                    }
                    
                case .diagonals:
                    for offset in stride(from: -size.height, to: size.width + size.height, by: spacing) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: offset, y: 0))
                                path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                            },
                            with: .color(patternColor),
                            lineWidth: 1
                        )
                    }
                    
                case .chevrons:
                    for y in stride(from: 0, to: size.height + spacing, by: spacing) {
                        for x in stride(from: 0, to: size.width + spacing, by: spacing * 2) {
                            context.stroke(
                                Path { path in
                                    path.move(to: CGPoint(x: x, y: y))
                                    path.addLine(to: CGPoint(x: x + spacing, y: y - spacing / 2))
                                    path.addLine(to: CGPoint(x: x + spacing * 2, y: y))
                                },
                                with: .color(patternColor),
                                lineWidth: 1
                            )
                        }
                    }
                    
                case .circles:
                    for x in stride(from: spacing, to: size.width, by: spacing * 2) {
                        for y in stride(from: spacing, to: size.height, by: spacing * 2) {
                            context.stroke(
                                Circle().path(in: CGRect(
                                    x: x - spacing / 2,
                                    y: y - spacing / 2,
                                    width: spacing,
                                    height: spacing
                                )),
                                with: .color(patternColor),
                                lineWidth: 1
                            )
                        }
                    }
                }
            }
        }
    }
}


