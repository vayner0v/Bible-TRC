//
//  LiveActivityAttributes.swift
//  Bible v1
//
//  ActivityKit attributes for Live Activities and Dynamic Island
//

import Foundation
import ActivityKit

// MARK: - AI Generation Activity

/// Live Activity for AI chat generation progress
struct AIGenerationAttributes: ActivityAttributes {
    
    /// Dynamic content state for AI generation
    public struct ContentState: Codable, Hashable {
        /// Current status: "thinking", "streaming", "complete", "error"
        var status: String
        /// Preview of the response (first ~100 chars)
        var preview: String
        /// Estimated progress (0.0 - 1.0) based on token count
        var progress: Double
        /// Title of the response (if available)
        var title: String?
        
        static var thinking: ContentState {
            ContentState(status: "thinking", preview: "Thinking...", progress: 0.0)
        }
        
        static func streaming(preview: String, progress: Double) -> ContentState {
            ContentState(status: "streaming", preview: preview, progress: progress)
        }
        
        static func complete(title: String?, preview: String) -> ContentState {
            ContentState(status: "complete", preview: preview, progress: 1.0, title: title)
        }
        
        static var error: ContentState {
            ContentState(status: "error", preview: "Generation failed", progress: 0.0)
        }
    }
    
    /// Conversation ID for deep linking
    var conversationId: String
    /// AI mode (study, devotional, prayer)
    var mode: String
    /// Mode display name for UI
    var modeDisplayName: String
    /// Start time for elapsed tracking
    var startTime: Date
}

// MARK: - Bible Audio Playback Activity

/// Live Activity for Bible audio playback
struct BibleAudioAttributes: ActivityAttributes {
    
    /// Dynamic content state for audio playback
    public struct ContentState: Codable, Hashable {
        /// Current verse reference (e.g., "John 3:16")
        var reference: String
        /// Current verse text (truncated for display)
        var verseText: String
        /// Whether audio is currently playing
        var isPlaying: Bool
        /// Current verse index (0-based)
        var currentVerse: Int
        /// Total verses in the chapter
        var totalVerses: Int
        /// Voice type display name ("Premium AI" or "Built-in")
        var voiceType: String
        /// Whether audio is loading
        var isLoading: Bool
        
        /// Progress as a percentage (0.0 - 1.0)
        var progress: Double {
            guard totalVerses > 0 else { return 0 }
            return Double(currentVerse + 1) / Double(totalVerses)
        }
        
        /// Formatted progress text (e.g., "5 of 31")
        var progressText: String {
            "\(currentVerse + 1) of \(totalVerses)"
        }
        
        static func playing(
            reference: String,
            verseText: String,
            currentVerse: Int,
            totalVerses: Int,
            voiceType: String
        ) -> ContentState {
            ContentState(
                reference: reference,
                verseText: String(verseText.prefix(120)),
                isPlaying: true,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType,
                isLoading: false
            )
        }
        
        static func paused(
            reference: String,
            verseText: String,
            currentVerse: Int,
            totalVerses: Int,
            voiceType: String
        ) -> ContentState {
            ContentState(
                reference: reference,
                verseText: String(verseText.prefix(120)),
                isPlaying: false,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType,
                isLoading: false
            )
        }
        
        static func loading(
            reference: String,
            currentVerse: Int,
            totalVerses: Int,
            voiceType: String
        ) -> ContentState {
            ContentState(
                reference: reference,
                verseText: "Loading audio...",
                isPlaying: false,
                currentVerse: currentVerse,
                totalVerses: totalVerses,
                voiceType: voiceType,
                isLoading: true
            )
        }
    }
    
    /// Bible translation ID
    var translationId: String
    /// Book name (e.g., "John")
    var bookName: String
    /// Chapter number
    var chapter: Int
    /// Full chapter reference for display
    var chapterReference: String {
        "\(bookName) \(chapter)"
    }
}

// MARK: - Activity Intent Actions

/// Actions that can be triggered from Live Activities
enum LiveActivityAction: String, Codable {
    // AI Actions
    case cancelAIGeneration = "cancel_ai"
    case openAIConversation = "open_ai"
    
    // Audio Actions
    case playPauseAudio = "play_pause"
    case nextVerse = "next_verse"
    case previousVerse = "prev_verse"
    case stopAudio = "stop_audio"
    case openReader = "open_reader"
}



