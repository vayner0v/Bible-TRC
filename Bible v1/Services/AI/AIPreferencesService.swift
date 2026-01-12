//
//  AIPreferencesService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - User Preferences Service
//

import Foundation
import Combine

/// Service for managing AI user preferences with hybrid local/cloud storage
@MainActor
class AIPreferencesService: ObservableObject {
    static let shared = AIPreferencesService()
    
    // MARK: - Storage Keys
    
    private let preferencesKey = "trc_ai_user_preferences"
    private let memoryEnabledKey = "trc_ai_memory_enabled"
    private let hasSeenMemoryConsentKey = "trc_ai_has_seen_memory_consent"
    
    // MARK: - Published State
    
    @Published private(set) var preferences: AIUserPreferences = .default
    @Published var isMemoryEnabled: Bool = false
    @Published var hasSeenMemoryConsent: Bool = false
    
    // MARK: - Dependencies
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadPreferences()
        loadMemorySettings()
    }
    
    // MARK: - Public API
    
    /// Update all preferences
    func updatePreferences(_ newPreferences: AIUserPreferences) {
        preferences = newPreferences
        savePreferences()
    }
    
    /// Update default translation
    func setDefaultTranslation(_ translationId: String) {
        preferences.defaultTranslation = translationId
        savePreferences()
    }
    
    /// Update response tone
    func setResponseTone(_ tone: ResponseTone) {
        preferences.responseTone = tone
        savePreferences()
    }
    
    /// Update reading level
    func setReadingLevel(_ level: ReadingLevel) {
        preferences.readingLevel = level
        savePreferences()
    }
    
    /// Update denomination lens
    func setDenominationLens(_ lens: DenominationLens) {
        preferences.denominationLens = lens
        savePreferences()
    }
    
    /// Update controversial topics preference
    func setAvoidControversialTopics(_ avoid: Bool) {
        preferences.avoidControversialTopics = avoid
        savePreferences()
    }
    
    /// Update preferred response length
    func setPreferredResponseLength(_ length: ResponseLength) {
        preferences.preferredResponseLength = length
        savePreferences()
    }
    
    /// Update selected persona
    func setSelectedPersona(_ persona: AIPersona) {
        preferences.selectedPersona = persona
        savePreferences()
    }
    
    /// Update custom instructions
    func setCustomInstructions(_ instructions: String) {
        preferences.customInstructions = instructions
        savePreferences()
    }
    
    /// Enable or disable memory
    func setMemoryEnabled(_ enabled: Bool) {
        isMemoryEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: memoryEnabledKey)
    }
    
    /// Mark that user has seen memory consent
    func markMemoryConsentSeen() {
        hasSeenMemoryConsent = true
        UserDefaults.standard.set(true, forKey: hasSeenMemoryConsentKey)
    }
    
    /// Reset all preferences to defaults
    func resetToDefaults() {
        preferences = .default
        savePreferences()
    }
    
    // MARK: - System Prompt Generation
    
    /// Build preference instructions for system prompt
    func buildPreferencePrompt() -> String {
        var instructions: [String] = []
        
        // Persona
        instructions.append(preferences.selectedPersona.systemPromptInstruction)
        
        // Tone
        instructions.append("TONE: \(preferences.responseTone.systemPromptInstruction)")
        
        // Reading level
        instructions.append("READING LEVEL: \(preferences.readingLevel.systemPromptInstruction)")
        
        // Denomination
        instructions.append("THEOLOGICAL LENS: \(preferences.denominationLens.systemPromptInstruction)")
        
        // Response length
        instructions.append("LENGTH: \(preferences.preferredResponseLength.systemPromptInstruction)")
        
        // Controversial topics
        if preferences.avoidControversialTopics {
            instructions.append("""
            CONTROVERSIAL TOPICS: Avoid engaging with politically divisive or denominationally contentious topics. \
            If asked about such topics, gently redirect to areas of common Christian agreement.
            """)
        }
        
        // Custom instructions
        if preferences.hasCustomInstructions {
            instructions.append("""
            
            USER'S CUSTOM INSTRUCTIONS (follow these carefully):
            \(preferences.customInstructions)
            """)
        }
        
        return """
        
        USER PREFERENCES:
        \(instructions.joined(separator: "\n"))
        
        """
    }
    
    /// Get the token limit based on user's length preference
    var preferredTokenLimit: Int {
        preferences.preferredResponseLength.tokenLimit
    }
    
    // MARK: - Persistence
    
    private func loadPreferences() {
        guard let data = UserDefaults.standard.data(forKey: preferencesKey),
              let decoded = try? JSONDecoder().decode(AIUserPreferences.self, from: data) else {
            preferences = .default
            return
        }
        preferences = decoded
    }
    
    private func savePreferences() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: preferencesKey)
        
        // Notify observers of changes
        objectWillChange.send()
    }
    
    private func loadMemorySettings() {
        isMemoryEnabled = UserDefaults.standard.bool(forKey: memoryEnabledKey)
        hasSeenMemoryConsent = UserDefaults.standard.bool(forKey: hasSeenMemoryConsentKey)
    }
}

// MARK: - Cloud Sync (Supabase)

extension AIPreferencesService {
    
    /// Check if user is authenticated for cloud sync
    private var isUserAuthenticated: Bool {
        AuthService.shared.authState.isAuthenticated
    }
    
    /// Sync preferences to Supabase for logged-in users
    /// Note: Requires backend table setup for user_preferences
    func syncToCloud() async {
        guard isUserAuthenticated,
              SupabaseService.shared.isConfigured else { return }
        
        do {
            let data = try JSONEncoder().encode(preferences)
            guard String(data: data, encoding: .utf8) != nil else { return }
            
            // TODO: Implement Supabase upsert when backend table is ready
            // try await SupabaseService.shared.client.from("user_preferences")
            //     .upsert(["user_id": userId, "preferences_json": jsonString])
            //     .execute()
            
            print("Preferences sync: Ready for cloud sync")
        } catch {
            print("Failed to prepare preferences for sync: \(error)")
        }
    }
    
    /// Load preferences from Supabase
    /// Note: Requires backend table setup for user_preferences
    func loadFromCloud() async {
        guard isUserAuthenticated,
              SupabaseService.shared.isConfigured else { return }
        
        // TODO: Implement Supabase fetch when backend table is ready
        // do {
        //     let response = try await SupabaseService.shared.client.from("user_preferences")
        //         .select()
        //         .eq("user_id", value: userId)
        //         .single()
        //         .execute()
        //     
        //     if let jsonString = response.data["preferences_json"] as? String,
        //        let data = jsonString.data(using: .utf8),
        //        let cloudPreferences = try? JSONDecoder().decode(AIUserPreferences.self, from: data) {
        //         preferences = cloudPreferences
        //         savePreferences()
        //     }
        // } catch {
        //     print("Failed to load preferences from cloud: \(error)")
        // }
        
        print("Preferences load from cloud: Feature pending backend setup")
    }
}

