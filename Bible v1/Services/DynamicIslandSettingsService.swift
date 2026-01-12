//
//  DynamicIslandSettingsService.swift
//  Bible v1
//
//  Service for managing Dynamic Island settings with App Groups storage
//

import Foundation
import SwiftUI
import Combine

/// Service for managing Dynamic Island customization settings
/// Uses App Groups UserDefaults for sharing with widget extension
@MainActor
class DynamicIslandSettingsService: ObservableObject {
    static let shared = DynamicIslandSettingsService()
    
    // MARK: - Constants
    
    private let appGroupId = "group.vaynerov.Bible-v1"
    private let settingsKey = "dynamicIslandSettings"
    
    // MARK: - Published Settings
    
    @Published var settings: DynamicIslandSettings {
        didSet {
            saveSettings()
        }
    }
    
    // MARK: - Computed Properties for Bindings
    
    // Audio Settings
    var audioTheme: Binding<DITheme> {
        Binding(
            get: { self.settings.audioTheme },
            set: { self.settings.audioTheme = $0 }
        )
    }
    
    var audioTextSize: Binding<DITextSize> {
        Binding(
            get: { self.settings.audioTextSize },
            set: { self.settings.audioTextSize = $0 }
        )
    }
    
    var audioShowProgress: Binding<Bool> {
        Binding(
            get: { self.settings.audioShowProgress },
            set: { self.settings.audioShowProgress = $0 }
        )
    }
    
    var audioShowVerseText: Binding<Bool> {
        Binding(
            get: { self.settings.audioShowVerseText },
            set: { self.settings.audioShowVerseText = $0 }
        )
    }
    
    var audioCompactMode: Binding<Bool> {
        Binding(
            get: { self.settings.audioCompactMode },
            set: { self.settings.audioCompactMode = $0 }
        )
    }
    
    var audioAnimationsEnabled: Binding<Bool> {
        Binding(
            get: { self.settings.audioAnimationsEnabled },
            set: { self.settings.audioAnimationsEnabled = $0 }
        )
    }
    
    var audioHapticsEnabled: Binding<Bool> {
        Binding(
            get: { self.settings.audioHapticsEnabled },
            set: { self.settings.audioHapticsEnabled = $0 }
        )
    }
    
    // AI Settings
    var aiTheme: Binding<DITheme> {
        Binding(
            get: { self.settings.aiTheme },
            set: { self.settings.aiTheme = $0 }
        )
    }
    
    var aiTextSize: Binding<DITextSize> {
        Binding(
            get: { self.settings.aiTextSize },
            set: { self.settings.aiTextSize = $0 }
        )
    }
    
    var aiShowProgress: Binding<Bool> {
        Binding(
            get: { self.settings.aiShowProgress },
            set: { self.settings.aiShowProgress = $0 }
        )
    }
    
    var aiCompactMode: Binding<Bool> {
        Binding(
            get: { self.settings.aiCompactMode },
            set: { self.settings.aiCompactMode = $0 }
        )
    }
    
    var aiAnimationsEnabled: Binding<Bool> {
        Binding(
            get: { self.settings.aiAnimationsEnabled },
            set: { self.settings.aiAnimationsEnabled = $0 }
        )
    }
    
    // MARK: - Initialization
    
    private init() {
        self.settings = Self.loadSettings()
        setupDarwinNotificationObserver()
        print("DynamicIslandSettingsService: Initialized with Darwin notification observers")
    }
    
    // MARK: - Darwin Notification for Cross-Process Communication
    
