//
//  SettingsStore.swift
//  Bible v1
//
//  Centralized settings management with unified font scale hierarchy
//

import Foundation
import SwiftUI
import Combine

// #region agent log
/// Debug logging helper for SettingsStore debugging - prints to console for visibility
private func settingsDebugLog(location: String, message: String, data: [String: Any], hypothesisId: String) {
    let dataStr = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    print("🔧 [\(hypothesisId)] \(location): \(message) | \(dataStr)")
    
    let logPath = "/Users/vayner0v/Desktop/Bible /Bible v1/.cursor/debug.log"
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let jsonLine = "{\"location\":\"\(location)\",\"message\":\"\(message)\",\"data\":{\(data.map { "\"\($0.key)\":\"\($0.value)\"" }.joined(separator: ","))},\"timestamp\":\(timestamp),\"hypothesisId\":\"\(hypothesisId)\"}\n"
    if let handle = FileHandle(forWritingAtPath: logPath) {
        handle.seekToEndOfFile()
        if let d = jsonLine.data(using: .utf8) { handle.write(d) }
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logPath, contents: jsonLine.data(using: .utf8))
    }
}
// #endregion

/// Notification style for controlling notification frequency
enum NotificationStyle: String, CaseIterable, Codable, Identifiable {
    case gentle = "Gentle"
    case standard = "Standard"
    case engaged = "Engaged"
    
    var id: String { rawValue }
    
    var maxPerDay: Int {
        switch self {
        case .gentle: return 2
        case .standard: return 5
        case .engaged: return 8
        }
    }
    
    var description: String {
        switch self {
        case .gentle: return "Up to 2 notifications per day"
        case .standard: return "Up to 5 notifications per day"
        case .engaged: return "Up to 8 notifications per day"
        }
    }
}

