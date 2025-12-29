//
//  NowPlayingManager.swift
//  Bible v1
//
//  Manages Now Playing info for Control Center and Lock Screen
//

import Foundation
import MediaPlayer
import UIKit

/// Manages Now Playing information and remote command handling
@MainActor
class NowPlayingManager {
    
    private weak var audioService: AudioService?
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    init(audioService: AudioService) {
        self.audioService = audioService
        setupRemoteCommands()
    }
    
    // MARK: - Remote Command Setup
    
    private func setupRemoteCommands() {
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.audioService?.resume()
            }
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.audioService?.pause()
            }
            return .success
        }
        
        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.audioService?.togglePlayPause()
            }
            return .success
        }
        
        // Next track command (next verse)
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.audioService?.nextVerse()
            }
            return .success
        }
        
        // Previous track command (previous verse)
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.audioService?.previousVerse()
            }
            return .success
        }
        
        // Skip forward command
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 15)]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                // Skip to next verse as an approximation
                self.audioService?.nextVerse()
            }
            return .success
        }
        
        // Skip backward command
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                // Go to previous verse
                self.audioService?.previousVerse()
            }
            return .success
        }
        
        // Stop command
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            Task { @MainActor in
                self.audioService?.stop()
            }
            return .success
        }
    }
    
    // MARK: - Now Playing Info
    
    func updateNowPlayingInfo() {
        guard let audioService = audioService else { return }
        
        var nowPlayingInfo = [String: Any]()
        
        // Title - Current verse text (truncated)
        let verseText = audioService.currentVerseText
        let truncatedText = verseText.count > 100 ? String(verseText.prefix(100)) + "..." : verseText
        nowPlayingInfo[MPMediaItemPropertyTitle] = truncatedText
        
        // Artist - Reference
        nowPlayingInfo[MPMediaItemPropertyArtist] = audioService.currentReference
        
        // Album - App name with voice type
        let voiceType = audioService.currentAudioSource == .openAI ? "Premium Voice" : "Built-in Voice"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Bible - \(voiceType)"
        
        // Track info
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = audioService.currentVerseIndex
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = audioService.totalVerses
        
        // Progress info
        let verseProgress = Double(audioService.currentVerseIndex) / Double(max(1, audioService.totalVerses))
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = verseProgress
        
        // Playback rate
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioService.isPaused ? 0.0 : 1.0
        
        // If we have OpenAI audio, we can get more precise duration/time
        if audioService.currentAudioSource == .openAI {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = audioService.currentPlaybackDuration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioService.currentPlaybackTime
        } else {
            // For system TTS, estimate based on text length and rate
            let estimatedDuration = estimateSpeechDuration(text: verseText, rate: audioService.speechRate)
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = estimatedDuration
        }
        
        // Create artwork
        if let artwork = createArtwork() {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    private func estimateSpeechDuration(text: String, rate: Float) -> TimeInterval {
        // Average speaking rate: ~150 words per minute at normal speed
        // System rate 0.5 = normal, adjust accordingly
        let wordCount = Double(text.components(separatedBy: .whitespaces).count)
        let baseWPM = 150.0
        let adjustedWPM = baseWPM * Double(rate / 0.5)
        return (wordCount / adjustedWPM) * 60.0
    }
    
    private func createArtwork() -> MPMediaItemArtwork? {
        // Create a simple artwork with app icon or Bible icon
        let size = CGSize(width: 600, height: 600)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Background gradient
            let colors = [
                UIColor(red: 0.2, green: 0.35, blue: 0.6, alpha: 1.0).cgColor,
                UIColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0).cgColor
            ]
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Draw book icon
            let bookRect = CGRect(x: 175, y: 150, width: 250, height: 300)
            UIColor.white.withAlphaComponent(0.9).setFill()
            
            let bookPath = UIBezierPath(roundedRect: bookRect, cornerRadius: 20)
            bookPath.fill()
            
            // Book spine
            UIColor.white.withAlphaComponent(0.7).setFill()
            let spineRect = CGRect(x: 175, y: 150, width: 20, height: 300)
            let spinePath = UIBezierPath(roundedRect: spineRect, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: CGSize(width: 10, height: 10))
            spinePath.fill()
            
            // Cross on book
            let crossColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            crossColor.setFill()
            
            let crossVertical = CGRect(x: 290, y: 220, width: 20, height: 160)
            UIBezierPath(roundedRect: crossVertical, cornerRadius: 3).fill()
            
            let crossHorizontal = CGRect(x: 240, y: 260, width: 120, height: 20)
            UIBezierPath(roundedRect: crossHorizontal, cornerRadius: 3).fill()
            
            // "Bible" text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let text = "Bible"
            let textRect = CGRect(x: 0, y: 480, width: size.width, height: 60)
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return MPMediaItemArtwork(boundsSize: size) { _ in image }
    }
    
    func clearNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = nil
    }
    
    deinit {
        // Clean up remote commands
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.stopCommand.removeTarget(nil)
    }
}


