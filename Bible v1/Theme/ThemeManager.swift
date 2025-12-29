//
//  ThemeManager.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI
import Combine

/// Available app themes
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark
    case sepia
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .sepia: return "book.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        case .sepia: return .light
        }
    }
}

/// Available font families for reading
enum ReadingFont: String, CaseIterable, Identifiable, Codable {
    case system
    case serif
    case georgia
    case palatino
    case newYork
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Serif"
        case .georgia: return "Georgia"
        case .palatino: return "Palatino"
        case .newYork: return "New York"
        }
    }
    
    /// Font category for grouping in UI
    var category: FontCategory {
        switch self {
        case .system: return .sansSerif
        case .serif, .georgia, .palatino, .newYork: return .serif
        }
    }
    
    enum FontCategory: String, CaseIterable {
        case serif = "Serif"
        case sansSerif = "Sans-Serif"
    }
    
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
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

/// Manages app-wide theme settings
/// Now integrates with SettingsStore for unified settings management
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // Keys for UserDefaults (legacy, kept for migration)
    private enum Keys {
        static let selectedTheme = "selectedTheme"
        static let paragraphSpacing = "paragraphSpacing"
    }
    
    // MARK: - Published Properties
    
    /// Selected theme - bridged to SettingsStore
    /// Note: This is kept in sync with SettingsStore.selectedTheme
    /// SettingsStore is the source of truth and updates ThemeManager directly
    @Published var selectedTheme: AppTheme {
        didSet {
            guard oldValue != selectedTheme else { return }
            // Legacy: save directly for backward compatibility
            defaults.set(selectedTheme.rawValue, forKey: Keys.selectedTheme)
        }
    }
    
    @Published var paragraphSpacing: Double {
        didSet {
            defaults.set(paragraphSpacing, forKey: Keys.paragraphSpacing)
        }
    }
    
    // MARK: - SettingsStore Forwarding Properties
    // These properties forward to SettingsStore to ensure single source of truth
    // and proper synchronization between Read tab and Settings tab
    
    /// Reading font - forwards to SettingsStore.readerFontFamily
    @MainActor
    var readingFont: ReadingFont {
        get { SettingsStore.shared.readerFontFamily }
        set {
            objectWillChange.send()
            SettingsStore.shared.readerFontFamily = newValue
        }
    }
    
    /// Font size - computed from SettingsStore's effectiveReaderFontSize
    /// This is read-only to prevent circular sync issues
    @MainActor
    var fontSize: Double {
        SettingsStore.shared.effectiveReaderFontSize
    }
    
    /// Line spacing - forwards to SettingsStore, converted for legacy compatibility
    /// Uses the same scale as SettingsStore.readerLineSpacing (multiplier)
    @MainActor
    var lineSpacing: Double {
        get {
            // Convert multiplier to legacy absolute value (where 6 = 1.4x)
            (SettingsStore.shared.readerLineSpacing - 1.0) * 16.0
        }
        set {
            objectWillChange.send()
            // Convert legacy absolute value to multiplier
            SettingsStore.shared.readerLineSpacing = 1.0 + (newValue / 16.0)
        }
    }
    
    // Font size limits (for backward compatibility with any legacy code)
    let minFontSize: Double = 12
    let maxFontSize: Double = 32
    
    // Line spacing limits
    let minLineSpacing: Double = 0
    let maxLineSpacing: Double = 16
    
    private init() {
        // Load saved theme or use default
        let themeString = defaults.string(forKey: Keys.selectedTheme) ?? AppTheme.system.rawValue
        self.selectedTheme = AppTheme(rawValue: themeString) ?? .system
        
        self.paragraphSpacing = defaults.object(forKey: Keys.paragraphSpacing) as? Double ?? 12
        
        // Set up observation of SettingsStore changes
        setupSettingsStoreBinding()
    }
    
    /// Observe SettingsStore for changes and notify ThemeManager observers
    private func setupSettingsStoreBinding() {
        // This ensures views using ThemeManager refresh when SettingsStore changes
        Task { @MainActor in
            let settings = SettingsStore.shared
            
            // Observe SettingsStore changes via objectWillChange
            settings.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Trigger ThemeManager's objectWillChange to update all observers
                    // This ensures views using ThemeManager refresh when SettingsStore changes
                    self.objectWillChange.send()
                    
                    // Sync theme if changed (theme is the only bidirectional sync needed)
                    if self.selectedTheme != settings.selectedTheme {
                        self.selectedTheme = settings.selectedTheme
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Colors
    
    var backgroundColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.96, green: 0.93, blue: 0.87)
        case .dark:
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .light:
            return Color(red: 0.99, green: 0.99, blue: 0.99)
        case .system:
            return Color(.systemBackground)
        }
    }
    
    var textColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.24, green: 0.20, blue: 0.15)
        case .dark:
            return Color(red: 0.92, green: 0.92, blue: 0.92)
        case .light:
            return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .system:
            return Color(.label)
        }
    }
    
    var secondaryTextColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.45, green: 0.40, blue: 0.32)
        case .dark:
            return Color(red: 0.60, green: 0.60, blue: 0.60)
        case .light:
            return Color(red: 0.45, green: 0.45, blue: 0.45)
        case .system:
            return Color(.secondaryLabel)
        }
    }
    
    var accentColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.55, green: 0.35, blue: 0.20)
        case .dark:
            return Color(red: 0.40, green: 0.60, blue: 0.90)
        case .light:
            return Color(red: 0.20, green: 0.45, blue: 0.75)
        case .system:
            return .accentColor
        }
    }
    
    var cardBackgroundColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.94, green: 0.90, blue: 0.82)
        case .dark:
            return Color(red: 0.17, green: 0.17, blue: 0.18)
        case .light:
            return Color(red: 0.96, green: 0.96, blue: 0.97)
        case .system:
            return Color(.secondarySystemBackground)
        }
    }
    
    var dividerColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.85, green: 0.80, blue: 0.70)
        case .dark:
            return Color(red: 0.25, green: 0.25, blue: 0.27)
        case .light:
            return Color(red: 0.88, green: 0.88, blue: 0.88)
        case .system:
            return Color(.separator)
        }
    }
    
    // MARK: - Hub Colors
    
    /// Gradient for Hub feature tiles
    var hubTileGradient: LinearGradient {
        switch selectedTheme {
        case .sepia:
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.91, blue: 0.84),
                    Color(red: 0.92, green: 0.88, blue: 0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.18, blue: 0.20),
                    Color(red: 0.14, green: 0.14, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .light:
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.94, green: 0.94, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .system:
            return LinearGradient(
                colors: [
                    Color(.tertiarySystemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    /// Secondary accent color for Hub tiles
    var hubTileSecondaryColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.65, green: 0.45, blue: 0.30)
        case .dark:
            return Color(red: 0.50, green: 0.70, blue: 0.95)
        case .light:
            return Color(red: 0.30, green: 0.55, blue: 0.85)
        case .system:
            return Color.accentColor.opacity(0.8)
        }
    }
    
    /// Glow effect color for Hub icons and animations
    var hubGlowColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.70, green: 0.50, blue: 0.25)
        case .dark:
            return Color(red: 0.45, green: 0.65, blue: 0.95)
        case .light:
            return Color(red: 0.25, green: 0.50, blue: 0.80)
        case .system:
            return Color.accentColor
        }
    }
    
    /// Shadow color appropriate for each theme
    var hubShadowColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.40, green: 0.35, blue: 0.25).opacity(0.15)
        case .dark:
            return Color.black.opacity(0.4)
        case .light:
            return Color.black.opacity(0.08)
        case .system:
            return Color.black.opacity(0.1)
        }
    }
    
    /// Elevated surface color for Hub cards
    var hubElevatedSurface: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .dark:
            return Color(red: 0.20, green: 0.20, blue: 0.22)
        case .light:
            return Color.white
        case .system:
            return Color(.systemBackground)
        }
    }
    
    // MARK: - Theme Gradients
    
    /// Subtle background gradient for cards and sections
    var subtleBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundColor, cardBackgroundColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Accent gradient for buttons and highlighted elements
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor, accentColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Premium/feature gradient using accent color variations
    var premiumGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor, accentColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Inverted subtle gradient for variety
    var invertedSubtleGradient: LinearGradient {
        LinearGradient(
            colors: [cardBackgroundColor, backgroundColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Fonts
    
    /// Verse font using unified scale hierarchy from SettingsStore
    /// This now properly uses SettingsStore's computed font size
    var verseFont: Font {
        // Get the effective font size from SettingsStore
        // This combines System Dynamic Type × App UI Scale × Reader Offset
        let settings = SettingsStore.shared
        let size = settings.effectiveReaderFontSize
        let weight: Font.Weight = settings.boldTextEnabled ? .medium : .regular
        return settings.readerFontFamily.font(size: size, weight: weight)
    }
    
    var verseNumberFont: Font {
        let settings = SettingsStore.shared
        let size = settings.effectiveReaderFontSize * 0.7
        return settings.readerFontFamily.font(size: size, weight: .semibold)
    }
    
    var headingFont: Font {
        let settings = SettingsStore.shared
        let size = settings.effectiveReaderFontSize * 1.3
        return settings.readerFontFamily.font(size: size, weight: .bold)
    }
    
    var subheadingFont: Font {
        let settings = SettingsStore.shared
        let size = settings.effectiveReaderFontSize * 1.1
        return settings.readerFontFamily.font(size: size, weight: .semibold)
    }
    
    // MARK: - Methods
    
    /// Increase font size by adjusting SettingsStore.readerTextOffset
    @MainActor
    func increaseFontSize() {
        let currentOffset = SettingsStore.shared.readerTextOffset
        let step = 0.1
        SettingsStore.shared.readerTextOffset = min(currentOffset + step, 2.0)
    }
    
    /// Decrease font size by adjusting SettingsStore.readerTextOffset
    @MainActor
    func decreaseFontSize() {
        let currentOffset = SettingsStore.shared.readerTextOffset
        let step = 0.1
        SettingsStore.shared.readerTextOffset = max(currentOffset - step, 0.70)
    }
    
    @MainActor
    func resetToDefaults() {
        selectedTheme = .system
        paragraphSpacing = 12
        
        // Reset SettingsStore (this handles font, size, spacing)
        SettingsStore.shared.resetReaderSettings()
    }
    
    // MARK: - SettingsStore Integration Helpers
    
    /// Get effective reader font size from SettingsStore hierarchy
    @MainActor
    var effectiveReaderFontSize: CGFloat {
        SettingsStore.shared.effectiveReaderFontSize
    }
    
    /// Get reader text offset multiplier
    @MainActor
    var readerTextOffset: Double {
        get { SettingsStore.shared.readerTextOffset }
        set { SettingsStore.shared.readerTextOffset = newValue }
    }
    
    /// Get reader line spacing multiplier
    @MainActor
    var readerLineSpacingMultiplier: Double {
        get { SettingsStore.shared.readerLineSpacing }
        set { SettingsStore.shared.readerLineSpacing = newValue }
    }
}

// MARK: - View Modifiers

struct ThemedBackground: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.backgroundColor)
    }
}

struct ThemedText: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    let isSecondary: Bool
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(isSecondary ? themeManager.secondaryTextColor : themeManager.textColor)
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackground())
    }
    
    func themedText(secondary: Bool = false) -> some View {
        modifier(ThemedText(isSecondary: secondary))
    }
}
