//
//  LiveActivityService.swift
//  Bible v1
//
//  Manages Live Activities for Dynamic Island integration
//

import Foundation
import ActivityKit
import SwiftUI
import Combine

/// Service for managing Live Activities (Dynamic Island) for AI generation and audio playback
@MainActor
class LiveActivityService: ObservableObject {
    static let shared = LiveActivityService()
    
    // MARK: - Published State
    
    @Published var hasActiveAIActivity: Bool = false
    @Published var hasActiveAudioActivity: Bool = false
    
    // MARK: - Private State
    
    private var aiActivity: Activity<AIGenerationAttributes>?
    private var audioActivity: Activity<BibleAudioAttributes>?
    
    // MARK: - Initialization
    
    private init() {
        // Clean up any stale activities on init
        Task {
            await cleanupStaleActivities()
        }
    }
    
    // MARK: - Activity Availability
    
    /// Check if Live Activities are supported
    var areActivitiesSupported: Bool {
        let authInfo = ActivityAuthorizationInfo()
        print("LiveActivityService: Activities enabled: \(authInfo.areActivitiesEnabled), frequent push: \(authInfo.frequentPushesEnabled)")
        return authInfo.areActivitiesEnabled
    }
    
    /// Check and log activity authorization status
    func checkActivityAuthorization() {
        let authInfo = ActivityAuthorizationInfo()
        print("LiveActivityService: ===== Activity Authorization Status =====")
        print("LiveActivityService: areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
        print("LiveActivityService: frequentPushesEnabled: \(authInfo.frequentPushesEnabled)")
        print("LiveActivityService: Active AI activities: \(Activity<AIGenerationAttributes>.activities.count)")
        print("LiveActivityService: Active Audio activities: \(Activity<BibleAudioAttributes>.activities.count)")
        print("LiveActivityService: =========================================")
        
        // List any existing activities
        for activity in Activity<AIGenerationAttributes>.activities {
            print("LiveActivityService: Existing AI Activity - ID: \(activity.id), State: \(activity.content.state)")
        }
        for activity in Activity<BibleAudioAttributes>.activities {
            print("LiveActivityService: Existing Audio Activity - ID: \(activity.id), State: \(activity.content.state)")
        }
    }
    
    /// Test function to create a simple Live Activity for debugging
    func testLiveActivity() {
        print("LiveActivityService: ===== TESTING LIVE ACTIVITY =====")
        
        let authInfo = ActivityAuthorizationInfo()
        print("LiveActivityService: TEST - Activities enabled: \(authInfo.areActivitiesEnabled)")
        
        if !authInfo.areActivitiesEnabled {
            print("LiveActivityService: TEST - ❌ Live Activities are DISABLED")
            print("LiveActivityService: TEST - User needs to enable in Settings > [App Name] > Live Activities")
            print("LiveActivityService: TEST - Or Settings > Face ID & Passcode > Allow Access When Locked > Live Activities")
            return
        }
        
        // Try to create a simple AI activity
        let attributes = AIGenerationAttributes(
            conversationId: "test-\(UUID().uuidString)",
            mode: "study",
            modeDisplayName: "Study",
            startTime: Date()
        )
        
        let state = AIGenerationAttributes.ContentState.thinking
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(300)),
                pushType: nil
            )
            print("LiveActivityService: TEST - ✅ Successfully created test activity!")
            print("LiveActivityService: TEST - Activity ID: \(activity.id)")
            
