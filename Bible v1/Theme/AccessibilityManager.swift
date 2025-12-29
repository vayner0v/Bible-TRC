//
//  AccessibilityManager.swift
//  Bible v1
//
//  Manages accessibility settings for the app
//  Now integrates with SettingsStore for unified settings management
//

import Foundation
import SwiftUI
import Combine

/// Available font styles for accessibility
enum AccessibleFontStyle: String, CaseIterable, Codable, Identifiable {
    case system = "System Default"
    case openDyslexic = "Dyslexia Friendly"
    case serif = "Serif (Classic)"
    case sansSerif = "Sans Serif (Clean)"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .system: return "Uses your system font settings"
        case .openDyslexic: return "Weighted bottoms help distinguish letters"
        case .serif: return "Traditional style with decorative strokes"
        case .sansSerif: return "Modern, clean appearance"
        }
    }
}

/// Text size multiplier options (legacy - now uses SettingsStore.appUIScaleMultiplier)
enum TextSizeMultiplier: String, CaseIterable, Codable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    case accessibility = "Accessibility"
    
    var id: String { rawValue }
    
    var multiplier: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.2
        case .extraLarge: return 1.4
        case .accessibility: return 1.6
        }
    }
    
    var description: String {
        switch self {
        case .small: return "Compact text size"
        case .medium: return "Default reading size"
        case .large: return "Easier to read"
        case .extraLarge: return "Much larger text"
        case .accessibility: return "Maximum readability"
        }
    }
    
    /// Initialize from a multiplier value
    init(fromMultiplier multiplier: Double) {
        switch multiplier {
        case ..<0.9: self = .small
        case 0.9..<1.1: self = .medium
        case 1.1..<1.3: self = .large
        case 1.3..<1.5: self = .extraLarge
        default: self = .accessibility
        }
    }
}

