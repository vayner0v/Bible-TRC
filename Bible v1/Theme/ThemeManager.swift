//
//  ThemeManager.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI
import Combine

/// Theme family for grouping related themes (e.g., Velvet Light/Dark)
enum ThemeFamily: String, CaseIterable, Identifiable {
    case standard   // System, Light, Dark, Sepia
    case velvet     // Premium: Velvet Light/Dark
    case frostedGlass // Premium: Frosted Glass Light/Dark
    case aurora     // Premium: Aurora Light/Dark
    case custom     // Purchasable: Theme Studio
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .velvet: return "Velvet"
        case .frostedGlass: return "Frosted Glass"
        case .aurora: return "Aurora"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "circle.lefthalf.filled"
        case .velvet: return "sparkles.rectangle.stack"
        case .frostedGlass: return "rectangle.on.rectangle"
        case .aurora: return "sparkles"
        case .custom: return "paintpalette.fill"
        }
    }
    
    /// Whether this theme family requires premium subscription
    var isPremium: Bool {
        switch self {
        case .standard: return false
        case .velvet, .frostedGlass, .aurora: return true
        case .custom: return false // Custom requires separate purchase
        }
    }
    
    /// Whether this theme family requires Theme Studio purchase
    var requiresThemeStudioPurchase: Bool {
        self == .custom
    }
}

