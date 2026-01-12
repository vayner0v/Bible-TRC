//
//  BackgroundKeepAliveService.swift
//  Bible v1
//
//  Service to keep the app alive in background using silent audio
//  This is used when AI generation needs to continue after the user leaves the app
//

import Foundation
import AVFoundation
import Combine
import UIKit

/// Service that keeps the app running in background by playing inaudible audio
/// Used for AI generation to continue when app is backgrounded
@MainActor
class BackgroundKeepAliveService: ObservableObject {
    static let shared = BackgroundKeepAliveService()
    
    // MARK: - Published State
    
    @Published private(set) var isKeepAliveActive: Bool = false
    @Published private(set) var keepAliveReason: String = ""
    
    // MARK: - Private State
    
    private var silentPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }
    
    // Track active keep-alive requests by ID
    private var activeRequests: Set<String> = []
    
    // MARK: - Initialization
    
    private init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Monitor app state changes
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
    }
    
    @objc nonisolated private func handleAppDidEnterBackground(_ notification: Notification) {
        Task { @MainActor in
            if isKeepAliveActive {
                print("BackgroundKeepAliveService: App entered background, keep-alive is active")
                // Ensure audio is still playing
                ensureSilentAudioPlaying()
            }
        }
    }
    
    @objc nonisolated private func handleAppWillEnterForeground(_ notification: Notification) {
        Task { @MainActor in
            print("BackgroundKeepAliveService: App entering foreground")
            // Audio continues, no action needed
        }
    }
    
    // MARK: - Public API
    
    /// Start keep-alive for a specific reason/request ID
    /// Multiple requests can be active simultaneously
    /// - Parameters:
    ///   - requestId: Unique identifier for this keep-alive request
    ///   - reason: Human-readable reason (for debugging)
    func startKeepAlive(requestId: String, reason: String) {
        guard !activeRequests.contains(requestId) else {
            print("BackgroundKeepAliveService: Request \(requestId) already active")
            return
        }
        
        activeRequests.insert(requestId)
        keepAliveReason = reason
        
        if !isKeepAliveActive {
            print("BackgroundKeepAliveService: Starting keep-alive for: \(reason)")
            startSilentAudio()
            isKeepAliveActive = true
        } else {
            print("BackgroundKeepAliveService: Added request \(requestId), total active: \(activeRequests.count)")
        }
    }
    
    /// Stop keep-alive for a specific request
    /// Only stops audio when all requests are removed
    func stopKeepAlive(requestId: String) {
        activeRequests.remove(requestId)
        
        if activeRequests.isEmpty {
            print("BackgroundKeepAliveService: All requests completed, stopping keep-alive")
            stopSilentAudio()
            isKeepAliveActive = false
            keepAliveReason = ""
        } else {
            print("BackgroundKeepAliveService: Removed request \(requestId), remaining: \(activeRequests.count)")
        }
    }
    
    /// Force stop all keep-alive (emergency use)
    func forceStopAll() {
        activeRequests.removeAll()
        stopSilentAudio()
        isKeepAliveActive = false
        keepAliveReason = ""
        print("BackgroundKeepAliveService: Force stopped all keep-alive")
    }
    
    // MARK: - Silent Audio Management
    
    private func startSilentAudio() {
        // Configure audio session for background playback
        do {
            // Use .playback to enable background audio
            // .mixWithOthers allows our silent audio to not interfere with other audio
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true, options: [])
        } catch {
            print("BackgroundKeepAliveService: Failed to configure audio session: \(error)")
            return
        }
        
        // Create silent audio player
        guard let silentAudio = createSilentAudioData() else {
            print("BackgroundKeepAliveService: Failed to create silent audio data")
            return
        }
        
        do {
            silentPlayer = try AVAudioPlayer(data: silentAudio)
            silentPlayer?.numberOfLoops = -1 // Loop indefinitely
            silentPlayer?.volume = 0.01 // Nearly silent (0 might cause iOS to stop it)
            silentPlayer?.prepareToPlay()
            silentPlayer?.play()
            print("BackgroundKeepAliveService: Silent audio started")
        } catch {
            print("BackgroundKeepAliveService: Failed to create audio player: \(error)")
        }
    }
    
    private func stopSilentAudio() {
        silentPlayer?.stop()
        silentPlayer = nil
        
        // Don't deactivate the audio session as other audio might be using it
        print("BackgroundKeepAliveService: Silent audio stopped")
    }
    
    private func ensureSilentAudioPlaying() {
        guard isKeepAliveActive else { return }
        
        if silentPlayer == nil || !(silentPlayer?.isPlaying ?? false) {
            print("BackgroundKeepAliveService: Restarting silent audio")
            startSilentAudio()
        }
    }
    
    /// Create a minimal silent WAV audio data
    private func createSilentAudioData() -> Data? {
        // Create a minimal WAV file with silence
        // WAV header + 1 second of silence at 8000Hz, 8-bit mono
        let sampleRate: UInt32 = 8000
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 8
        let duration: Double = 1.0 // 1 second of silence
        
        let numSamples = Int(Double(sampleRate) * duration)
        let dataSize = numSamples * Int(numChannels) * Int(bitsPerSample / 8)
        
        var data = Data()
        
        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        
        // fmt subchunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) }) // Subchunk1Size
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // AudioFormat (PCM)
        data.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })
        let byteRate = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        let blockAlign = numChannels * (bitsPerSample / 8)
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
        
        // data subchunk
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        
        // Silence data (128 is silence for 8-bit unsigned PCM)
        let silenceData = Data(repeating: 128, count: dataSize)
        data.append(silenceData)
        
        return data
    }
}