/// Manages accessibility preferences
/// Integrates with SettingsStore for unified font scale hierarchy
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    private enum Keys {
        static let fontStyle = "accessibility_font_style"
        static let textSize = "accessibility_text_size"
        static let highContrast = "accessibility_high_contrast"
        static let reducedMotion = "accessibility_reduced_motion"
        static let boldText = "accessibility_bold_text"
        static let increaseContrast = "accessibility_increase_contrast"
        static let buttonShapes = "accessibility_button_shapes"
        static let lineSpacing = "accessibility_line_spacing"
    }
    
    // MARK: - Published Properties (Bridged to SettingsStore)
    
    @Published var fontStyle: AccessibleFontStyle {
        didSet {
            defaults.set(fontStyle.rawValue, forKey: Keys.fontStyle)
            Task { @MainActor in
                SettingsStore.shared.accessibleFontStyle = fontStyle
            }
        }
    }
    
    /// Text size - bridged to SettingsStore.appUIScaleMultiplier
    @Published var textSize: TextSizeMultiplier {
        didSet {
            defaults.set(textSize.rawValue, forKey: Keys.textSize)
            Task { @MainActor in
                SettingsStore.shared.appUIScaleMultiplier = textSize.multiplier
                // If not using system size, this applies
                if textSize != .medium {
                    SettingsStore.shared.useSystemTextSize = false
                }
            }
        }
    }
    
    @Published var highContrastEnabled: Bool {
        didSet {
            defaults.set(highContrastEnabled, forKey: Keys.highContrast)
            Task { @MainActor in
                SettingsStore.shared.highContrastEnabled = highContrastEnabled
            }
        }
    }
    
    @Published var reducedMotionEnabled: Bool {
        didSet {
            defaults.set(reducedMotionEnabled, forKey: Keys.reducedMotion)
            Task { @MainActor in
                SettingsStore.shared.reducedMotionEnabled = reducedMotionEnabled
            }
        }
    }
    
    @Published var boldTextEnabled: Bool {
        didSet {
            defaults.set(boldTextEnabled, forKey: Keys.boldText)
            Task { @MainActor in
                SettingsStore.shared.boldTextEnabled = boldTextEnabled
            }
        }
    }
    
    @Published var buttonShapesEnabled: Bool {
        didSet {
            defaults.set(buttonShapesEnabled, forKey: Keys.buttonShapes)
            Task { @MainActor in
                SettingsStore.shared.buttonShapesEnabled = buttonShapesEnabled
            }
        }
    }
    
    @Published var increaseLineSpacing: Bool {
        didSet {
            defaults.set(increaseLineSpacing, forKey: Keys.lineSpacing)
            Task { @MainActor in
                SettingsStore.shared.increaseLineSpacing = increaseLineSpacing
            }
        }
    }
    
    // MARK: - New: Use iOS Text Size Toggle
    
    /// When true, app uses iOS Dynamic Type. When false, uses custom scale.
    @Published var useSystemTextSize: Bool = true {
        didSet {
            Task { @MainActor in
                SettingsStore.shared.useSystemTextSize = useSystemTextSize
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load font style
        if let fontStyleRaw = defaults.string(forKey: Keys.fontStyle),
           let style = AccessibleFontStyle(rawValue: fontStyleRaw) {
            fontStyle = style
        } else {
            fontStyle = .system
        }
        
        // Load text size
        if let textSizeRaw = defaults.string(forKey: Keys.textSize),
           let size = TextSizeMultiplier(rawValue: textSizeRaw) {
            textSize = size
        } else {
            textSize = .medium
        }
        
        // Load boolean settings
        highContrastEnabled = defaults.bool(forKey: Keys.highContrast)
        reducedMotionEnabled = defaults.bool(forKey: Keys.reducedMotion)
        boldTextEnabled = defaults.bool(forKey: Keys.boldText)
        buttonShapesEnabled = defaults.bool(forKey: Keys.buttonShapes)
        increaseLineSpacing = defaults.bool(forKey: Keys.lineSpacing)
        
        // Sync from SettingsStore
        setupSettingsStoreBinding()
    }
    
    /// Set up two-way binding with SettingsStore
    private func setupSettingsStoreBinding() {
        Task { @MainActor in
            let settings = SettingsStore.shared
            
            // Sync initial values from SettingsStore
            self.useSystemTextSize = settings.useSystemTextSize
            
            // Observe SettingsStore changes via objectWillChange
            // Note: @AppStorage properties don't have $ prefix publishers
            settings.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    
                    // Sync values if changed
                    if self.useSystemTextSize != settings.useSystemTextSize {
                        self.useSystemTextSize = settings.useSystemTextSize
                    }
                    if self.boldTextEnabled != settings.boldTextEnabled {
                        self.boldTextEnabled = settings.boldTextEnabled
                    }
                    if self.highContrastEnabled != settings.highContrastEnabled {
                        self.highContrastEnabled = settings.highContrastEnabled
                    }
                    if self.reducedMotionEnabled != settings.reducedMotionEnabled {
                        self.reducedMotionEnabled = settings.reducedMotionEnabled
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Font Helpers
    
    /// Get the appropriate font for body text
    func bodyFont(size: CGFloat = 17) -> Font {
        let adjustedSize = size * textSize.multiplier
        let weight: Font.Weight = boldTextEnabled ? .semibold : .regular
        
        switch fontStyle {
        case .system:
            return .system(size: adjustedSize, weight: weight)
        case .openDyslexic:
            // OpenDyslexic-like characteristics using system font with adjustments
            // In a real app, you'd bundle the OpenDyslexic font
            return .system(size: adjustedSize, weight: weight, design: .rounded)
        case .serif:
            return .system(size: adjustedSize, weight: weight, design: .serif)
        case .sansSerif:
            return .system(size: adjustedSize, weight: weight, design: .default)
        }
    }
    
    /// Get the appropriate font for headings
    func headingFont(size: CGFloat = 22) -> Font {
        let adjustedSize = size * textSize.multiplier
        let weight: Font.Weight = .bold
        
        switch fontStyle {
        case .system:
            return .system(size: adjustedSize, weight: weight)
        case .openDyslexic:
            return .system(size: adjustedSize, weight: weight, design: .rounded)
        case .serif:
            return .system(size: adjustedSize, weight: weight, design: .serif)
        case .sansSerif:
            return .system(size: adjustedSize, weight: weight, design: .default)
        }
    }
    
    /// Get the appropriate font for captions
    func captionFont(size: CGFloat = 13) -> Font {
        let adjustedSize = size * textSize.multiplier
        let weight: Font.Weight = boldTextEnabled ? .medium : .regular
        
        switch fontStyle {
        case .system:
            return .system(size: adjustedSize, weight: weight)
        case .openDyslexic:
            return .system(size: adjustedSize, weight: weight, design: .rounded)
        case .serif:
            return .system(size: adjustedSize, weight: weight, design: .serif)
        case .sansSerif:
            return .system(size: adjustedSize, weight: weight, design: .default)
        }
    }
    
    /// Get scripture font (often different from body)
    func scriptureFont(size: CGFloat = 18) -> Font {
        let adjustedSize = size * textSize.multiplier
        let weight: Font.Weight = boldTextEnabled ? .medium : .regular
        
        switch fontStyle {
        case .system, .sansSerif:
            return .system(size: adjustedSize, weight: weight, design: .serif)
        case .openDyslexic:
            return .system(size: adjustedSize, weight: weight, design: .rounded)
        case .serif:
            return .system(size: adjustedSize, weight: weight, design: .serif)
        }
    }
    
    // MARK: - Line Spacing
    
    var lineSpacingValue: CGFloat {
        increaseLineSpacing ? 8 : 4
    }
    
    // MARK: - Animation
    
    /// Duration for animations (respects reduced motion)
    var animationDuration: Double {
        reducedMotionEnabled ? 0 : 0.3
    }
    
    /// Animation for standard transitions
    var standardAnimation: Animation? {
        reducedMotionEnabled ? nil : .easeInOut(duration: 0.3)
    }
    
    // MARK: - Colors (High Contrast)
    
    /// Foreground color adjusted for contrast
    func foregroundColor(for color: Color, on background: Color = .clear) -> Color {
        highContrastEnabled ? .primary : color
    }
    
    /// Background color adjusted for contrast
    func backgroundColor(for color: Color) -> Color {
        if highContrastEnabled {
            // Return pure white or black depending on color scheme
            return Color(UIColor.systemBackground)
        }
        return color
    }
    
    // MARK: - Button Styling
    
    /// Border width for buttons when shapes are enabled
    var buttonBorderWidth: CGFloat {
        buttonShapesEnabled ? 2 : 0
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        fontStyle = .system
        textSize = .medium
        highContrastEnabled = false
        reducedMotionEnabled = false
        boldTextEnabled = false
        buttonShapesEnabled = false
        increaseLineSpacing = false
        useSystemTextSize = true
        
        // Also reset SettingsStore accessibility settings
        Task { @MainActor in
            SettingsStore.shared.resetAccessibilitySettings()
        }
    }
    
    // MARK: - SettingsStore Integration
    
    /// Get the effective UI font size using the unified hierarchy
    @MainActor
    var effectiveUIFontSize: CGFloat {
        SettingsStore.shared.effectiveUIFontSize
    }
    
    /// Get the app UI scale multiplier
    @MainActor
    var appUIScaleMultiplier: Double {
        get { SettingsStore.shared.appUIScaleMultiplier }
        set { SettingsStore.shared.appUIScaleMultiplier = newValue }
    }
}

// MARK: - View Modifier for Accessible Text

struct AccessibleTextModifier: ViewModifier {
    @ObservedObject private var accessibility = AccessibilityManager.shared
    let style: TextStyle
    
    enum TextStyle {
        case body
        case heading
        case caption
        case scripture
    }
    
    func body(content: Content) -> some View {
        content
            .font(fontForStyle)
            .lineSpacing(accessibility.lineSpacingValue)
    }
    
    private var fontForStyle: Font {
        switch style {
        case .body: return accessibility.bodyFont()
        case .heading: return accessibility.headingFont()
        case .caption: return accessibility.captionFont()
        case .scripture: return accessibility.scriptureFont()
        }
    }
}

extension View {
    func accessibleText(_ style: AccessibleTextModifier.TextStyle = .body) -> some View {
        modifier(AccessibleTextModifier(style: style))
    }
}

// MARK: - Preview Helper

struct AccessibilityPreview: View {
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heading Example")
                .accessibleText(.heading)
            
            Text("This is body text that demonstrates the current accessibility settings. It should be easy to read with the selected font and size.")
                .accessibleText(.body)
            
            Text("\"For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you.\" - Jeremiah 29:11")
                .accessibleText(.scripture)
                .italic()
            
            Text("Caption: Small supporting text")
                .accessibleText(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}



