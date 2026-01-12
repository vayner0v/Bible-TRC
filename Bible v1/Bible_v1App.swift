//
//  Bible_v1App.swift
//  Bible v1
//
//  Created by Edward Amirain on 12/16/25.
//

import SwiftUI
import Supabase
import Combine
import UserNotifications
import AVFoundation

@main
struct Bible_v1App: App {
    @StateObject private var navigationManager = WidgetNavigationManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Initialize PromoCodeService early to avoid triggering @Published changes during view updates
        // This ensures the service is fully initialized before any views access it
        _ = PromoCodeService.shared
        
        // Register notification categories for actionable notifications
        AIBackgroundNotificationService.shared.registerNotificationCategories()
        
        // Initialize Dynamic Island settings service (sets up Darwin notification observers)
        _ = DynamicIslandSettingsService.shared
        
        // Check Live Activity authorization status on startup
        Task { @MainActor in
            LiveActivityService.shared.checkActivityAuthorization()
            
            // Uncomment the line below to test Live Activity on app launch:
            // LiveActivityService.shared.testLiveActivity()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationManager)
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }
    
    private func handleURL(_ url: URL) {
        // Handle OAuth callback from Google/Apple Sign-In
        if url.scheme == "biblev1" {
            // Check for audio control actions first
            if url.host == "audio-control" {
                handleAudioControlURL(url)
                return
            }
            
            // Check for AI chat navigation
            if url.host == "ai-chat" {
                handleAIChatURL(url)
                return
            }
            
            // Handle widget deep links
            handleWidgetDeepLink(url)
        } else {
            // Handle OAuth callbacks (only if Supabase is configured)
            if SupabaseService.shared.isConfigured {
                Task {
                    try? await SupabaseService.shared.client.auth.session(from: url)
                }
            }
        }
    }
    
    private func handleAudioControlURL(_ url: URL) {
        let action = url.lastPathComponent
        
        Task { @MainActor in
            let audioService = AudioService.shared
            
            switch action {
            case "toggle":
                audioService.togglePlayPause()
            case "play":
                audioService.resume()
            case "pause":
                audioService.pause()
            case "next":
                audioService.nextVerse()
            case "previous":
                audioService.previousVerse()
            case "stop":
                audioService.stop()
            default:
                print("Unknown audio control action: \(action)")
            }
        }
    }
    
    private func handleAIChatURL(_ url: URL) {
        // Extract conversation ID from path
        let conversationIdString = url.lastPathComponent
        guard let conversationId = UUID(uuidString: conversationIdString) else { return }
        
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .openAIConversation,
                object: nil,
                userInfo: ["conversationId": conversationId]
            )
        }
    }
    
    private func handleWidgetDeepLink(_ url: URL) {
        guard let host = url.host else { return }
        
        switch host {
        case "verse-of-day":
            navigationManager.navigateTo(.verseOfDay)
        case "reading-plan":
            navigationManager.navigateTo(.readingPlan)
        case "prayer":
            navigationManager.navigateTo(.prayer)
        case "habits":
            navigationManager.navigateTo(.habits)
        case "scripture-quote":
            navigationManager.navigateTo(.verseOfDay)
        case "countdown":
            navigationManager.navigateTo(.countdown)
        case "mood-gratitude":
            navigationManager.navigateTo(.moodGratitude)
        case "favorites":
            navigationManager.navigateTo(.favorites)
        default:
            break
        }
    }
}

// MARK: - Widget Navigation Manager

/// Manages navigation from widget deep links
@MainActor
final class WidgetNavigationManager: ObservableObject {
    static let shared = WidgetNavigationManager()
    
    @Published var pendingDestination: WidgetDestination?
    @Published var shouldNavigate: Bool = false
    
    enum WidgetDestination {
        case verseOfDay
        case readingPlan
        case prayer
        case habits
        case countdown
        case moodGratitude
        case favorites
        case journal
        
