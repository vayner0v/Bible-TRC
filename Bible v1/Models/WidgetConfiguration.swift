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
}

