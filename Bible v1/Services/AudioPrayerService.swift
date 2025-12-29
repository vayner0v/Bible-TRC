//
//  AudioPrayerService.swift
//  Bible v1
//
//  Spiritual Hub - Audio Prayer Playback Service
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

/// Manages audio playback for prayers
class AudioPrayerService: NSObject, ObservableObject {
    static let shared = AudioPrayerService()
    
    // Playback state
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published private(set) var currentPrayer: AudioPrayer?
    @Published private(set) var currentUserPrayer: UserAudioPrayer?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var playbackSpeed: Float = 1.0 {
        didSet {
            audioPlayer?.rate = playbackSpeed
            // Note: AVSpeechSynthesizer rate is set on the utterance, not the synthesizer
            // The rate will be applied to the next utterance played
        }
    }
    
    // Sleep timer
    @Published var sleepTimer: SleepTimerOption = .off {
        didSet {
            configureSleepTimer()
        }
    }
    @Published private(set) var sleepTimerRemaining: TimeInterval = 0
    
    // Queue
    @Published private(set) var queue: [AudioPrayer] = []
    @Published private(set) var queueIndex: Int = 0
    
    // Storage
    @Published var audioPrayers: [AudioPrayer] = []
    @Published var userAudioPrayers: [UserAudioPrayer] = []
    
    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var displayLink: CADisplayLink?
    private var sleepTimerDate: Date?
    private var sleepTimerTimer: Timer?
    
    private let defaults = UserDefaults.standard
    private enum Keys {
        static let audioPrayers = "audio_prayers"
        static let userAudioPrayers = "user_audio_prayers"
    }
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
        setupAudioSession()
        loadData()
        