        var tabIndex: Int {
            switch self {
            case .verseOfDay, .readingPlan, .prayer, .habits, .countdown, .moodGratitude:
                return 0 // Hub tab
            case .favorites:
                return 2 // Read tab (contains Saved segment)
            case .journal:
                return 2 // Read tab (contains Journal segment)
            }
        }
        
        /// The segment to select within the Read tab container
        var readSegment: String? {
            switch self {
            case .favorites:
                return "saved"
            case .journal:
                return "journal"
            default:
                return nil
            }
        }
        
        var hubSection: String? {
            switch self {
            case .verseOfDay:
                return "today"
            case .readingPlan:
                return "plans"
            case .prayer:
                return "prayer"
            case .habits:
                return "habits"
            case .countdown:
                return "today"
            case .moodGratitude:
                return "today"
            default:
                return nil
            }
        }
    }
    
    private init() {}
    
    func navigateTo(_ destination: WidgetDestination) {
        pendingDestination = destination
        shouldNavigate = true
    }
    
    func clearNavigation() {
        pendingDestination = nil
        shouldNavigate = false
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Configure audio session for background playback early
        configureAudioSession()
        
        // Check for pending audio actions from Live Activity
        checkPendingAudioAction()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Check for pending audio actions when app becomes active
        checkPendingAudioAction()
    }
    
    /// Check for pending audio control actions from Live Activity
    private func checkPendingAudioAction() {
        guard let defaults = UserDefaults(suiteName: "group.vaynerov.Bible-v1"),
              let actionString = defaults.string(forKey: "pendingAudioAction") else {
            return
        }
        
        // Check timestamp to avoid processing stale actions
        let timestamp = defaults.double(forKey: "pendingAudioActionTimestamp")
        let actionTime = Date(timeIntervalSince1970: timestamp)
        guard Date().timeIntervalSince(actionTime) < 30.0 else {
            // Clear stale action
            defaults.removeObject(forKey: "pendingAudioAction")
            defaults.removeObject(forKey: "pendingAudioActionTimestamp")
            return
        }
        
        // Clear the pending action
        defaults.removeObject(forKey: "pendingAudioAction")
        defaults.removeObject(forKey: "pendingAudioActionTimestamp")
        defaults.synchronize()
        
        print("AppDelegate: Processing pending audio action: \(actionString)")
        
        // Handle the action
        Task { @MainActor in
            let audioService = AudioService.shared
            
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
                print("AppDelegate: Unknown audio action: \(actionString)")
            }
            
            // Force update Live Activity after action
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            audioService.forceUpdateLiveActivity()
        }
    }
    
    /// Configure the audio session at app launch for background audio support
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .allowBluetoothA2DP, .allowAirPlay])
            // Don't activate yet - wait until actual playback
            print("AppDelegate: Audio session configured for background playback")
        } catch {
            print("AppDelegate: Failed to configure audio session: \(error)")
        }
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and sound even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is an AI response notification
        if let type = userInfo["type"] as? String, type == "ai_response",
           let conversationIdString = userInfo["conversationId"] as? String,
           let conversationId = UUID(uuidString: conversationIdString) {
            
            // Handle the action
            switch response.actionIdentifier {
            case "OPEN_CONVERSATION", UNNotificationDefaultActionIdentifier:
                // Navigate to the conversation
                Task { @MainActor in
                    // Clear the notification
                    AIBackgroundNotificationService.shared.clearNotification(for: conversationId)
                    
                    // Post notification to open AI chat with this conversation
                    NotificationCenter.default.post(
                        name: .openAIConversation,
                        object: nil,
                        userInfo: ["conversationId": conversationId]
                    )
                }
            case "DISMISS":
                // Just dismiss the notification
                Task { @MainActor in
                    AIBackgroundNotificationService.shared.clearNotification(for: conversationId)
                }
            default:
                break
            }
        }
        
        completionHandler()
    }
}

// Note: Notification.Name.openAIConversation is defined in Notification+Extensions.swift