/// Centralized settings store using unified font scale hierarchy
/// 
/// Font Scale Hierarchy:
/// - Effective Reader Size = (System Dynamic Type) × (App UI Scale) × (Reader Offset)
/// - App UI Scale: Optional multiplier for the whole app UI (only when not using system)
/// - Reader Offset: Applies only to scripture reader
@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    // MARK: - App-Wide Display (Accessibility)
    
    /// When true, app uses iOS Dynamic Type. When false, uses appUIScaleMultiplier
    @AppStorage("useSystemTextSize") private var _useSystemTextSize: Bool = true
    
    var useSystemTextSize: Bool {
        get { _useSystemTextSize }
        set {
            objectWillChange.send()
            _useSystemTextSize = newValue
        }
    }
    
    /// App-wide UI text scale (0.8 - 1.4) - only used when useSystemTextSize is false
    @AppStorage("appUIScaleMultiplier") private var _appUIScaleMultiplier: Double = 1.0
    
    var appUIScaleMultiplier: Double {
        get { _appUIScaleMultiplier }
        set {
            objectWillChange.send()
            _appUIScaleMultiplier = newValue
        }
    }
    
    /// Bold text throughout the app
    @AppStorage("boldTextEnabled") private var _boldTextEnabled: Bool = false
    
    var boldTextEnabled: Bool {
        get { _boldTextEnabled }
        set {
            objectWillChange.send()
            _boldTextEnabled = newValue
        }
    }
    
    /// High contrast mode
    @AppStorage("highContrastEnabled") var highContrastEnabled: Bool = false
    
    /// Reduce motion/animations
    @AppStorage("reducedMotionEnabled") var reducedMotionEnabled: Bool = false
    
    /// Show button shapes for better visibility
    @AppStorage("buttonShapesEnabled") var buttonShapesEnabled: Bool = false
    
    /// Increase line spacing throughout app
    @AppStorage("increaseLineSpacing") var increaseLineSpacing: Bool = false
    
    /// Accessible font style for app UI
    @AppStorage("accessibleFontStyle") private var accessibleFontStyleRaw: String = "System Default"
    
    var accessibleFontStyle: AccessibleFontStyle {
        get { AccessibleFontStyle(rawValue: accessibleFontStyleRaw) ?? .system }
        set { accessibleFontStyleRaw = newValue.rawValue }
    }
    
    // MARK: - Reader-Specific (Reading)
    
    /// Reader text offset multiplier (0.70 - 2.0) - applies on top of app scale
    @AppStorage("readerTextOffset") private var _readerTextOffset: Double = 1.0
    
    var readerTextOffset: Double {
        get {
            // #region agent log
            settingsDebugLog(location: "SettingsStore.readerTextOffset.get", message: "Getting readerTextOffset", data: ["storedValue": _readerTextOffset], hypothesisId: "A,D")
            // #endregion
            return _readerTextOffset
        }
        set {
            // #region agent log
            settingsDebugLog(location: "SettingsStore.readerTextOffset.set", message: "Setting readerTextOffset", data: ["oldValue": _readerTextOffset, "newValue": newValue], hypothesisId: "D")
            // #endregion
            objectWillChange.send()
            _readerTextOffset = newValue
        }
    }
    
    /// Reader font family
    @AppStorage("readerFontFamily") private var readerFontFamilyRaw: String = "serif"
    
    var readerFontFamily: ReadingFont {
        get { ReadingFont(rawValue: readerFontFamilyRaw) ?? .serif }
        set {
            objectWillChange.send()
            readerFontFamilyRaw = newValue.rawValue
        }
    }
    
    /// Reader line spacing multiplier
    @AppStorage("readerLineSpacing") private var _readerLineSpacing: Double = 1.4
    
    var readerLineSpacing: Double {
        get { _readerLineSpacing }
        set {
            objectWillChange.send()
            _readerLineSpacing = newValue
        }
    }
    
    /// Show verse numbers in reader
    @AppStorage("showVerseNumbers") private var _showVerseNumbers: Bool = true
    
    var showVerseNumbers: Bool {
        get { _showVerseNumbers }
        set {
            objectWillChange.send()
            _showVerseNumbers = newValue
        }
    }
    
    /// Show paragraph mode (vs verse-by-verse)
    @AppStorage("paragraphMode") var paragraphMode: Bool = false
    
    /// Active reading preset ID (nil = custom)
    @AppStorage("activeReadingPreset") var activePresetId: String?
    
    /// Text alignment in reader
    @AppStorage("readerTextAlignment") private var readerTextAlignmentRaw: String = "leading"
    
    var readerTextAlignment: TextAlignment {
        get {
            switch readerTextAlignmentRaw {
            case "center": return .center
            case "trailing": return .trailing
            default: return .leading
            }
        }
        set {
            switch newValue {
            case .center: readerTextAlignmentRaw = "center"
            case .trailing: readerTextAlignmentRaw = "trailing"
            default: readerTextAlignmentRaw = "leading"
            }
        }
    }
    
    // MARK: - Theme
    
    /// Selected app theme
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = "system"
    
    var selectedTheme: AppTheme {
        get { AppTheme(rawValue: selectedThemeRaw) ?? .system }
        set {
            objectWillChange.send()
            selectedThemeRaw = newValue.rawValue
            // Also update ThemeManager directly to ensure immediate sync
            ThemeManager.shared.selectedTheme = newValue
        }
    }
    
    // MARK: - Audio Settings
    
    /// Preferred voice type (premium AI vs built-in)
    @AppStorage("audio_preferred_voice_type") private var preferredVoiceTypeRaw: String = "premium"
    
    var preferredVoiceType: PreferredVoiceType {
        get { PreferredVoiceType(rawValue: preferredVoiceTypeRaw) ?? .premium }
        set { preferredVoiceTypeRaw = newValue.rawValue }
    }
    
    /// Selected built-in voice identifier
    @AppStorage("audio_selected_builtin_voice") var selectedBuiltinVoiceId: String = ""
    
    /// Speech rate for system TTS (0.0 - 1.0)
    @AppStorage("audio_speech_rate") var speechRate: Double = 0.5
    
    /// Per-voice speed overrides (JSON encoded)
    @AppStorage("audio_per_voice_speeds") private var perVoiceSpeedsData: Data = Data()
    
    var perVoiceSpeeds: [String: Float] {
        get {
            (try? JSONDecoder().decode([String: Float].self, from: perVoiceSpeedsData)) ?? [:]
        }
        set {
            perVoiceSpeedsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    /// Enable immersive listening mode
    @AppStorage("audio_immersive_mode_enabled") var immersiveModeEnabled: Bool = true
    
    /// Auto-continue to next chapter
    @AppStorage("audio_auto_continue_chapter") var autoContinueToNextChapter: Bool = true
    
    /// Normalize audio loudness
    @AppStorage("audio_normalize_loudness") var normalizeLoudness: Bool = false
    
    // MARK: - Immersive Mode Settings
    
    /// Auto-hide UI delay in seconds
    @AppStorage("immersive_auto_hide_delay") var immersiveAutoHideDelay: Double = 3.0
    
    /// Animation style for immersive mode
    @AppStorage("immersive_animation_style") private var immersiveAnimationStyleRaw: String = "gentle"
    
    var immersiveAnimationStyle: ImmersiveAnimationStyle {
        get { ImmersiveAnimationStyle(rawValue: immersiveAnimationStyleRaw) ?? .gentle }
        set { immersiveAnimationStyleRaw = newValue.rawValue }
    }
    
    /// Keep screen on during immersive mode
    @AppStorage("immersive_keep_screen_on") var immersiveKeepScreenOn: Bool = true
    
    /// Allow background audio in immersive mode
    @AppStorage("immersive_background_audio") var immersiveBackgroundAudio: Bool = true
    
    // MARK: - Downloads Settings
    
    /// Download only on Wi-Fi
    @AppStorage("download_wifi_only") var downloadWifiOnly: Bool = true
    
    /// Enable background downloads
    @AppStorage("download_background_enabled") var backgroundDownloadEnabled: Bool = true
    
    // MARK: - Notifications
    
    /// Master notification style
    @AppStorage("notification_style") private var notificationStyleRaw: String = "standard"
    
    var notificationStyle: NotificationStyle {
        get { NotificationStyle(rawValue: notificationStyleRaw) ?? .standard }
        set { notificationStyleRaw = newValue.rawValue }
    }
    
    // MARK: - Data Export
    
    /// Last data export date
    @AppStorage("lastDataExportDate") private var lastDataExportTimestamp: Double = 0
    
    var lastDataExportDate: Date? {
        get { lastDataExportTimestamp > 0 ? Date(timeIntervalSince1970: lastDataExportTimestamp) : nil }
        set { lastDataExportTimestamp = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    // MARK: - UI State (Settings Screen)
    
    /// Expanded state for collapsible sections
    @AppStorage("settings_data_expanded") var dataExpanded: Bool = false
    @AppStorage("settings_about_expanded") var aboutExpanded: Bool = false
    @AppStorage("settings_developer_expanded") var developerExpanded: Bool = false
    
    // MARK: - Computed Effective Sizes
    
    /// Base system font size from Dynamic Type
    var systemBaseFontSize: CGFloat {
        UIFont.preferredFont(forTextStyle: .body).pointSize
    }
    
    /// Effective font size for app UI (menus, settings, hub screens)
    /// Uses Dynamic Type directly when useSystemTextSize is true
    var effectiveUIFontSize: CGFloat {
        let baseSize = systemBaseFontSize
        if useSystemTextSize {
            return baseSize
        }
        return baseSize * appUIScaleMultiplier
    }
    
    /// Effective font size for scripture reader
    /// Combines System Dynamic Type × App UI Scale × Reader Offset
    var effectiveReaderFontSize: CGFloat {
        let baseSize = systemBaseFontSize
        let appScale = useSystemTextSize ? 1.0 : appUIScaleMultiplier
        return baseSize * appScale * readerTextOffset
    }
    
    /// App UI scale multiplier (for use in reader computation)
    /// Returns 1.0 if using system text size
    var effectiveAppScale: CGFloat {
        useSystemTextSize ? 1.0 : appUIScaleMultiplier
    }
    
    /// Line spacing value based on settings
    var effectiveLineSpacing: CGFloat {
        increaseLineSpacing ? 8 : 4
    }
    
    /// Animation duration respecting reduced motion
    var animationDuration: Double {
        reducedMotionEnabled ? 0 : 0.3
    }
    
    /// Standard animation respecting reduced motion
    var standardAnimation: Animation? {
        reducedMotionEnabled ? nil : .easeInOut(duration: 0.3)
    }
    
    // MARK: - Fonts
    
    /// Get font for scripture verses
    var verseFont: Font {
        readerFontFamily.font(size: effectiveReaderFontSize, weight: boldTextEnabled ? .medium : .regular)
    }
    
    /// Get font for verse numbers
    var verseNumberFont: Font {
        readerFontFamily.font(size: effectiveReaderFontSize * 0.7, weight: .semibold)
    }
    
    /// Get font for reader headings
    var readerHeadingFont: Font {
        readerFontFamily.font(size: effectiveReaderFontSize * 1.3, weight: .bold)
    }
    
    /// Get font for reader subheadings
    var readerSubheadingFont: Font {
        readerFontFamily.font(size: effectiveReaderFontSize * 1.1, weight: .semibold)
    }
    
    // MARK: - Initialization
    
    private init() {
        // Migration: Ensure existing settings are preserved
        migrateExistingSettings()
    }
    
    /// Migrate settings from old keys to new unified store
    private func migrateExistingSettings() {
        let defaults = UserDefaults.standard
        
        // Migrate fontSize to readerTextOffset if needed
        // Old fontSize was absolute (12-32), new is multiplier (0.7-2.0)
        if defaults.object(forKey: "fontSize") != nil && defaults.object(forKey: "readerTextOffset") == nil {
            let oldFontSize = defaults.double(forKey: "fontSize")
            // Convert absolute size to offset (18 is baseline)
            if oldFontSize > 0 {
                readerTextOffset = oldFontSize / 18.0
            }
        }
        
        // Migrate lineSpacing to readerLineSpacing
        if defaults.object(forKey: "lineSpacing") != nil && defaults.object(forKey: "readerLineSpacing") == nil {
            let oldLineSpacing = defaults.double(forKey: "lineSpacing")
            // Old was 0-16 absolute, new is multiplier
            if oldLineSpacing > 0 {
                readerLineSpacing = 1.0 + (oldLineSpacing / 16.0)
            }
        }
        
        // Migrate readingFont
        if let oldFont = defaults.string(forKey: "readingFont"),
           defaults.object(forKey: "readerFontFamily") == nil {
            readerFontFamilyRaw = oldFont
        }
        
        // Migrate accessibility settings
        if let oldTextSize = defaults.string(forKey: "accessibility_text_size"),
           let textSize = TextSizeMultiplier(rawValue: oldTextSize) {
            // Convert TextSizeMultiplier to appUIScaleMultiplier
            appUIScaleMultiplier = textSize.multiplier
            useSystemTextSize = (textSize == .medium) // Medium means use system
        }
    }
    
    // MARK: - Preset Management
    
    /// Apply a reading preset
    func applyPreset(_ preset: ReadingPreset) {
        readerFontFamily = ReadingFont(rawValue: preset.fontFamily) ?? .serif
        readerTextOffset = preset.textOffset
        readerLineSpacing = preset.lineSpacing
        if let theme = preset.theme {
            selectedTheme = theme
        }
        activePresetId = preset.id
    }
    
    /// Clear active preset (going custom)
    func clearActivePreset() {
        activePresetId = nil
    }
    
    /// Check if current settings match a preset
    func matchesPreset(_ preset: ReadingPreset) -> Bool {
        guard readerFontFamilyRaw == preset.fontFamily,
              abs(readerTextOffset - preset.textOffset) < 0.01,
              abs(readerLineSpacing - preset.lineSpacing) < 0.01 else {
            return false
        }
        if let theme = preset.theme {
            return selectedTheme == theme
        }
        return true
    }
    
    // MARK: - Per-Voice Speed
    
    /// Get speed for a specific voice (returns global if no override)
    func speedForVoice(_ voiceId: String) -> Float {
        perVoiceSpeeds[voiceId] ?? Float(speechRate)
    }
    
    /// Set speed override for a specific voice
    func setSpeedForVoice(_ voiceId: String, speed: Float) {
        var speeds = perVoiceSpeeds
        speeds[voiceId] = speed
        perVoiceSpeeds = speeds
    }
    
    /// Clear speed override for a voice (use global)
    func clearSpeedForVoice(_ voiceId: String) {
        var speeds = perVoiceSpeeds
        speeds.removeValue(forKey: voiceId)
        perVoiceSpeeds = speeds
    }
    
    // MARK: - Reset Functions
    
    /// Reset reader settings to defaults
    func resetReaderSettings() {
        // #region agent log
        settingsDebugLog(location: "SettingsStore.resetReaderSettings", message: "Resetting reader settings", data: ["currentOffset": _readerTextOffset, "willSetTo": 1.0], hypothesisId: "D")
        // #endregion
        readerTextOffset = 1.0
        readerFontFamilyRaw = "serif"
        readerLineSpacing = 1.4
        showVerseNumbers = true
        paragraphMode = false
        readerTextAlignmentRaw = "leading"
        activePresetId = nil
    }
    
    /// Reset accessibility settings to defaults
    func resetAccessibilitySettings() {
        useSystemTextSize = true
        appUIScaleMultiplier = 1.0
        boldTextEnabled = false
        highContrastEnabled = false
        reducedMotionEnabled = false
        buttonShapesEnabled = false
        increaseLineSpacing = false
        accessibleFontStyleRaw = "System Default"
    }
    
    /// Reset audio settings to defaults
    func resetAudioSettings() {
        preferredVoiceTypeRaw = "premium"
        speechRate = 0.5
        perVoiceSpeedsData = Data()
        immersiveModeEnabled = true
        autoContinueToNextChapter = true
        normalizeLoudness = false
    }
    
    /// Reset immersive mode settings to defaults
    func resetImmersiveModeSettings() {
        immersiveAutoHideDelay = 3.0
        immersiveAnimationStyleRaw = "gentle"
        immersiveKeepScreenOn = true
        immersiveBackgroundAudio = true
    }
    
    /// Reset all settings to defaults
    func resetAllSettings() {
        resetReaderSettings()
        resetAccessibilitySettings()
        resetAudioSettings()
        resetImmersiveModeSettings()
        selectedThemeRaw = "system"
        downloadWifiOnly = true
        backgroundDownloadEnabled = true
        notificationStyleRaw = "standard"
    }
}

// MARK: - Immersive Animation Style

enum ImmersiveAnimationStyle: String, CaseIterable, Identifiable {
    case none = "none"
    case gentle = "gentle"
    case dynamic = "dynamic"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .gentle: return "Gentle"
        case .dynamic: return "Dynamic"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "No animations"
        case .gentle: return "Subtle, calming animations"
        case .dynamic: return "More expressive movements"
        }
    }
}

// MARK: - Preview Helpers

extension SettingsStore {
    /// Create a preview instance with custom settings
    static func preview(
        useSystemTextSize: Bool = true,
        appUIScaleMultiplier: Double = 1.0,
        readerTextOffset: Double = 1.0
    ) -> SettingsStore {
        let store = SettingsStore.shared
        store.useSystemTextSize = useSystemTextSize
        store.appUIScaleMultiplier = appUIScaleMultiplier
        store.readerTextOffset = readerTextOffset
        return store
    }
}