/// Available app themes
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    // Standard (Free) themes
    case system
    case light
    case dark
    case sepia
    
    // Premium themes (require subscription)
    case velvetLight
    case velvetDark
    case frostedGlassLight
    case frostedGlassDark
    case auroraLight
    case auroraDark
    
    // Custom theme (requires Theme Studio purchase)
    case custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        case .velvetLight: return "Velvet Light"
        case .velvetDark: return "Velvet Dark"
        case .frostedGlassLight: return "Glass Light"
        case .frostedGlassDark: return "Glass Dark"
        case .auroraLight: return "Aurora Light"
        case .auroraDark: return "Aurora Dark"
        case .custom: return "Custom"
        }
    }
    
    /// Short name for compact UI
    var shortName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        case .velvetLight, .velvetDark: return "Velvet"
        case .frostedGlassLight, .frostedGlassDark: return "Glass"
        case .auroraLight, .auroraDark: return "Aurora"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .sepia: return "book.fill"
        case .velvetLight: return "sparkles.rectangle.stack"
        case .velvetDark: return "sparkles.rectangle.stack.fill"
        case .frostedGlassLight: return "rectangle.on.rectangle"
        case .frostedGlassDark: return "rectangle.on.rectangle.fill"
        case .auroraLight: return "sun.haze"
        case .auroraDark: return "moon.haze"
        case .custom: return "paintpalette.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light, .sepia, .velvetLight, .frostedGlassLight, .auroraLight: return .light
        case .dark, .velvetDark, .frostedGlassDark, .auroraDark, .custom: return .dark
        }
    }
    
    /// The theme family this theme belongs to
    var family: ThemeFamily {
        switch self {
        case .system, .light, .dark, .sepia: return .standard
        case .velvetLight, .velvetDark: return .velvet
        case .frostedGlassLight, .frostedGlassDark: return .frostedGlass
        case .auroraLight, .auroraDark: return .aurora
        case .custom: return .custom
        }
    }
    
    /// Whether this is a premium theme (requires subscription)
    var isPremiumTheme: Bool {
        family.isPremium
    }
    
    /// Whether this theme requires Theme Studio purchase
    var requiresThemeStudioPurchase: Bool {
        family.requiresThemeStudioPurchase
    }
    
    /// Whether this is a dark variant
    var isDarkVariant: Bool {
        switch self {
        case .dark, .velvetDark, .frostedGlassDark, .auroraDark, .custom:
            return true
        default:
            return false
        }
    }
    
    /// Get the light variant of this theme (if applicable)
    var lightVariant: AppTheme? {
        switch self {
        case .velvetLight, .velvetDark: return .velvetLight
        case .frostedGlassLight, .frostedGlassDark: return .frostedGlassLight
        case .auroraLight, .auroraDark: return .auroraLight
        default: return nil
        }
    }
    
    /// Get the dark variant of this theme (if applicable)
    var darkVariant: AppTheme? {
        switch self {
        case .velvetLight, .velvetDark: return .velvetDark
        case .frostedGlassLight, .frostedGlassDark: return .frostedGlassDark
        case .auroraLight, .auroraDark: return .auroraDark
        default: return nil
        }
    }
    
    /// Whether this theme has light/dark variants
    var hasVariants: Bool {
        lightVariant != nil && darkVariant != nil
    }
    
    /// Free themes only (for non-premium users)
    static var freeThemes: [AppTheme] {
        [.system, .light, .dark, .sepia]
    }
    
    /// Premium themes only
    static var premiumThemes: [AppTheme] {
        [.velvetLight, .velvetDark, .frostedGlassLight, .frostedGlassDark, .auroraLight, .auroraDark]
    }
    
    /// Theme families with variants (for premium theme picker)
    static var premiumFamilies: [ThemeFamily] {
        [.velvet, .frostedGlass, .aurora]
    }
    
    /// Corner radius for this theme (premium themes use slightly rounded corners)
    var cornerRadius: CGFloat {
        switch family {
        case .standard: return 12
        case .velvet: return 14
        case .frostedGlass: return 16
        case .aurora: return 14
        case .custom: return 12 // Will be customizable
        }
    }
    
    /// Whether this theme uses glass/blur effects
    var usesGlassEffect: Bool {
        family == .frostedGlass
    }
    
    /// Blur radius for glass effects
    var glassBlurRadius: CGFloat {
        switch self {
        case .frostedGlassLight: return AppColors.FrostedGlassLight.blurRadius
        case .frostedGlassDark: return AppColors.FrostedGlassDark.blurRadius
        default: return 0
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
        case .system:
            return Color(.systemBackground)
        case .light:
            return AppColors.Light.background
        case .dark:
            return AppColors.Dark.background
        case .sepia:
            return AppColors.Sepia.background
        case .velvetLight:
            return AppColors.VelvetLight.background
        case .velvetDark:
            return AppColors.VelvetDark.background
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.background
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.background
        case .auroraLight:
            return AppColors.AuroraLight.background
        case .auroraDark:
            return AppColors.AuroraDark.background
        case .custom:
            return customThemeColors.background
        }
    }
    
    var textColor: Color {
        switch selectedTheme {
        case .system:
            return Color(.label)
        case .light:
            return AppColors.Light.text
        case .dark:
            return AppColors.Dark.text
        case .sepia:
            return AppColors.Sepia.text
        case .velvetLight:
            return AppColors.VelvetLight.text
        case .velvetDark:
            return AppColors.VelvetDark.text
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.text
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.text
        case .auroraLight:
            return AppColors.AuroraLight.text
        case .auroraDark:
            return AppColors.AuroraDark.text
        case .custom:
            return customThemeColors.text
        }
    }
    
    var secondaryTextColor: Color {
        switch selectedTheme {
        case .system:
            return Color(.secondaryLabel)
        case .light:
            return AppColors.Light.secondaryText
        case .dark:
            return AppColors.Dark.secondaryText
        case .sepia:
            return AppColors.Sepia.secondaryText
        case .velvetLight:
            return AppColors.VelvetLight.textMuted
        case .velvetDark:
            return AppColors.VelvetDark.textMuted
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.textMuted
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.textMuted
        case .auroraLight:
            return AppColors.AuroraLight.textMuted
        case .auroraDark:
            return AppColors.AuroraDark.textMuted
        case .custom:
            return customThemeColors.textMuted
        }
    }
    
    var accentColor: Color {
        switch selectedTheme {
        case .system:
            return .accentColor
        case .light:
            return AppColors.Light.accent
        case .dark:
            return AppColors.Dark.accent
        case .sepia:
            return AppColors.Sepia.accent
        case .velvetLight:
            return AppColors.VelvetLight.accent
        case .velvetDark:
            return AppColors.VelvetDark.accent
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.accent
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.accent
        case .auroraLight:
            return AppColors.AuroraLight.accent
        case .auroraDark:
            return AppColors.AuroraDark.accent
        case .custom:
            return customThemeColors.accent
        }
    }
    
    /// Primary color for CTAs and buttons
    var primaryColor: Color {
        switch selectedTheme {
        case .system:
            return .accentColor
        case .light:
            return AppColors.Light.accent
        case .dark:
            return AppColors.Dark.accent
        case .sepia:
            return AppColors.Sepia.accent
        case .velvetLight:
            return AppColors.VelvetLight.primary
        case .velvetDark:
            return AppColors.VelvetDark.primary
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.primary
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.primary
        case .auroraLight:
            return AppColors.AuroraLight.primary
        case .auroraDark:
            return AppColors.AuroraDark.primary
        case .custom:
            return customThemeColors.primary
        }
    }
    
    /// Text color on primary buttons
    var onPrimaryColor: Color {
        switch selectedTheme {
        case .velvetLight:
            return AppColors.VelvetLight.onPrimary
        case .velvetDark:
            return AppColors.VelvetDark.onPrimary
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.onPrimary
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.onPrimary
        case .auroraLight:
            return AppColors.AuroraLight.onPrimary
        case .auroraDark:
            return AppColors.AuroraDark.onPrimary
        case .custom:
            return customThemeColors.onPrimary
        default:
            return .white
        }
    }
    
    var cardBackgroundColor: Color {
        switch selectedTheme {
        case .system:
            return Color(.secondarySystemBackground)
        case .light:
            return AppColors.Light.cardBackground
        case .dark:
            return AppColors.Dark.cardBackground
        case .sepia:
            return AppColors.Sepia.cardBackground
        case .velvetLight:
            return AppColors.VelvetLight.surface
        case .velvetDark:
            return AppColors.VelvetDark.surface
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.glassSurface
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.glassSurface
        case .auroraLight:
            return AppColors.AuroraLight.surface
        case .auroraDark:
            return AppColors.AuroraDark.surface
        case .custom:
            return customThemeColors.surface
        }
    }
    
    /// Elevated surface for cards and modals
    var elevatedSurfaceColor: Color {
        switch selectedTheme {
        case .system:
            return Color(.tertiarySystemBackground)
        case .light:
            return Color.white
        case .dark:
            return Color(red: 0.20, green: 0.20, blue: 0.22)
        case .sepia:
            return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .velvetLight:
            return AppColors.VelvetLight.surfaceElevated
        case .velvetDark:
            return AppColors.VelvetDark.surfaceElevated
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.glassElevated
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.glassElevated
        case .auroraLight:
            return AppColors.AuroraLight.surfaceElevated
        case .auroraDark:
            return AppColors.AuroraDark.surfaceElevated
        case .custom:
            return customThemeColors.surfaceElevated
        }
    }
    
    var dividerColor: Color {
        switch selectedTheme {
        case .system:
            return Color(.separator)
        case .light:
            return AppColors.Light.divider
        case .dark:
            return AppColors.Dark.divider
        case .sepia:
            return AppColors.Sepia.divider
        case .velvetLight:
            return AppColors.VelvetLight.border
        case .velvetDark:
            return AppColors.VelvetDark.border
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.border
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.border
        case .auroraLight:
            return AppColors.AuroraLight.border
        case .auroraDark:
            return AppColors.AuroraDark.border
        case .custom:
            return customThemeColors.border
        }
    }
    
    /// Link color for tappable text
    var linkColor: Color {
        switch selectedTheme {
        case .velvetLight:
            return AppColors.VelvetLight.link
        case .velvetDark:
            return AppColors.VelvetDark.link
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.link
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.link
        case .auroraLight:
            return AppColors.AuroraLight.link
        case .auroraDark:
            return AppColors.AuroraDark.link
        case .custom:
            return customThemeColors.accent
        default:
            return accentColor
        }
    }
    
    /// Success color (green)
    var successColor: Color {
        switch selectedTheme {
        case .velvetLight:
            return AppColors.VelvetLight.success
        case .velvetDark:
            return AppColors.VelvetDark.success
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.success
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.success
        case .auroraLight:
            return AppColors.AuroraLight.success
        case .auroraDark:
            return AppColors.AuroraDark.success
        default:
            return .green
        }
    }
    
    /// Warning color (amber/orange)
    var warningColor: Color {
        switch selectedTheme {
        case .velvetLight:
            return AppColors.VelvetLight.warning
        case .velvetDark:
            return AppColors.VelvetDark.warning
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.warning
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.warning
        case .auroraLight:
            return AppColors.AuroraLight.warning
        case .auroraDark:
            return AppColors.AuroraDark.warning
        default:
            return .orange
        }
    }
    
    /// Error color (red)
    var errorColor: Color {
        switch selectedTheme {
        case .velvetLight:
            return AppColors.VelvetLight.error
        case .velvetDark:
            return AppColors.VelvetDark.error
        case .frostedGlassLight:
            return AppColors.FrostedGlassLight.error
        case .frostedGlassDark:
            return AppColors.FrostedGlassDark.error
        case .auroraLight:
            return AppColors.AuroraLight.error
        case .auroraDark:
            return AppColors.AuroraDark.error
        default:
            return .red
        }
    }
    
    // MARK: - Custom Theme Colors (loaded from SettingsStore)
    
    /// Custom theme color configuration - loaded from user's saved configuration
    private var customThemeColors: CustomThemeColors {
        SettingsStore.shared.customThemeConfig.generatedColors
    }
    
    /// Custom theme corner radius
    var customCornerRadius: CGFloat {
        SettingsStore.shared.customThemeConfig.cornerRadiusValue
    }
    
    /// Whether custom theme uses glass blur
    var customUsesGlassBlur: Bool {
        SettingsStore.shared.customThemeConfig.shouldApplyGlassBlur
    }
    
    /// Custom theme blur radius
    var customBlurRadius: CGFloat {
        SettingsStore.shared.customThemeConfig.blurRadius
    }
    
    // MARK: - Glass Effects (Frosted Glass theme)
    
    /// Whether current theme uses glass/blur effects
    var usesGlassEffect: Bool {
        selectedTheme.usesGlassEffect
    }
    
    /// Blur radius for glass effects
    var glassBlurRadius: CGFloat {
        selectedTheme.glassBlurRadius
    }
    
    /// Background gradient for frosted glass themes
    var frostedGlassGradient: LinearGradient? {
        switch selectedTheme {
        case .frostedGlassLight:
            return LinearGradient(
                colors: [AppColors.FrostedGlassLight.bgGradientA, AppColors.FrostedGlassLight.bgGradientB],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .frostedGlassDark:
            return LinearGradient(
                colors: [AppColors.FrostedGlassDark.bgGradientA, AppColors.FrostedGlassDark.bgGradientB],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return nil
        }
    }
    
    // MARK: - Aurora Gradients
    
    /// Aurora gradient for special effects
    var auroraGradient: LinearGradient? {
        switch selectedTheme {
        case .auroraLight:
            return LinearGradient(
                colors: [AppColors.AuroraLight.gradientStart, AppColors.AuroraLight.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .auroraDark:
            return LinearGradient(
                colors: [AppColors.AuroraDark.gradientStart, AppColors.AuroraDark.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return nil
        }
    }
    
    /// Secondary color for Aurora theme (violet)
    var auroraSecondaryColor: Color? {
        switch selectedTheme {
        case .auroraLight:
            return AppColors.AuroraLight.secondary
        case .auroraDark:
            return AppColors.AuroraDark.secondary
        default:
            return nil
        }
    }
    
    // MARK: - Hub Colors
    
    /// Gradient for Hub feature tiles
    var hubTileGradient: LinearGradient {
        // Use aurora gradient for aurora themes
        if let aurora = auroraGradient {
            return aurora
        }
        
        // Use frosted glass gradient for glass themes
        if let glass = frostedGlassGradient {
            return glass
        }
        
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
        case .velvetLight:
            return LinearGradient(
                colors: [
                    AppColors.VelvetLight.surfaceElevated,
                    AppColors.VelvetLight.surface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .velvetDark:
            return LinearGradient(
                colors: [
                    AppColors.VelvetDark.surfaceElevated,
                    AppColors.VelvetDark.surface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .custom:
            return LinearGradient(
                colors: [elevatedSurfaceColor, cardBackgroundColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
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
        // For aurora themes, use the violet accent
        if let secondary = auroraSecondaryColor {
            return secondary
        }
        
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.65, green: 0.45, blue: 0.30)
        case .dark:
            return Color(red: 0.50, green: 0.70, blue: 0.95)
        case .light:
            return Color(red: 0.30, green: 0.55, blue: 0.85)
        case .velvetLight, .velvetDark:
            return accentColor
        case .frostedGlassLight, .frostedGlassDark:
            return accentColor.opacity(0.9)
        case .custom:
            return accentColor.opacity(0.8)
        default:
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
        case .velvetLight, .velvetDark:
            return accentColor
        case .frostedGlassLight, .frostedGlassDark:
            return primaryColor
        case .auroraLight, .auroraDark:
            return AppColors.AuroraLight.accentTeal
        case .custom:
            return accentColor
        default:
            return Color.accentColor
        }
    }
    
    /// Shadow color appropriate for each theme
    var hubShadowColor: Color {
        switch selectedTheme {
        case .sepia:
            return Color(red: 0.40, green: 0.35, blue: 0.25).opacity(0.15)
        case .dark, .velvetDark, .frostedGlassDark, .auroraDark:
            return Color.black.opacity(0.4)
        case .light, .velvetLight, .frostedGlassLight, .auroraLight:
            return Color.black.opacity(0.08)
        case .custom:
            return Color.black.opacity(selectedTheme.isDarkVariant ? 0.4 : 0.08)
        default:
            return Color.black.opacity(0.1)
        }
    }
    
    /// Elevated surface color for Hub cards
    var hubElevatedSurface: Color {
        elevatedSurfaceColor
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
