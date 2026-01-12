//
//  AudioService.swift
//  Bible v1
//
//  Advanced Bible Reader App with OpenAI TTS Integration
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer

/// Audio source type for playback
enum AudioSource {
    case openAI
    case systemTTS
    
    var displayName: String {
        switch self {
        case .openAI: return "Premium AI"
        case .systemTTS: return "Built-in Enhanced"
        }
    }
    
    var icon: String {
        switch self {
        case .openAI: return "waveform"
        case .systemTTS: return "speaker.wave.3.fill"
        }
    }
}

/// Preferred voice type selection
enum PreferredVoiceType: String, Codable {
    case premium = "premium"
    case builtin = "builtin"
}

/// Represents a saved audio playback position for "continue where you left off"
struct AudioPlaybackPosition: Codable, Equatable {
    let translationId: String
    let bookId: String
    let bookName: String
    let chapter: Int
    let verseIndex: Int
    let totalVerses: Int
    let voiceType: PreferredVoiceType
    let timestamp: Date
    
    init(translationId: String, bookId: String, bookName: String, chapter: Int, verseIndex: Int, totalVerses: Int, voiceType: PreferredVoiceType, timestamp: Date = Date()) {
        self.translationId = translationId
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verseIndex = verseIndex
        self.totalVerses = totalVerses
        self.voiceType = voiceType
        self.timestamp = timestamp
    }
    
    /// Display string for UI (e.g., "John 3:16")
    var displayString: String {
        "\(bookName) \(chapter):\(verseIndex + 1)"
    }
    
    /// Check if position is still valid (not too old - 30 days)
    var isValid: Bool {
        let maxAge: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        return Date().timeIntervalSince(timestamp) < maxAge
    }
}