    private func setupDarwinNotificationObserver() {
        print("DynamicIslandSettingsService: Setting up Darwin notification observers...")
        
        // Audio control notification
        let audioNotificationName = "com.vaynerov.biblev1.audioControl" as CFString
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, name, _, _ in
                print("DynamicIslandSettingsService: Darwin notification received: \(String(describing: name))")
                guard let observer = observer else {
                    print("DynamicIslandSettingsService: Observer is nil")
                    return
                }
                let service = Unmanaged<DynamicIslandSettingsService>.fromOpaque(observer).takeUnretainedValue()
                // Dispatch to main thread
                DispatchQueue.main.async {
                    Task { @MainActor in
                        service.handleAudioControlNotification()
                    }
                }
            },
            audioNotificationName,
            nil,
            .deliverImmediately
        )
        
        // AI control notification
        let aiNotificationName = "com.vaynerov.biblev1.aiControl" as CFString
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, name, _, _ in
                print("DynamicIslandSettingsService: Darwin AI notification received: \(String(describing: name))")
                guard let observer = observer else { return }
                let service = Unmanaged<DynamicIslandSettingsService>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    Task { @MainActor in
                        service.handleAIControlNotification()
                    }
                }
            },
            aiNotificationName,
            nil,
            .deliverImmediately
        )
        
        print("DynamicIslandSettingsService: Darwin notification observers registered")
    }
    
    private func handleAudioControlNotification() {
        // Read from UserDefaults on background thread first
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            print("DynamicIslandSettingsService: Failed to access App Group UserDefaults")
            return
        }
        
        // Force synchronize to get latest values
        defaults.synchronize()
        
        guard let actionString = defaults.string(forKey: "pendingAudioAction") else {
            print("DynamicIslandSettingsService: No pending audio action found")
            return
        }
        
        // Check timestamp to avoid processing stale actions
        let timestamp = defaults.double(forKey: "pendingAudioActionTimestamp")
        let actionTime = Date(timeIntervalSince1970: timestamp)
        let timeSinceAction = Date().timeIntervalSince(actionTime)
        
        print("DynamicIslandSettingsService: Received action '\(actionString)', age: \(timeSinceAction)s")
        
        guard timeSinceAction < 10.0 else {
            print("DynamicIslandSettingsService: Action is stale, ignoring")
            return // Action is stale
        }
        
        // Clear the pending action
        defaults.removeObject(forKey: "pendingAudioAction")
        defaults.removeObject(forKey: "pendingAudioActionTimestamp")
        defaults.synchronize()
        
        // Execute the action on main actor
        Task { @MainActor in
            let audioService = AudioService.shared
            
            print("DynamicIslandSettingsService: Executing action '\(actionString)'")
            
            switch actionString {
            case "play":
                audioService.resume()
            case "pause":
                audioService.pause()
            case "toggle":
                audioService.togglePlayPause()
            case "next":
                audioService.nextVerse()
            case "previous":
                audioService.previousVerse()
            case "stop":
                audioService.stop()
            default:
                print("DynamicIslandSettingsService: Unknown audio action: \(actionString)")
            }
            
            // Haptic feedback if enabled
            if self.settings.audioHapticsEnabled {
                HapticManager.shared.lightImpact()
            }
            
            // Force a Live Activity update after a short delay to ensure state has changed
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            audioService.forceUpdateLiveActivity()
        }
    }
    
    private func handleAIControlNotification() {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              defaults.bool(forKey: "cancelAIGeneration") else {
            return
        }
        
        // Check timestamp
        let timestamp = defaults.double(forKey: "cancelAIGenerationTimestamp")
        let actionTime = Date(timeIntervalSince1970: timestamp)
        guard Date().timeIntervalSince(actionTime) < 5.0 else {
            return
        }
        
        // Clear the pending action
        defaults.removeObject(forKey: "cancelAIGeneration")
        defaults.removeObject(forKey: "cancelAIGenerationTimestamp")
        defaults.synchronize()
        
        // Cancel AI generation
        TRCAIService.shared.cancel()
        LiveActivityService.shared.cancelAIGeneration()
    }
    
    // MARK: - Persistence
    
    private static func loadSettings() -> DynamicIslandSettings {
        guard let defaults = UserDefaults(suiteName: "group.vaynerov.Bible-v1"),
              let data = defaults.data(forKey: "dynamicIslandSettings"),
              let settings = try? JSONDecoder().decode(DynamicIslandSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    private func saveSettings() {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = try? JSONEncoder().encode(settings) else {
            return
        }
        defaults.set(data, forKey: settingsKey)
        defaults.synchronize()
        
        // Notify widget extension of settings change
        notifySettingsChanged()
    }
    
    private func notifySettingsChanged() {
        let notificationName = "com.vaynerov.biblev1.settingsChanged" as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName),
            nil,
            nil,
            true
        )
    }
    
    // MARK: - Public Methods
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        settings = .default
    }
    
    /// Reset audio settings only
    func resetAudioSettings() {
        let defaultSettings = DynamicIslandSettings.default
        settings.audioTheme = defaultSettings.audioTheme
        settings.audioTextSize = defaultSettings.audioTextSize
        settings.audioShowProgress = defaultSettings.audioShowProgress
        settings.audioShowVerseText = defaultSettings.audioShowVerseText
        settings.audioCompactMode = defaultSettings.audioCompactMode
        settings.audioAnimationsEnabled = defaultSettings.audioAnimationsEnabled
        settings.audioHapticsEnabled = defaultSettings.audioHapticsEnabled
    }
    
    /// Reset AI settings only
    func resetAISettings() {
        let defaultSettings = DynamicIslandSettings.default
        settings.aiTheme = defaultSettings.aiTheme
        settings.aiTextSize = defaultSettings.aiTextSize
        settings.aiShowProgress = defaultSettings.aiShowProgress
        settings.aiCompactMode = defaultSettings.aiCompactMode
        settings.aiAnimationsEnabled = defaultSettings.aiAnimationsEnabled
    }
}

