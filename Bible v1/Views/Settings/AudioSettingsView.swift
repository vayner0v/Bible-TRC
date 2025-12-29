//
//  AudioSettingsView.swift
//  Bible v1
//
//  Reorganized audio settings with reduced choice anxiety
//

import SwiftUI
import AVFoundation

struct AudioSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var audioService = AudioService.shared
    @ObservedObject private var openAITTSService = OpenAITTSService.shared
    
    @State private var isTestingVoice = false
    @State private var testingVoiceId: String?
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Voice Quality Section (Top-Level Choice)
                    voiceQualitySection
                    
                    // Voice Selection Section
                    voiceSelectionSection
                    
                    // Playback Settings Section
                    playbackSettingsSection
                    
                    // Immersive Mode Link
                    immersiveModeLink
                }
                .padding()
            }
        }
        .navigationTitle("Audio & Voice")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Voice Quality Section
    
    private var voiceQualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VOICE QUALITY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                VoiceQualityCard(
                    title: "Premium AI",
                    subtitle: "Natural, expressive narration",
                    detail: "Requires internet • Powered by OpenAI",
                    icon: "waveform.circle.fill",
                    isSelected: settings.preferredVoiceType == .premium,
                    isPremiumRequired: true,
                    themeManager: themeManager
                ) {
                    settings.preferredVoiceType = .premium
                    HapticManager.shared.selection()
                }
                
                VoiceQualityCard(
                    title: "Built-in Enhanced",
                    subtitle: "Works offline • Device processing",
                    detail: "No subscription required",
                    icon: "speaker.wave.3.fill",
                    isSelected: settings.preferredVoiceType == .builtin,
                    isPremiumRequired: false,
                    themeManager: themeManager
                ) {
                    settings.preferredVoiceType = .builtin
                    HapticManager.shared.selection()
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Voice Selection Section
    
    private var voiceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT VOICE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if settings.preferredVoiceType == .premium {
                    // OpenAI voices
                    ForEach(OpenAIVoice.allCases) { voice in
                        VoiceSelectionRow(
                            name: voice.displayName,
                            description: voice.description,
                            isSelected: openAITTSService.selectedVoice == voice,
                            isTesting: testingVoiceId == voice.rawValue && isTestingVoice,
                            themeManager: themeManager,
                            onSelect: {
                                openAITTSService.setVoice(voice)
                                HapticManager.shared.selection()
                            },
                            onTest: {
                                testVoice(voice)
                            }
                        )
                        
                        if voice != OpenAIVoice.allCases.last {
                            Divider()
                                .background(themeManager.dividerColor)
                        }
                    }
                } else {
                    // Built-in voices
                    let voices = audioService.getAvailableEnhancedVoices()
                    
                    if voices.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No enhanced voices found")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textColor)
                                Text("Download enhanced voices in Settings > Accessibility > Spoken Content > Voices")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(voices, id: \.id) { voice in
                            VoiceSelectionRow(
                                name: voice.name,
                                description: voice.quality,
                                isSelected: audioService.selectedBuiltinVoiceId == voice.id,
                                isTesting: testingVoiceId == voice.id && isTestingVoice,
                                themeManager: themeManager,
                                onSelect: {
                                    audioService.setBuiltinVoice(voice.id)
                                    HapticManager.shared.selection()
                                },
                                onTest: {
                                    testBuiltinVoice(voice.id)
                                }
                            )
                            
                            if voice.id != voices.last?.id {
                                Divider()
                                    .background(themeManager.dividerColor)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Playback Settings Section
    
    private var playbackSettingsSection: some View {
        ResettableSection(
            title: "Playback",
            resetTitle: "Reset Playback Settings",
            onReset: {
                settings.resetAudioSettings()
            }
        ) {
            VStack(spacing: 16) {
                // Speed slider
                SettingsSliderRow(
                    title: "Reading Speed",
                    value: $settings.speechRate,
                    range: 0.3...0.7,
                    step: 0.05,
                    tickMarks: [0.3, 0.4, 0.5, 0.6, 0.7],
                    formatValue: { speedDisplayName(Float($0)) }
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Auto-continue toggle
                SettingsToggleRow(
                    icon: "arrow.right.circle",
                    title: "Auto-Continue",
                    subtitle: "Automatically start next chapter",
                    isOn: $settings.autoContinueToNextChapter
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Normalize loudness toggle
                SettingsToggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "Normalize Loudness",
                    subtitle: "Consistent volume across voices",
                    isOn: $settings.normalizeLoudness
                )
            }
        }
    }
    
    // MARK: - Immersive Mode Link
    
    private var immersiveModeLink: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPERIENCE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            NavigationLink {
                ImmersiveModeSettingsView()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(themeManager.accentGradient)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "sparkles")
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Immersive Mode")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(settings.immersiveModeEnabled ? "Enabled" : "Disabled")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(14)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func speedDisplayName(_ rate: Float) -> String {
        switch rate {
        case ..<0.4: return "Slow"
        case 0.4..<0.55: return "Normal"
        case 0.55..<0.65: return "Fast"
        default: return "Very Fast"
        }
    }
    
    private func testVoice(_ voice: OpenAIVoice) {
        isTestingVoice = true
        testingVoiceId = voice.rawValue
        
        // Play a short sample
        Task {
            do {
                let sample = "The Lord is my shepherd; I shall not want."
                let previousVoice = openAITTSService.selectedVoice
                openAITTSService.setVoice(voice)
                
                let audioData = try await openAITTSService.generateSpeech(text: sample)
                let player = try AVAudioPlayer(data: audioData)
                player.play()
                
                // Wait for playback
                try await Task.sleep(nanoseconds: UInt64(player.duration * 1_000_000_000))
                
                await MainActor.run {
                    isTestingVoice = false
                    testingVoiceId = nil
                }
                
                // Restore previous voice if different
                if previousVoice != voice {
                    openAITTSService.setVoice(previousVoice)
                }
            } catch {
                await MainActor.run {
                    isTestingVoice = false
                    testingVoiceId = nil
                }
            }
        }
    }
    
    private func testBuiltinVoice(_ voiceId: String) {
        isTestingVoice = true
        testingVoiceId = voiceId
        
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: "The Lord is my shepherd; I shall not want.")
        
        if let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        }
        utterance.rate = Float(settings.speechRate)
        
        synthesizer.speak(utterance)
        
        // Reset after approximate duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isTestingVoice = false
            testingVoiceId = nil
        }
    }
}

// MARK: - Voice Quality Card

struct VoiceQualityCard: View {
    let title: String
    let subtitle: String
    let detail: String
    let icon: String
    let isSelected: Bool
    let isPremiumRequired: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accentColor.opacity(0.15) : themeManager.backgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textColor)
                        
                        if isPremiumRequired {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.accentColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding()
            .background(isSelected ? themeManager.accentColor.opacity(0.08) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? themeManager.accentColor : themeManager.dividerColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Voice Selection Row

struct VoiceSelectionRow: View {
    let name: String
    let description: String
    let isSelected: Bool
    let isTesting: Bool
    let themeManager: ThemeManager
    let onSelect: () -> Void
    let onTest: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            // Test button
            Button(action: onTest) {
                if isTesting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .disabled(isTesting)
            .accessibilityLabel("Test \(name) voice")
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AudioSettingsView()
    }
}