/// Service for text-to-speech audio playback of Bible verses
@MainActor
class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()
    
    // System TTS (fallback)
    private let synthesizer = AVSpeechSynthesizer()
    
    // AVAudioPlayer for OpenAI audio
    private var audioPlayer: AVAudioPlayer?
    
    // Services
    private let openAITTSService = OpenAITTSService.shared
    private let cacheService = CacheService.shared
    private let usageTrackingService = UsageTrackingService.shared
    
    // UserDefaults keys
    private enum Keys {
        static let preferredVoiceType = "audio_preferred_voice_type"
        static let selectedBuiltinVoice = "audio_selected_builtin_voice"
        static let speechRate = "audio_speech_rate"
        static let immersiveModeEnabled = "audio_immersive_mode_enabled"
        static let autoContinueChapter = "audio_auto_continue_chapter"
        static let lastAudioPosition = "audio_last_playback_position"
    }
    
    // Playback state
    @Published var isPlaying = false
    @Published var isPaused = false
    @Published var currentVerseIndex: Int = 0
    @Published var speechRate: Float = 0.5 // 0.0 - 1.0 (for system TTS)
    @Published var totalVerses: Int = 0
    @Published var currentVerseText: String = ""
    @Published var currentReference: String = ""
    
    // OpenAI TTS specific state
    @Published var isLoadingAudio = false
    @Published var currentAudioSource: AudioSource = .openAI
    @Published var loadingVerseIndex: Int? = nil
    @Published var audioError: String? = nil
    
    // Subscription state (will be managed by SubscriptionManager)
    @Published var isPremiumSubscriber: Bool = false
    @Published var usageLimitReached: Bool = false
    
    // Voice selection settings
    @Published var preferredVoiceType: PreferredVoiceType = .premium {
        didSet {
            UserDefaults.standard.set(preferredVoiceType.rawValue, forKey: Keys.preferredVoiceType)
        }
    }
    
    @Published var selectedBuiltinVoiceId: String = "" {
        didSet {
            UserDefaults.standard.set(selectedBuiltinVoiceId, forKey: Keys.selectedBuiltinVoice)
        }
    }
    
    // Immersive mode settings
    @Published var immersiveModeEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(immersiveModeEnabled, forKey: Keys.immersiveModeEnabled)
        }
    }
    
    @Published var autoContinueToNextChapter: Bool = true {
        didSet {
            UserDefaults.standard.set(autoContinueToNextChapter, forKey: Keys.autoContinueChapter)
        }
    }
    
    // Listening mode state
    @Published var isInListeningMode = false
    
    // Chapter context for caching
    private var translationId: String = ""
    private var bookId: String = ""
    private var chapterNum: Int = 0
    
    private var verses: [Verse] = []
    private var currentUtterance: AVSpeechUtterance?
    private var onVerseChange: ((Int) -> Void)?
    private var languageCode: String = "en-US"
    
    // Pre-fetch task
    private var prefetchTask: Task<Void, Never>?
    
    // Now playing manager
    private var nowPlayingManager: NowPlayingManager?
    
    // Live Activity service for Dynamic Island
    private var liveActivityService: LiveActivityService?
    
    // Book name for Live Activity (stored when playback starts)
    private var bookName: String = ""
    
    // Track if we were playing before an interruption
    private var wasPlayingBeforeInterruption: Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
        loadSavedPreferences()
        setupAudioSession()
        openAITTSService.loadSavedPreferences()
        nowPlayingManager = NowPlayingManager(audioService: self)
        
        // Set up notification observers for decoupled service communication
        // This avoids circular dependency issues during singleton initialization
        setupNotificationObservers()
        
        // Set up Live Activity service (deferred to avoid initialization issues)
        Task { @MainActor in
            self.liveActivityService = LiveActivityService.shared
        }
        
        // Observe UserDefaults changes for settings sync
        setupUserDefaultsObserver()
        
        // NOTE: Do NOT access SubscriptionManager.shared here!
        // It will be synced via notification or deferred call after app launch
    }
    
    /// Set up observer for UserDefaults changes to sync settings
    private func setupUserDefaultsObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserDefaultsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc nonisolated private func handleUserDefaultsChanged(_ notification: Notification) {
        Task { @MainActor in
            // Sync preferredVoiceType from UserDefaults if changed externally
            if let voiceType = UserDefaults.standard.string(forKey: Keys.preferredVoiceType),
               let type = PreferredVoiceType(rawValue: voiceType),
               type != self.preferredVoiceType {
                self.preferredVoiceType = type
            }
        }
    }
    
    /// Set up observers for notifications from other services
    private func setupNotificationObservers() {
        // Observe subscription status changes from SubscriptionManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionStatusChanged),
            name: .subscriptionStatusChanged,
            object: nil
        )
        
        // Observe usage limit reached from UsageTrackingService
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUsageLimitReached),
            name: .usageLimitReached,
            object: nil
        )
        
        // Observe usage limit reset from UsageTrackingService
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUsageLimitReset),
            name: .usageLimitReset,
            object: nil
        )
        
        // Observe audio control actions from Live Activity
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioControlAction),
            name: .audioControlAction,
            object: nil
        )
    }
    
    @objc nonisolated private func handleAudioControlAction(_ notification: Notification) {
        guard let actionString = notification.userInfo?["action"] as? String else { return }
        
        Task { @MainActor in
            switch actionString {
            case "play":
                self.resume()
            case "pause":
                self.pause()
            case "next":
                self.nextVerse()
            case "previous":
                self.previousVerse()
            case "stop":
                self.stop()
            default:
                break
            }
        }
    }
    
    @objc nonisolated private func handleSubscriptionStatusChanged(_ notification: Notification) {
        let isPremium = notification.userInfo?["isPremium"] as? Bool ?? false
        Task { @MainActor in
            self.isPremiumSubscriber = isPremium
        }
    }
    
    @objc nonisolated private func handleUsageLimitReached(_ notification: Notification) {
        Task { @MainActor in
            self.usageLimitReached = true
        }
    }
    
    @objc nonisolated private func handleUsageLimitReset(_ notification: Notification) {
        Task { @MainActor in
            self.usageLimitReached = false
        }
    }
    
    /// Call this after app initialization is complete to sync subscription status
    /// This avoids circular dependency during singleton initialization
    func syncSubscriptionStatus() {
        Task { @MainActor in
            isPremiumSubscriber = SubscriptionManager.shared.isPremium
        }
    }
    
    private func loadSavedPreferences() {
        let defaults = UserDefaults.standard
        
        if let voiceType = defaults.string(forKey: Keys.preferredVoiceType),
           let type = PreferredVoiceType(rawValue: voiceType) {
            preferredVoiceType = type
        }
        
        if let voiceId = defaults.string(forKey: Keys.selectedBuiltinVoice), !voiceId.isEmpty {
            selectedBuiltinVoiceId = voiceId
        } else {
            // Set default enhanced voice
            selectedBuiltinVoiceId = findDefaultEnhancedVoice()
        }
        
        if let rate = defaults.object(forKey: Keys.speechRate) as? Float {
            speechRate = rate
        }
        
        immersiveModeEnabled = defaults.object(forKey: Keys.immersiveModeEnabled) as? Bool ?? true
        autoContinueToNextChapter = defaults.object(forKey: Keys.autoContinueChapter) as? Bool ?? true
    }
    
    private func findDefaultEnhancedVoice() -> String {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // Prefer enhanced voices
        for voice in voices {
            if voice.language.hasPrefix("en") && voice.quality == .enhanced {
                return voice.identifier
            }
        }
        
        // Fallback to any English voice
        for voice in voices {
            if voice.language.hasPrefix("en") {
                return voice.identifier
            }
        }
        
        return ""
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Use .playback category for background audio support
            // .mixWithOthers removed to ensure we take audio focus
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .allowBluetoothA2DP, .allowAirPlay])
            try session.setActive(true, options: [])
            
            // Register for interruption notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: session
            )
            
            // Register for route change notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: session
            )
            
            // Register for app lifecycle notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppWillResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            
            // Register for app termination - critical for saving position
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppWillTerminate),
                name: UIApplication.willTerminateNotification,
                object: nil
            )
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Ensure audio session is active before playback
    /// Call this before starting any audio playback
    private func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Ensure category is set correctly
            if session.category != .playback {
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .allowBluetoothA2DP, .allowAirPlay])
            }
            // Activate the session
            try session.setActive(true, options: [])
            print("AudioService: Audio session activated successfully")
        } catch {
            print("AudioService: Failed to activate audio session: \(error)")
        }
    }
    
    @objc nonisolated private func handleAppWillResignActive(_ notification: Notification) {
        // App losing focus but not yet in background
        Task { @MainActor in
            // Save audio position immediately when app loses focus
            // This handles the case where user force-quits from app switcher
            if self.isPlaying || self.isPaused {
                print("AudioService: App will resign active, saving audio position")
                self.saveAudioPlaybackPosition()
            }
            
            if self.isPlaying {
                // Prepare for potential background - ensure session is configured
                self.activateAudioSession()
            }
        }
    }
    
    @objc nonisolated private func handleAppDidEnterBackground(_ notification: Notification) {
        // App fully in background - critical for background playback
        Task { @MainActor in
            // Save audio position when entering background (redundant with willResignActive, but ensures safety)
            if self.isPlaying || self.isPaused {
                print("AudioService: App entered background, saving audio position")
                self.saveAudioPlaybackPosition()
            }
            
            if self.isPlaying {
                print("AudioService: App entered background, audio is playing - ensuring continuation")
                
                // Re-activate session to maintain background audio
                self.activateAudioSession()
                
                // Update now playing info - iOS uses this to keep audio alive
                self.nowPlayingManager?.updateNowPlayingInfo()
                
                // Ensure player is still playing (sometimes it needs a nudge)
                if let player = self.audioPlayer, !player.isPlaying && !self.isPaused {
                    print("AudioService: Player stopped unexpectedly, restarting...")
                    player.play()
                }
            }
        }
    }
    
    @objc nonisolated private func handleAppWillEnterForeground(_ notification: Notification) {
        Task { @MainActor in
            print("AudioService: App will enter foreground")
            if self.isPlaying {
                // Re-activate in case session was interrupted
                self.activateAudioSession()
            }
        }
    }
    
    @objc nonisolated private func handleAppDidBecomeActive(_ notification: Notification) {
        Task { @MainActor in
            if self.isPlaying {
                print("AudioService: App became active, audio was playing")
                // Re-activate session in case it was deactivated
                self.activateAudioSession()
                self.nowPlayingManager?.updateNowPlayingInfo()
            }
        }
    }
    
    @objc nonisolated private func handleAppWillTerminate(_ notification: Notification) {
        // App is being terminated - save position synchronously
        // Note: This is called on main thread and must complete quickly
        Task { @MainActor in
            if self.isPlaying || self.isPaused || !self.verses.isEmpty {
                print("AudioService: App will terminate, saving audio position")
                self.saveAudioPlaybackPosition()
                // Force synchronize UserDefaults to ensure data is written
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    @objc nonisolated private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        // Extract options before Task to avoid capturing non-Sendable userInfo
        let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
        
        Task { @MainActor in
            switch type {
            case .began:
                print("AudioService: Interruption began")
                // Audio session interrupted (e.g., phone call)
                // Mark that we were playing before interruption
                if isPlaying && !isPaused {
                    wasPlayingBeforeInterruption = true
                    pause()
                }
            case .ended:
                print("AudioService: Interruption ended")
                // Re-activate the audio session
                activateAudioSession()
                
                // Interruption ended - check if we should resume
                if let optionsValue = optionsValue {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && wasPlayingBeforeInterruption {
                        // Small delay to let the system settle
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        resume()
                    }
                } else if wasPlayingBeforeInterruption {
                    // Even without shouldResume, try to resume if we were playing
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    resume()
                }
                wasPlayingBeforeInterruption = false
            @unknown default:
                break
            }
        }
    }
    
    @objc nonisolated private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        Task { @MainActor in
            switch reason {
            case .oldDeviceUnavailable:
                // Headphones unplugged - pause playback
                if isPlaying && !isPaused {
                    pause()
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Playback Controls
    
    /// Start reading from a specific verse
    func play(
        verses: [Verse],
        reference: String = "",
        startingAt index: Int = 0,
        language: String = "en-US",
        translationId: String = "",
        bookId: String = "",
        bookName: String = "",
        chapter: Int = 0,
        voiceType: PreferredVoiceType? = nil,
        onVerseChange: ((Int) -> Void)? = nil
    ) {
        stop()
        
        self.verses = verses
        self.totalVerses = verses.count
        self.currentVerseIndex = index
        self.onVerseChange = onVerseChange
        self.languageCode = language
        self.currentReference = reference
        self.translationId = translationId
        self.bookId = bookId
        self.bookName = bookName.isEmpty ? extractBookName(from: reference) : bookName
        self.chapterNum = chapter
        self.audioError = nil
        
        // Use specified voice type or fall back to preference
        if let type = voiceType {
            preferredVoiceType = type
        }
        
        // Enter listening mode if enabled
        if immersiveModeEnabled {
            isInListeningMode = true
        }
        
        playCurrentVerse()
        
        // Update now playing info
        nowPlayingManager?.updateNowPlayingInfo()
        
        // Start Live Activity for Dynamic Island
        startLiveActivity()
    }
    
    /// Extract book name from a reference like "John 3:16"
    private func extractBookName(from reference: String) -> String {
        let parts = reference.components(separatedBy: " ")
        if parts.count >= 2 {
            // Handle numbered books like "1 John 3:16"
            if let firstChar = parts.first?.first, firstChar.isNumber, parts.count >= 3 {
                return "\(parts[0]) \(parts[1])"
            }
            return parts[0]
        }
        return reference
    }
    
    /// Start Live Activity for audio playback
    private func startLiveActivity() {
        guard !verses.isEmpty else { return }
        
        let voiceTypeDisplay = currentAudioSource.displayName
        let verse = verses[currentVerseIndex]
        let verseReference = "\(bookName) \(chapterNum):\(verse.verse)"
        
        liveActivityService?.startAudioPlayback(
            translationId: translationId,
            bookName: bookName,
            chapter: chapterNum,
            reference: verseReference,
            verseText: verse.text,
            currentVerse: currentVerseIndex,
            totalVerses: totalVerses,
            voiceType: voiceTypeDisplay,
            isLoading: isLoadingAudio
        )
    }
    
    /// Update Live Activity with current state
    private func updateLiveActivity() {
        guard !verses.isEmpty, currentVerseIndex < verses.count else { return }
        
        let verse = verses[currentVerseIndex]
        let verseReference = "\(bookName) \(chapterNum):\(verse.verse)"
        let voiceTypeDisplay = currentAudioSource.displayName
        
        print("AudioService: Updating Live Activity - playing: \(isPlaying), paused: \(isPaused), verse: \(currentVerseIndex)")
        
        liveActivityService?.updateAudioState(
            reference: verseReference,
            verseText: verse.text,
            isPlaying: isPlaying && !isPaused,
            currentVerse: currentVerseIndex,
            totalVerses: totalVerses,
            voiceType: voiceTypeDisplay,
            isLoading: isLoadingAudio
        )
    }
    
    /// Force update Live Activity (called from external sources like Live Activity controls)
    func forceUpdateLiveActivity() {
        updateLiveActivity()
    }
    
    private func playCurrentVerse() {
        print("AudioService: playCurrentVerse called - index: \(currentVerseIndex)")
        guard currentVerseIndex < verses.count else {
            print("AudioService: Index out of bounds, stopping")
            stop()
            return
        }
        
        let verse = verses[currentVerseIndex]
        currentVerseText = verse.text
        currentReference = "\(bookName) \(chapterNum):\(verse.verse)"
        onVerseChange?(currentVerseIndex)
        
        // Save position on each verse change for crash safety
        // This ensures we can resume even if the app is force-quit
        saveAudioPlaybackPosition()
        
        // Check if premium TTS should be used
        // Also check PromoCodeService for dev/promo access (respecting simulation mode)
        let hasPremiumAccess = (isPremiumSubscriber || PromoCodeService.shared.isPromoActivated) && !PromoCodeService.shared.isCustomerSimulationMode
        let canUsePremium = preferredVoiceType == .premium && 
                           openAITTSService.isEnabled && 
                           hasPremiumAccess &&
                           !usageLimitReached
        
        print("AudioService: hasPremiumAccess=\(hasPremiumAccess), canUsePremium=\(canUsePremium), usageLimitReached=\(usageLimitReached)")
        
        if canUsePremium {
            print("AudioService: Using OpenAI TTS")
            playWithOpenAI(verse: verse)
        } else {
            print("AudioService: Using System TTS")
            playWithSystemTTS(verse: verse)
        }
        
        // Update now playing info
        nowPlayingManager?.updateNowPlayingInfo()
        
        // Update Live Activity
        updateLiveActivity()
    }
    
    // MARK: - OpenAI TTS Playback
    
    private func playWithOpenAI(verse: Verse) {
        print("AudioService: playWithOpenAI starting for verse \(verse.verse)")
        isLoadingAudio = true
        loadingVerseIndex = currentVerseIndex
        currentAudioSource = .openAI
        
        Task {
            do {
                print("AudioService: Getting/generating audio for verse \(verse.verse)")
                let audioData = try await getOrGenerateAudio(for: verse)
                
                print("AudioService: Got audio data, size: \(audioData.count) bytes")
                // Play the audio
                try await playAudioData(audioData)
                
                print("AudioService: Audio playback started successfully")
                isLoadingAudio = false
                loadingVerseIndex = nil
                isPlaying = true
                isPaused = false
                
                // Update Live Activity after state change
                updateLiveActivity()
                
                // Pre-fetch next verse audio
                prefetchNextVerse()
                
            } catch {
                print("AudioService: OpenAI TTS error: \(error)")
                isLoadingAudio = false
                loadingVerseIndex = nil
                
                // Set error message
                if let openaiError = error as? OpenAITTSError {
                    audioError = openaiError.errorDescription
                    print("AudioService: OpenAI specific error: \(openaiError.errorDescription ?? "unknown")")
                    
                    // Check for specific errors
                    if case .usageLimitReached = openaiError {
                        print("AudioService: Usage limit reached!")
                        usageLimitReached = true
                    }
                }
                
                // Fallback to system TTS
                print("AudioService: Falling back to system TTS")
                playWithSystemTTS(verse: verse)
            }
        }
    }
    
    private func getOrGenerateAudio(for verse: Verse) async throws -> Data {
        let voiceId = openAITTSService.selectedVoice.rawValue
        
        // Check cache first (cached audio doesn't count against usage)
        if let cachedAudio = cacheService.getCachedAudio(
            translationId: translationId,
            bookId: bookId,
            chapter: chapterNum,
            verse: verse.verse,
            voiceId: voiceId
        ) {
            return cachedAudio
        }
        
        // Check usage limits before generating
        guard usageTrackingService.canProcess(text: verse.text) else {
            usageLimitReached = true
            throw OpenAITTSError.usageLimitReached
        }
        
        // Generate new audio
        let audioData = try await openAITTSService.generateSpeech(text: verse.text)
        
        // Track usage after successful generation
        usageTrackingService.recordUsage(characters: verse.text.count)
        
        // Cache it for future use
        cacheService.cacheAudio(
            audioData,
            translationId: translationId,
            bookId: bookId,
            chapter: chapterNum,
            verse: verse.verse,
            voiceId: voiceId
        )
        
        return audioData
    }
    
    private func playAudioData(_ data: Data) async throws {
        // Ensure audio session is active before playback
        activateAudioSession()
        
        // Create and configure the audio player
        let player = try AVAudioPlayer(data: data)
        player.delegate = self
        player.volume = 1.0
        player.prepareToPlay()
        
        // Store strong reference to prevent deallocation
        self.audioPlayer = player
        
        // Start playback
        let success = player.play()
        if !success {
            print("AudioService: AVAudioPlayer.play() returned false")
        }
        
        print("AudioService: Started playing audio, duration: \(player.duration)s")
    }
    
    private func prefetchNextVerse() {
        prefetchTask?.cancel()
        
        guard currentVerseIndex + 1 < verses.count else { return }
        
        let nextVerse = verses[currentVerseIndex + 1]
        let voiceId = openAITTSService.selectedVoice.rawValue
        
        // Check if already cached
        if cacheService.isAudioCached(
            translationId: translationId,
            bookId: bookId,
            chapter: chapterNum,
            verse: nextVerse.verse,
            voiceId: voiceId
        ) {
            return
        }
        
        prefetchTask = Task {
            do {
                _ = try await getOrGenerateAudio(for: nextVerse)
            } catch {
                // Ignore prefetch errors
            }
        }
    }
    
    // MARK: - System TTS Playback (Enhanced)
    
    private func playWithSystemTTS(verse: Verse) {
        // Ensure audio session is active
        activateAudioSession()
        
        currentAudioSource = .systemTTS
        
        let utterance = AVSpeechUtterance(string: verse.text)
        
        // Use selected enhanced voice or find best available
        if !selectedBuiltinVoiceId.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: selectedBuiltinVoiceId) {
            utterance.voice = voice
        } else if let enhancedVoice = findBestEnhancedVoice(for: languageCode) {
            utterance.voice = enhancedVoice
        } else if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Optimized settings for scripture reading
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.05 // Slightly higher for clarity
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.15 // Brief pause before
        utterance.postUtteranceDelay = 0.4 // Pause after for contemplation
        
        currentUtterance = utterance
        isPlaying = true
        isPaused = false
        
        synthesizer.speak(utterance)
    }
    
    /// Find the best enhanced voice for a language
    private func findBestEnhancedVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let languagePrefix = String(language.prefix(2))
        
        // First, try to find an enhanced/premium voice
        for voice in voices {
            if voice.language.hasPrefix(languagePrefix) && voice.quality == .enhanced {
                return voice
            }
        }
        
        // Fall back to any voice for the language
        for voice in voices {
            if voice.language.hasPrefix(languagePrefix) {
                return voice
            }
        }
        
        return nil
    }
    
    /// Set the preferred built-in voice
    func setBuiltinVoice(_ voiceId: String) {
        selectedBuiltinVoiceId = voiceId
    }
    
    /// Get available enhanced voices for current language
    func getAvailableEnhancedVoices() -> [(id: String, name: String, quality: String)] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        var result: [(id: String, name: String, quality: String)] = []
        
        for voice in voices {
            guard voice.language.hasPrefix("en") else { continue }
            
            let quality: String
            switch voice.quality {
            case .enhanced:
                quality = "Enhanced"
            case .premium:
                quality = "Premium"
            default:
                continue // Skip non-enhanced voices
            }
            
            result.append((id: voice.identifier, name: voice.name, quality: quality))
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    // MARK: - Playback Controls
    
    /// Pause playback
    func pause() {
        if isPlaying && !isPaused {
            if currentAudioSource == .openAI {
                audioPlayer?.pause()
            } else {
                synthesizer.pauseSpeaking(at: .word)
            }
            isPaused = true
            nowPlayingManager?.updateNowPlayingInfo()
            updateLiveActivity()
            
            // Save position for resume later
            saveAudioPlaybackPosition()
        }
    }
    
    /// Resume playback
    func resume() {
        if isPaused {
            if currentAudioSource == .openAI {
                audioPlayer?.play()
            } else {
                synthesizer.continueSpeaking()
            }
            isPaused = false
            nowPlayingManager?.updateNowPlayingInfo()
            updateLiveActivity()
        }
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        print("AudioService: togglePlayPause called - isPlaying: \(isPlaying), isPaused: \(isPaused)")
        if isPaused {
            print("AudioService: Resuming playback")
            resume()
        } else if isPlaying {
            print("AudioService: Pausing playback")
            pause()
        } else {
            print("AudioService: Neither playing nor paused, cannot toggle")
        }
    }
    
    /// Get current playback duration (for OpenAI audio)
    var currentPlaybackDuration: TimeInterval {
        audioPlayer?.duration ?? 0
    }
    
    /// Get current playback time (for OpenAI audio)
    var currentPlaybackTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }
    
    /// Stop playback
    func stop() {
        stop(savePosition: true)
    }
    
    /// Stop playback with option to save position
    /// - Parameter savePosition: If true, saves current position for resume later
    func stop(savePosition: Bool) {
        // Save position before clearing state (for resume later)
        // Only save if we have valid playback state and savePosition is true
        if savePosition && !verses.isEmpty && currentVerseIndex < verses.count {
            saveAudioPlaybackPosition()
        } else if !savePosition {
            // Clear saved position on natural completion
            clearAudioPlaybackPosition()
        }
        
        prefetchTask?.cancel()
        prefetchTask = nil
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        synthesizer.stopSpeaking(at: .immediate)
        
        isPlaying = false
        isPaused = false
        isLoadingAudio = false
        loadingVerseIndex = nil
        currentVerseIndex = 0
        currentVerseText = ""
        verses = []
        currentUtterance = nil
        audioError = nil
        
        // Exit listening mode
        isInListeningMode = false
        
        // Clear now playing info
        nowPlayingManager?.clearNowPlayingInfo()
        
        // End Live Activity
        liveActivityService?.stopAudioPlayback()
    }
    
    /// Exit listening mode but keep playing
    func exitListeningMode() {
        isInListeningMode = false
    }
    
    /// Enter listening mode
    func enterListeningMode() {
        if isPlaying {
            isInListeningMode = true
        }
    }
    
    /// Skip to next verse
    func nextVerse() {
        if currentVerseIndex < verses.count - 1 {
            stopCurrentPlayback()
            currentVerseIndex += 1
            playCurrentVerse()
        }
    }
    
    /// Skip to previous verse
    func previousVerse() {
        if currentVerseIndex > 0 {
            stopCurrentPlayback()
            currentVerseIndex -= 1
            playCurrentVerse()
        }
    }
    
    /// Jump to a specific verse
    func jumpToVerse(at index: Int) {
        guard index >= 0 && index < verses.count else { return }
        stopCurrentPlayback()
        currentVerseIndex = index
        playCurrentVerse()
    }
    
    private func stopCurrentPlayback() {
        audioPlayer?.stop()
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    /// Move to next verse after current finishes
    private func moveToNextVerse() {
        print("AudioService: moveToNextVerse called - currentIndex: \(currentVerseIndex), totalVerses: \(verses.count)")
        if currentVerseIndex < verses.count - 1 {
            currentVerseIndex += 1
            print("AudioService: Moving to verse \(currentVerseIndex)")
            playCurrentVerse()
        } else {
            // Finished all verses in this chapter - handle chapter end
            print("AudioService: Reached end of chapter")
            handleChapterEnd()
        }
    }
    
    /// Handle when the last verse of a chapter finishes playing
    private func handleChapterEnd() {
        // Ensure UserDefaults is synchronized before reading
        UserDefaults.standard.synchronize()
        
        // Read the auto-continue setting directly from UserDefaults
        // Default to true only if the key has never been set
        let autoContinueEnabled: Bool
        if let storedValue = UserDefaults.standard.object(forKey: Keys.autoContinueChapter) as? Bool {
            autoContinueEnabled = storedValue
        } else {
            // Key doesn't exist yet, use default
            autoContinueEnabled = true
        }
        
        if autoContinueEnabled {
            // Signal that we need the next chapter
            NotificationCenter.default.post(name: .audioChapterCompleted, object: nil)
        } else {
            // Auto-continue is disabled, stop playback completely
            // Don't save position since this is natural completion
            stop(savePosition: false)
        }
    }
    
    // MARK: - Settings
    
    /// Update speech rate (for system TTS)
    func setRate(_ rate: Float) {
        speechRate = max(0.0, min(1.0, rate))
        UserDefaults.standard.set(speechRate, forKey: Keys.speechRate)
    }
    
    /// Set preferred voice type
    func setPreferredVoiceType(_ type: PreferredVoiceType) {
        preferredVoiceType = type
    }
    
    /// Progress as percentage
    var progress: Double {
        guard totalVerses > 0 else { return 0 }
        return Double(currentVerseIndex + 1) / Double(totalVerses)
    }
    
    /// Current verse number (1-indexed)
    var currentVerseNumber: Int {
        currentVerseIndex + 1
    }
    
    /// Get language code from translation language
    func languageCode(for language: String) -> String {
        // Map common language codes
        let languageMap: [String: String] = [
            "eng": "en-US",
            "spa": "es-ES",
            "fra": "fr-FR",
            "deu": "de-DE",
            "ita": "it-IT",
            "por": "pt-BR",
            "rus": "ru-RU",
            "zho": "zh-CN",
            "jpn": "ja-JP",
            "kor": "ko-KR",
            "ara": "ar-SA",
            "heb": "he-IL"
        ]
        
        return languageMap[language.lowercased()] ?? "en-US"
    }
    
    /// Get display name for speech rate
    func rateDisplayName(_ rate: Float) -> String {
        switch rate {
        case 0..<0.4: return "Slow"
        case 0.4..<0.55: return "Normal"
        case 0.55..<0.7: return "Fast"
        default: return "Very Fast"
        }
    }
    
    /// Check if OpenAI TTS is enabled
    var isOpenAITTSEnabled: Bool {
        openAITTSService.isEnabled
    }
    
    /// Get selected voice name
    var selectedVoiceName: String {
        openAITTSService.selectedVoice.displayName
    }
    
    // MARK: - Audio Playback Position Persistence
    
    /// Save current audio playback position for resume later
    func saveAudioPlaybackPosition() {
        guard !verses.isEmpty,
              currentVerseIndex < verses.count,
              !translationId.isEmpty,
              !bookId.isEmpty else {
            return
        }
        
        let position = AudioPlaybackPosition(
            translationId: translationId,
            bookId: bookId,
            bookName: bookName,
            chapter: chapterNum,
            verseIndex: currentVerseIndex,
            totalVerses: verses.count,
            voiceType: preferredVoiceType
        )
        
        if let data = try? JSONEncoder().encode(position) {
            UserDefaults.standard.set(data, forKey: Keys.lastAudioPosition)
        }
    }
    
    /// Get the last saved audio playback position
    func getLastAudioPosition() -> AudioPlaybackPosition? {
        guard let data = UserDefaults.standard.data(forKey: Keys.lastAudioPosition),
              let position = try? JSONDecoder().decode(AudioPlaybackPosition.self, from: data) else {
            return nil
        }
        
        // Only return if still valid (not too old)
        return position.isValid ? position : nil
    }
    
    /// Clear the saved audio playback position
    func clearAudioPlaybackPosition() {
        UserDefaults.standard.removeObject(forKey: Keys.lastAudioPosition)
    }
    
    // MARK: - Subscription Integration
    
    /// Update premium subscriber status (called by SubscriptionManager)
    func updateSubscriptionStatus(isPremium: Bool) {
        // Defer @Published property change to avoid SwiftUI view update conflicts
        DispatchQueue.main.async { [weak self] in
            self?.isPremiumSubscriber = isPremium
        }
    }
    
    /// Reset usage limit (called when usage resets)
    func resetUsageLimit() {
        usageLimitReached = false
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            moveToNextVerse()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            // Cancelled - state is handled by stop() method
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("AudioService: audioPlayerDidFinishPlaying called, success: \(flag)")
        Task { @MainActor in
            if flag {
                moveToNextVerse()
            } else {
                print("AudioService: Audio playback finished unsuccessfully")
            }
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("Audio decode error: \(error?.localizedDescription ?? "unknown")")
            // Fallback to system TTS for current verse
            if currentVerseIndex < verses.count {
                playWithSystemTTS(verse: verses[currentVerseIndex])
            }
        }
    }
}