        // Initialize with curated prayers if empty
        if audioPrayers.isEmpty {
            audioPrayers = AudioPrayer.curatedPrayers
            saveAudioPrayers()
        }
    }
    
    // MARK: - Audio Session
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowAirPlay, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }
    
    // MARK: - Playback Control
    
    /// Play an audio prayer
    func play(_ prayer: AudioPrayer) {
        stop()
        currentPrayer = prayer
        currentUserPrayer = nil
        
        // Use TTS for transcript since we don't have actual audio files
        playWithTextToSpeech(text: prayer.transcript)
        
        // Update play count
        if let index = audioPrayers.firstIndex(where: { $0.id == prayer.id }) {
            audioPrayers[index].recordPlay()
            saveAudioPrayers()
        }
    }
    
    /// Play a user audio prayer with TTS
    func play(_ userPrayer: UserAudioPrayer) {
        stop()
        currentUserPrayer = userPrayer
        currentPrayer = nil
        
        playWithTextToSpeech(
            text: userPrayer.content,
            rate: userPrayer.speechRate,
            voiceIdentifier: userPrayer.voiceIdentifier
        )
        
        // Update play count
        if let index = userAudioPrayers.firstIndex(where: { $0.id == userPrayer.id }) {
            userAudioPrayers[index].playCount += 1
            userAudioPrayers[index].lastPlayed = Date()
            saveUserAudioPrayers()
        }
    }
    
    /// Play text using Text-to-Speech
    private func playWithTextToSpeech(
        text: String,
        rate: Float = 0.5,
        voiceIdentifier: String? = nil
    ) {
        let utterance = AVSpeechUtterance(string: text)
        
        // Set voice
        if let identifier = voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            utterance.voice = voice
        } else {
            // Use default English voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Set rate (0.0 - 1.0, where 0.5 is normal)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate * playbackSpeed
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.5
        utterance.postUtteranceDelay = 0.5
        
        // Estimate duration
        let wordCount = text.split(separator: " ").count
        let wordsPerSecond = Double(rate * 2.5 + 1.5) // Rough estimate
        duration = Double(wordCount) / wordsPerSecond
        currentTime = 0
        
        playbackState = .playing
        speechSynthesizer.speak(utterance)
        
        startProgressTracking()
    }
    
    /// Pause playback
    func pause() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: .word)
        }
        audioPlayer?.pause()
        playbackState = .paused
        stopProgressTracking()
    }
    
    /// Resume playback
    func resume() {
        if speechSynthesizer.isPaused {
            speechSynthesizer.continueSpeaking()
            playbackState = .playing
            startProgressTracking()
        } else if let player = audioPlayer, !player.isPlaying {
            player.play()
            playbackState = .playing
            startProgressTracking()
        }
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused:
            resume()
        case .finished:
            // Restart
            if let prayer = currentPrayer {
                play(prayer)
            } else if let userPrayer = currentUserPrayer {
                play(userPrayer)
            }
        default:
            break
        }
    }
    
    /// Stop playback
    func stop() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
        playbackState = .idle
        currentTime = 0
        stopProgressTracking()
    }
    
    /// Seek to position (0.0 - 1.0)
    func seek(to progress: Double) {
        // TTS doesn't support seeking, so this is a no-op for now
        // For actual audio files, would be: audioPlayer?.currentTime = duration * progress
    }
    
    /// Skip forward
    func skipForward(seconds: TimeInterval = 15) {
        // Would implement for actual audio files
    }
    
    /// Skip backward
    func skipBackward(seconds: TimeInterval = 15) {
        // Would implement for actual audio files
    }
    
    // MARK: - Queue Management
    
    /// Set queue and start playing
    func setQueue(_ prayers: [AudioPrayer], startIndex: Int = 0) {
        queue = prayers
        queueIndex = startIndex
        if !queue.isEmpty && startIndex < queue.count {
            play(queue[startIndex])
        }
    }
    
    /// Play next in queue
    func playNext() {
        guard !queue.isEmpty else { return }
        queueIndex = (queueIndex + 1) % queue.count
        play(queue[queueIndex])
    }
    
    /// Play previous in queue
    func playPrevious() {
        guard !queue.isEmpty else { return }
        queueIndex = queueIndex > 0 ? queueIndex - 1 : queue.count - 1
        play(queue[queueIndex])
    }
    
    /// Clear queue
    func clearQueue() {
        queue = []
        queueIndex = 0
    }
    
    // MARK: - Progress Tracking
    
    private func startProgressTracking() {
        stopProgressTracking()
        
        // Use timer for TTS progress estimation
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.playbackState == .playing {
                    self.currentTime = min(self.currentTime + 0.5, self.duration)
                } else if self.playbackState != .paused {
                    self.stopProgressTracking()
                }
            }
        }
        // Store reference if needed for cleanup
        RunLoop.current.add(progressTimer, forMode: .common)
    }
    
    private func stopProgressTracking() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - Sleep Timer
    
    private func configureSleepTimer() {
        sleepTimerTimer?.invalidate()
        sleepTimerTimer = nil
        
        guard sleepTimer != .off else {
            sleepTimerRemaining = 0
            return
        }
        
        sleepTimerRemaining = TimeInterval(sleepTimer.rawValue * 60)
        sleepTimerDate = Date().addingTimeInterval(sleepTimerRemaining)
        
        sleepTimerTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let endDate = self.sleepTimerDate {
                    self.sleepTimerRemaining = max(0, endDate.timeIntervalSinceNow)
                    
                    if self.sleepTimerRemaining <= 0 {
                        self.stop()
                        self.sleepTimer = .off
                    }
                }
            }
        }
    }
    
    // MARK: - User Audio Prayers
    
    /// Add user audio prayer
    func addUserAudioPrayer(_ prayer: UserAudioPrayer) {
        userAudioPrayers.append(prayer)
        saveUserAudioPrayers()
    }
    
    /// Update user audio prayer
    func updateUserAudioPrayer(_ prayer: UserAudioPrayer) {
        if let index = userAudioPrayers.firstIndex(where: { $0.id == prayer.id }) {
            userAudioPrayers[index] = prayer
            saveUserAudioPrayers()
        }
    }
    
    /// Delete user audio prayer
    func deleteUserAudioPrayer(id: UUID) {
        userAudioPrayers.removeAll { $0.id == id }
        saveUserAudioPrayers()
    }
    
    /// Toggle favorite for audio prayer
    func toggleFavorite(_ prayer: AudioPrayer) {
        if let index = audioPrayers.firstIndex(where: { $0.id == prayer.id }) {
            audioPrayers[index].toggleFavorite()
            saveAudioPrayers()
        }
    }
    
    /// Toggle favorite for user audio prayer
    func toggleUserFavorite(_ prayer: UserAudioPrayer) {
        if let index = userAudioPrayers.firstIndex(where: { $0.id == prayer.id }) {
            userAudioPrayers[index].isFavorite.toggle()
            saveUserAudioPrayers()
        }
    }
    
    // MARK: - Available Voices
    
    /// Get available TTS voices
    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.starts(with: "en") }
            .sorted { $0.name < $1.name }
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        if let data = defaults.data(forKey: Keys.audioPrayers),
           let prayers = try? JSONDecoder().decode([AudioPrayer].self, from: data) {
            audioPrayers = prayers
        }
        
        if let data = defaults.data(forKey: Keys.userAudioPrayers),
           let prayers = try? JSONDecoder().decode([UserAudioPrayer].self, from: data) {
            userAudioPrayers = prayers
        }
    }
    
    private func saveAudioPrayers() {
        if let encoded = try? JSONEncoder().encode(audioPrayers) {
            defaults.set(encoded, forKey: Keys.audioPrayers)
        }
    }
    
    private func saveUserAudioPrayers() {
        if let encoded = try? JSONEncoder().encode(userAudioPrayers) {
            defaults.set(encoded, forKey: Keys.userAudioPrayers)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Progress as 0.0 - 1.0
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    /// Formatted current time
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    /// Formatted duration
    var formattedDuration: String {
        formatTime(duration)
    }
    
    /// Formatted remaining time
    var formattedRemainingTime: String {
        formatTime(duration - currentTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Favorite prayers
    var favoritePrayers: [AudioPrayer] {
        audioPrayers.filter { $0.isFavorite }
    }
    
    /// Recently played prayers
    var recentlyPlayed: [AudioPrayer] {
        audioPrayers
            .filter { $0.lastPlayed != nil }
            .sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
            .prefix(10)
            .map { $0 }
    }
    
    /// Prayers by category
    func prayers(for category: AudioPrayerCategory) -> [AudioPrayer] {
        audioPrayers.filter { $0.category == category }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioPrayerService: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.playbackState = .finished
            self.currentTime = self.duration
            
            // Auto-play next if queue has more items
            if !self.queue.isEmpty && self.queueIndex < self.queue.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.playNext()
                }
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.playbackState = .paused
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.playbackState = .playing
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.playbackState = .idle
        }
    }
}


