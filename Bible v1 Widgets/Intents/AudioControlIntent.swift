//
//  AudioControlIntent.swift
//  Bible v1 Widgets
//
//  App Intent for controlling audio playback from Live Activity
//  Executes in background without opening the app
//

import AppIntents
import Foundation

/// App Intent for handling audio controls from Live Activity
/// This intent runs in the background without opening the app
struct AudioControlIntent: AppIntent {
    static var title: LocalizedStringResource = "Control Bible Audio"
    static var description = IntentDescription("Control Bible audio playback")
    
    // CRITICAL: This prevents the app from opening when the intent runs
    static var openAppWhenRun: Bool = false
    
    enum Action: String, AppEnum {
        case play = "play"
        case pause = "pause"
        case toggle = "toggle"
        case next = "next"
        case previous = "previous"
        case stop = "stop"
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Audio Action"
        static var caseDisplayRepresentations: [Action: DisplayRepresentation] = [
            .play: "Play",
            .pause: "Pause",
            .toggle: "Toggle Play/Pause",
            .next: "Next Verse",
            .previous: "Previous Verse",
            .stop: "Stop"
        ]
    }
    
    @Parameter(title: "Action")
    var action: Action
    
    init() {
        self.action = .toggle
    }
    
    init(action: Action) {
        self.action = action
    }
    
    func perform() async throws -> some IntentResult {
        // Store the action in shared App Group UserDefaults
        let defaults = UserDefaults(suiteName: "group.vaynerov.Bible-v1")
        defaults?.set(action.rawValue, forKey: "pendingAudioAction")
        defaults?.set(Date().timeIntervalSince1970, forKey: "pendingAudioActionTimestamp")
        defaults?.synchronize()
        
        // Post a Darwin notification to wake up the main app process
        // This allows the app to handle the action even in background
        let notificationName = "com.vaynerov.biblev1.audioControl" as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName),
            nil,
            nil,
            true
        )
        
        return .result()
    }
}

// MARK: - AI Cancel Intent

/// App Intent for cancelling AI generation from Live Activity
struct AICancelIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancel AI Generation"
    static var description = IntentDescription("Cancel the current AI generation")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.vaynerov.Bible-v1")
        defaults?.set(true, forKey: "cancelAIGeneration")
        defaults?.set(Date().timeIntervalSince1970, forKey: "cancelAIGenerationTimestamp")
        defaults?.synchronize()
        
        // Post Darwin notification
        let notificationName = "com.vaynerov.biblev1.aiControl" as CFString
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName),
            nil,
            nil,
            true
        )
        
        return .result()
    }
}



