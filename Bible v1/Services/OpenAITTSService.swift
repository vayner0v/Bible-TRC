//
//  OpenAITTSService.swift
//  Bible v1
//
//  OpenAI Text-to-Speech Integration
//

import Foundation
import Combine

/// Available OpenAI voices optimized for scripture reading
enum OpenAIVoice: String, CaseIterable, Identifiable {
    case alloy = "alloy"
    case echo = "echo"
    case fable = "fable"
    case onyx = "onyx"
    case nova = "nova"
    case shimmer = "shimmer"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .alloy: return "Alloy"
        case .echo: return "Echo"
        case .fable: return "Fable"
        case .onyx: return "Onyx"
        case .nova: return "Nova"
        case .shimmer: return "Shimmer"
        }
    }
    
    var description: String {
        switch self {
        case .alloy: return "Warm & friendly"
        case .echo: return "Clear & resonant"
        case .fable: return "Gentle & expressive"
        case .onyx: return "Deep & authoritative"
        case .nova: return "Bright & versatile"
        case .shimmer: return "Smooth & captivating"
        }
    }
}

/// Errors that can occur with OpenAI TTS API
enum OpenAITTSError: LocalizedError {
    case invalidURL
    case invalidAPIKey
    case networkError(Error)
    case serverError(Int)
    case noAudioData
    case rateLimited
    case invalidResponse
    case usageExceeded
    case usageLimitReached
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidAPIKey: return "Invalid API key"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .serverError(let code): return "Server error (code: \(code))"
        case .noAudioData: return "No audio data received"
        case .rateLimited: return "Rate limited - please wait"
        case .invalidResponse: return "Invalid response from server"
        case .usageExceeded: return "OpenAI usage quota exceeded"
        case .usageLimitReached: return "Daily/monthly AI audio limit reached"
        }
    }
    
    var shouldFallbackToSystemTTS: Bool { true }
}

/// Service for OpenAI Text-to-Speech API
@MainActor
class OpenAITTSService: ObservableObject {
    static let shared = OpenAITTSService()
    
    private let baseURL = "https://api.openai.com/v1/audio/speech"
    // API key loaded from environment or config - never commit secrets!
    private var apiKey: String {
        // Try to load from environment variable first
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        // Fallback: Load from Secrets.plist (add to .gitignore)
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path),
           let key = secrets["OPENAI_API_KEY"] as? String {
            return key
        }
        // Return empty string if no key found - will fail gracefully
        return ""
    }
    
    @Published var selectedVoice: OpenAIVoice = .nova
    @Published var isEnabled = true
    @Published var isLoadingAudio = false
    @Published var lastError: OpenAITTSError?
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }
    
    /// Generate speech audio from text
    func generateSpeech(text: String, voice: OpenAIVoice? = nil) async throws -> Data {
        let voiceToUse = voice ?? selectedVoice
        
        guard !text.isEmpty else {
            throw OpenAITTSError.noAudioData
        }
        
        guard let url = URL(string: baseURL) else {
            throw OpenAITTSError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voiceToUse.rawValue,
            "response_format": "mp3"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        isLoadingAudio = true
        defer { isLoadingAudio = false }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAITTSError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard !data.isEmpty else {
                    throw OpenAITTSError.noAudioData
                }
                lastError = nil
                return data
                
            case 401:
                throw OpenAITTSError.invalidAPIKey
                
            case 429:
                throw OpenAITTSError.rateLimited
                
            case 400...499:
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorDict = errorData["error"] as? [String: Any],
                   let message = errorDict["message"] as? String,
                   message.contains("quota") || message.contains("limit") {
                    throw OpenAITTSError.usageExceeded
                }
                throw OpenAITTSError.serverError(httpResponse.statusCode)
                
            default:
                throw OpenAITTSError.serverError(httpResponse.statusCode)
            }
            
        } catch let error as OpenAITTSError {
            lastError = error
            throw error
        } catch {
            let openAIError = OpenAITTSError.networkError(error)
            lastError = openAIError
            throw openAIError
        }
    }
    
    // MARK: - Voice Selection
    
    func setVoice(_ voice: OpenAIVoice) {
        selectedVoice = voice
        UserDefaults.standard.set(voice.rawValue, forKey: "openai_voice")
    }
    
    func loadSavedVoice() {
        if let savedVoiceId = UserDefaults.standard.string(forKey: "openai_voice"),
           let voice = OpenAIVoice.allCases.first(where: { $0.rawValue == savedVoiceId }) {
            selectedVoice = voice
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "openai_enabled")
    }
    
    func loadSavedPreferences() {
        loadSavedVoice()
        isEnabled = UserDefaults.standard.object(forKey: "openai_enabled") as? Bool ?? true
    }
}