            // End it after 5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await activity.end(nil, dismissalPolicy: .immediate)
                print("LiveActivityService: TEST - Ended test activity")
            }
        } catch {
            print("LiveActivityService: TEST - ❌ Failed to create activity: \(error)")
            print("LiveActivityService: TEST - Error details: \(String(describing: error))")
        }
        
        print("LiveActivityService: ===== END TEST =====")
    }
    
    // MARK: - AI Generation Activity
    
    /// Start a new AI generation activity
    func startAIGeneration(conversationId: UUID, mode: String, modeDisplayName: String) {
        print("LiveActivityService: Attempting to start AI generation activity...")
        
        // Check authorization first
        checkActivityAuthorization()
        
        guard areActivitiesSupported else {
            print("LiveActivityService: ❌ Live Activities not supported/enabled on this device")
            print("LiveActivityService: User needs to enable Live Activities in Settings > Face ID & Passcode or Settings > [App Name]")
            return
        }
        
        // End any existing AI activity first and wait for it
        Task {
            await endAIActivity()
            
            // Small delay to ensure cleanup
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            await startAIActivityRequest(conversationId: conversationId, mode: mode, modeDisplayName: modeDisplayName)
        }
    }
    
    private func startAIActivityRequest(conversationId: UUID, mode: String, modeDisplayName: String) async {
        let attributes = AIGenerationAttributes(
            conversationId: conversationId.uuidString,
            mode: mode,
            modeDisplayName: modeDisplayName,
            startTime: Date()
        )
        
        let initialState = AIGenerationAttributes.ContentState.thinking
        
        do {
            print("LiveActivityService: Requesting AI activity with attributes: \(attributes)")
            
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            self.aiActivity = activity
            self.hasActiveAIActivity = true
            print("LiveActivityService: ✅ Started AI generation activity successfully!")
            print("LiveActivityService: Activity ID: \(activity.id)")
        } catch {
            print("LiveActivityService: ❌ Failed to start AI activity: \(error)")
            print("LiveActivityService: Error type: \(type(of: error))")
            if let activityError = error as? ActivityAuthorizationError {
                print("LiveActivityService: Authorization error: \(activityError)")
            }
        }
    }
    
    /// Update AI generation progress with streaming content
    func updateAIProgress(preview: String, estimatedProgress: Double) {
        guard let activity = aiActivity else { return }
        
        let truncatedPreview = String(preview.suffix(100))
        let state = AIGenerationAttributes.ContentState.streaming(
            preview: truncatedPreview.isEmpty ? "Generating..." : truncatedPreview,
            progress: min(0.95, estimatedProgress) // Cap at 95% until complete
        )
        
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }
    
    /// Mark AI generation as complete
    func completeAIGeneration(title: String?, preview: String) {
        guard let activity = aiActivity else { return }
        
        let truncatedPreview = String(preview.prefix(150))
        let state = AIGenerationAttributes.ContentState.complete(
            title: title,
            preview: truncatedPreview
        )
        
        Task {
            // Update to complete state
            await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(60)))
            
            // End the activity after a delay so user can see completion
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await endAIActivity()
        }
    }
    
    /// Cancel AI generation activity (on error or user cancel)
    func cancelAIGeneration() {
        guard let activity = aiActivity else { return }
        
        let state = AIGenerationAttributes.ContentState.error
        
        Task {
            await activity.update(ActivityContent(state: state, staleDate: Date()))
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await endAIActivity()
        }
    }
    
    /// End the AI activity
    private func endAIActivity() async {
        guard let activity = aiActivity else { return }
        
        await activity.end(nil, dismissalPolicy: .immediate)
        self.aiActivity = nil
        self.hasActiveAIActivity = false
        print("LiveActivityService: Ended AI generation activity")
    }
    
    // MARK: - Audio Playback Activity
    
    /// Start audio playback activity
    func startAudioPlayback(
        translationId: String,
        bookName: String,
        chapter: Int,
        reference: String,
        verseText: String,
        currentVerse: Int,
        totalVerses: Int,
        voiceType: String,
        isLoading: Bool = false
    ) {
        print("LiveActivityService: Attempting to start audio playback activity...")
        
        guard areActivitiesSupported else {
            print("LiveActivityService: ❌ Live Activities not supported/enabled")
            return
        }
        
        // End any existing audio activity first
        Task {
            await endAudioActivity()
            
            // Small delay to ensure cleanup
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            await startAudioActivityRequest(
                translationId: translationId,
                bookName: bookName,
                chapter: chapter,
                reference: reference,
                verseText: verseText,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType,
                isLoading: isLoading
            )
        }
    }
    
    private func startAudioActivityRequest(
        translationId: String,
        bookName: String,
        chapter: Int,
        reference: String,
        verseText: String,
        currentVerse: Int,
        totalVerses: Int,
        voiceType: String,
        isLoading: Bool
    ) async {
        let attributes = BibleAudioAttributes(
            translationId: translationId,
            bookName: bookName,
            chapter: chapter
        )
        
        let initialState: BibleAudioAttributes.ContentState
        if isLoading {
            initialState = .loading(
                reference: reference,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType
            )
        } else {
            initialState = .playing(
                reference: reference,
                verseText: verseText,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType
            )
        }
        
        do {
            print("LiveActivityService: Requesting audio activity for: \(reference)")
            
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            self.audioActivity = activity
            self.hasActiveAudioActivity = true
            print("LiveActivityService: ✅ Started audio playback activity successfully!")
            print("LiveActivityService: Activity ID: \(activity.id)")
        } catch {
            print("LiveActivityService: ❌ Failed to start audio activity: \(error)")
            print("LiveActivityService: Error type: \(type(of: error))")
        }
    }
    
    /// Update audio playback state
    func updateAudioState(
        reference: String,
        verseText: String,
        isPlaying: Bool,
        currentVerse: Int,
        totalVerses: Int,
        voiceType: String,
        isLoading: Bool = false
    ) {
        guard let activity = audioActivity else { return }
        
        let state: BibleAudioAttributes.ContentState
        if isLoading {
            state = .loading(
                reference: reference,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType
            )
        } else if isPlaying {
            state = .playing(
                reference: reference,
                verseText: verseText,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType
            )
        } else {
            state = .paused(
                reference: reference,
                verseText: verseText,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType
            )
        }
        
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }
    
    /// Stop audio playback activity
    func stopAudioPlayback() {
        Task {
            await endAudioActivity()
        }
    }
    
    /// End the audio activity
    private func endAudioActivity() async {
        guard let activity = audioActivity else { return }
        
        await activity.end(nil, dismissalPolicy: .immediate)
        self.audioActivity = nil
        self.hasActiveAudioActivity = false
        print("LiveActivityService: Ended audio playback activity")
    }
    
    // MARK: - Cleanup
    
    /// Clean up any stale activities from previous sessions
    private func cleanupStaleActivities() async {
        // Clean up AI activities
        for activity in Activity<AIGenerationAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        
        // Clean up audio activities
        for activity in Activity<BibleAudioAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        
        self.aiActivity = nil
        self.audioActivity = nil
        self.hasActiveAIActivity = false
        self.hasActiveAudioActivity = false
    }
    
    /// End all activities (called on app termination)
    func endAllActivities() {
        Task {
            await endAIActivity()
            await endAudioActivity()
        }
    }
}

