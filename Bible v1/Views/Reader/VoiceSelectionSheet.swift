//
//  VoiceSelectionSheet.swift
//  Bible v1
//
//  Voice Selection for Audio Playback - Redesigned
//

import SwiftUI
import AVFoundation
import Combine

/// Voice type selection for audio playback
enum VoiceType: String, CaseIterable, Identifiable {
    case premium = "premium"
    case builtin = "builtin"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .premium: return "Premium AI"
        case .builtin: return "Built-in"
        }
    }
    
    var subtitle: String {
        switch self {
        case .premium: return "Natural, expressive narration"
        case .builtin: return "Works offline"
        }
    }
    
    var icon: String {
        switch self {
        case .premium: return "waveform.circle.fill"
        case .builtin: return "speaker.wave.3.fill"
        }
    }
}

/// Available enhanced system voices
struct EnhancedVoice: Identifiable, Hashable {
    let id: String
    let name: String
    let language: String
    let quality: VoiceQuality
    let identifier: String
    
    enum VoiceQuality: String {
        case enhanced = "Enhanced"
        case premium = "Premium"
        case standard = "Standard"
        
        var color: Color {
            switch self {
            case .enhanced: return ThemeManager.shared.accentColor
            case .premium: return ThemeManager.shared.accentColor
            case .standard: return .gray
            }
        }
    }
    
    static func availableEnhancedVoices() -> [EnhancedVoice] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        var enhancedVoices: [EnhancedVoice] = []
        
        for voice in voices {
            guard voice.language.hasPrefix("en") else { continue }
            
            let quality: VoiceQuality
            let identifier = voice.identifier.lowercased()
            
            if identifier.contains("premium") || identifier.contains("enhanced") {
                quality = .premium
            } else if identifier.contains("compact") {
                continue
            } else if voice.quality == .enhanced {
                quality = .enhanced
            } else {
                quality = .standard
            }
            
            guard quality != .standard else { continue }
            
            let voiceEntry = EnhancedVoice(
                id: voice.identifier,
                name: voice.name,
                language: voice.language,
                quality: quality,
                identifier: voice.identifier
            )
            enhancedVoices.append(voiceEntry)
        }
        
        return enhancedVoices.sorted { $0.name < $1.name }
    }
}

/// Sheet for selecting voice type before playback
struct VoiceSelectionSheet: View {
    let onSelect: (VoiceType) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var openAITTSService = OpenAITTSService.shared
    @ObservedObject private var audioService = AudioService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    
    @State private var selectedType: VoiceType = .builtin
    @State private var showPaywall = false
    
    // Preview state
    @State private var isPreviewing = false
    @State private var previewingVoiceId: String?
    @State private var isPreviewLoading = false
    @State private var premiumPreviewPlayer: AVAudioPlayer?
    
    // Built-in voice preview controller
    @StateObject private var builtinPreviewController = VoicePreviewController()
    
    // Resume state
    @State private var lastAudioPosition: AudioPlaybackPosition?
    
    /// Check if user has premium access
    private var hasPremiumAccess: Bool {
        if PromoCodeService.shared.isCustomerSimulationMode {
            return false
        }
        return subscriptionManager.isPremium || PromoCodeService.shared.isPromoActivated
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient background
                SubtleGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Compact header
                            headerSection
                            
                            // Resume section (if available)
                            if let position = lastAudioPosition {
                                resumeSection(position: position)
                            }
                            
                            // Voice type toggle
                            voiceTypeToggle
                            
                            // Subscription notice for premium
                            if !hasPremiumAccess && selectedType == .premium {
                                premiumRequiredNotice
                            }
                            
                            // Voice list based on selection
                            voiceListSection
                            
                            // Info banner
                            infoBanner
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Bottom CTA
                    bottomCTA
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        stopAllPreviews()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onDisappear {
            stopAllPreviews()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: subscriptionManager.isPremium) { _, isPremium in
            if isPremium && showPaywall {
                showPaywall = false
                selectedType = .premium
                settings.preferredVoiceType = .premium
                onSelect(.premium)
                dismiss()
            }
        }
        .onAppear {
            // Sync from settings
            selectedType = settings.preferredVoiceType == .premium ? .premium : .builtin
            audioService.syncSubscriptionStatus()
            
            // Load last audio position
            lastAudioPosition = audioService.getLastAudioPosition()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "headphones")
                    .font(.title2)
                    .foregroundColor(themeManager.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Choose Your Voice")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Select how you'd like to listen")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Resume Section
    
    private func resumeSection(position: AudioPlaybackPosition) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(themeManager.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue Listening")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(position.displayString)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Resume button
                Button {
                    resumeFromPosition(position)
                } label: {
                    Text("Resume")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(themeManager.accentColor)
                        .cornerRadius(20)
                }
                
                // Clear button
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        audioService.clearAudioPlaybackPosition()
                        lastAudioPosition = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(8)
                        .background(Circle().fill(themeManager.cardBackgroundColor))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Voice Type Toggle
    
    private var voiceTypeToggle: some View {
        HStack(spacing: 12) {
            ForEach(VoiceType.allCases) { type in
                VoiceTypeButton(
                    type: type,
                    isSelected: selectedType == type,
                    isPremiumLocked: type == .premium && !hasPremiumAccess,
                    themeManager: themeManager
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = type
                    }
                    HapticManager.shared.lightImpact()
                }
            }
        }
    }
    
    // MARK: - Premium Required Notice
    
    private var premiumRequiredNotice: some View {
        HStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .foregroundColor(.orange)
            
            Text("Subscribe to unlock premium voices")
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
    }
    
    // MARK: - Voice List Section
    
    private var voiceListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedType == .premium ? "AI Voices" : "System Voices")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                if selectedType == .premium {
                    Text("tts-1")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(themeManager.accentColor.opacity(0.15))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            VStack(spacing: 2) {
                if selectedType == .premium {
                    premiumVoiceList
                } else {
                    builtinVoiceList
                }
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Premium Voice List
    
    private var premiumVoiceList: some View {
        ForEach(Array(OpenAIVoice.allCases.enumerated()), id: \.element.id) { index, voice in
            VoiceRow(
                name: voice.displayName,
                description: voice.description,
                isSelected: openAITTSService.selectedVoice == voice,
                isPreviewing: previewingVoiceId == voice.rawValue && isPreviewing,
                isLoading: previewingVoiceId == voice.rawValue && isPreviewLoading,
                themeManager: themeManager,
                onSelect: {
                    openAITTSService.setVoice(voice)
                    HapticManager.shared.selection()
                },
                onPreview: {
                    previewPremiumVoice(voice)
                }
            )
            
            if index < OpenAIVoice.allCases.count - 1 {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
    
    // MARK: - Built-in Voice List
    
    private var builtinVoiceList: some View {
        let voices = EnhancedVoice.availableEnhancedVoices()
        
        return Group {
            if voices.isEmpty {
                noVoicesView
            } else {
                ForEach(Array(voices.enumerated()), id: \.element.id) { index, voice in
                    VoiceRow(
                        name: voice.name,
                        description: voice.quality.rawValue,
                        isSelected: audioService.selectedBuiltinVoiceId == voice.identifier,
                        isPreviewing: previewingVoiceId == voice.identifier && isPreviewing,
                        isLoading: previewingVoiceId == voice.identifier && isPreviewLoading,
                        themeManager: themeManager,
                        onSelect: {
                            audioService.setBuiltinVoice(voice.identifier)
                            HapticManager.shared.selection()
                        },
                        onPreview: {
                            previewBuiltinVoice(voice.identifier)
                        }
                    )
                    
                    if index < voices.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
    }
    
    private var noVoicesView: some View {
        VStack(spacing: 10) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.title2)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("No Enhanced Voices")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
            
            Text("Settings → Accessibility → Spoken Content → Voices")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedType == .premium ? "sparkles" : "checkmark.seal.fill")
                .foregroundColor(selectedType == .premium ? themeManager.accentColor : .green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedType == .premium ? "Powered by OpenAI" : "Works Offline")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Text(selectedType == .premium ? "Natural AI-powered narration" : "No internet required")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            (selectedType == .premium ? themeManager.accentColor : Color.green).opacity(0.1)
        )
        .cornerRadius(12)
    }
    
    // MARK: - Bottom CTA
    
    private var bottomCTA: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)
            
            Button {
                if selectedType == .premium && !hasPremiumAccess {
                    showPaywall = true
                } else {
                    HapticManager.shared.success()
                    settings.preferredVoiceType = selectedType == .premium ? .premium : .builtin
                    stopAllPreviews()
                    onSelect(selectedType)
                    dismiss()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.body)
                    Text("Start Listening")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(themeManager.accentColor)
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(themeManager.backgroundColor)
        }
    }
    
    // MARK: - Preview Functions
    
    private func previewPremiumVoice(_ voice: OpenAIVoice) {
        // Stop any current preview
        stopAllPreviews()
        
        isPreviewLoading = true
        isPreviewing = true
        previewingVoiceId = voice.rawValue
        
        Task {
            do {
                let sampleText = "The Lord is my shepherd; I shall not want."
                let audioData = try await openAITTSService.generateSpeech(text: sampleText, voice: voice)
                
                await MainActor.run {
                    isPreviewLoading = false
                }
                
                let player = try AVAudioPlayer(data: audioData)
                await MainActor.run {
                    premiumPreviewPlayer = player
                }
                player.play()
                
                // Wait for playback to finish
                try await Task.sleep(nanoseconds: UInt64(player.duration * 1_000_000_000))
                
                await MainActor.run {
                    isPreviewing = false
                    previewingVoiceId = nil
                    premiumPreviewPlayer = nil
                }
            } catch {
                await MainActor.run {
                    isPreviewLoading = false
                    isPreviewing = false
                    previewingVoiceId = nil
                }
            }
        }
    }
    
    private func previewBuiltinVoice(_ voiceId: String) {
        // Stop any current preview
        stopAllPreviews()
        
        guard let voice = AVSpeechSynthesisVoice(identifier: voiceId) else { return }
        
        isPreviewLoading = true
        isPreviewing = true
        previewingVoiceId = voiceId
        
        builtinPreviewController.startPreview(
            text: "The Lord is my shepherd; I shall not want.",
            voice: voice,
            rate: audioService.speechRate
        ) {
            DispatchQueue.main.async {
                self.isPreviewing = false
                self.previewingVoiceId = nil
                self.isPreviewLoading = false
            }
        }
        
        // Clear loading state after voice starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isPreviewLoading = false
        }
    }
    
    private func stopAllPreviews() {
        builtinPreviewController.stopPreview()
        premiumPreviewPlayer?.stop()
        premiumPreviewPlayer = nil
        isPreviewing = false
        previewingVoiceId = nil
        isPreviewLoading = false
    }
    
    private func resumeFromPosition(_ position: AudioPlaybackPosition) {
        // Clear the saved position since we're resuming
        audioService.clearAudioPlaybackPosition()
        lastAudioPosition = nil
        
        // Set the voice type from the saved position
        selectedType = position.voiceType == .premium ? .premium : .builtin
        settings.preferredVoiceType = position.voiceType
        
        HapticManager.shared.success()
        stopAllPreviews()
        
        // Notify to resume from saved position
        NotificationCenter.default.post(
            name: .resumeAudioFromPosition,
            object: nil,
            userInfo: ["position": position]
        )
        
        dismiss()
    }
}

// MARK: - Voice Type Button

struct VoiceTypeButton: View {
    let type: VoiceType
    let isSelected: Bool
    let isPremiumLocked: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: type.icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : themeManager.secondaryTextColor)
                    
                    if isPremiumLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(4)
                            .background(Circle().fill(themeManager.cardBackgroundColor))
                            .offset(x: 16, y: 16)
                    }
                }
                
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? themeManager.textColor : themeManager.secondaryTextColor)
                
                Text(type.subtitle)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Voice Row

struct VoiceRow: View {
    let name: String
    let description: String
    let isSelected: Bool
    let isPreviewing: Bool
    let isLoading: Bool
    let themeManager: ThemeManager
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Selection area
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    // Voice avatar
                    ZStack {
                        Circle()
                            .fill(isSelected ? themeManager.accentColor.opacity(0.15) : themeManager.backgroundColor)
                            .frame(width: 42, height: 42)
                        
                        if isPreviewing {
                            // Animated waveform
                            HStack(spacing: 2) {
                                ForEach(0..<3, id: \.self) { i in
                                    Capsule()
                                        .fill(themeManager.accentColor)
                                        .frame(width: 3, height: CGFloat.random(in: 8...18))
                                        .animation(
                                            .easeInOut(duration: 0.3)
                                            .repeatForever()
                                            .delay(Double(i) * 0.1),
                                            value: isPreviewing
                                        )
                                }
                            }
                        } else {
                            Text(String(name.prefix(1)))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
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
                            .font(.title3)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            // Preview button
            Button(action: onPreview) {
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if isPreviewing {
                        Image(systemName: "stop.fill")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .frame(width: 36, height: 36)
                .background(themeManager.accentColor.opacity(0.1))
                .clipShape(Circle())
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Subtle Gradient Background

struct SubtleGradientBackground: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        LinearGradient(
            colors: [
                themeManager.backgroundColor,
                themeManager.accentColor.opacity(0.03),
                themeManager.backgroundColor
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Voice Preview Controller

@MainActor
final class VoicePreviewController: NSObject, ObservableObject {
    private var synthesizer: AVSpeechSynthesizer?
    private var onComplete: (() -> Void)?
    private var delegateHandler: SpeechDelegateHandler?
    
    @Published var isPlaying = false
    
    override init() {
        super.init()
        let synth = AVSpeechSynthesizer()
        self.synthesizer = synth
        self.delegateHandler = SpeechDelegateHandler { [weak self] finished in
            Task { @MainActor in
                self?.isPlaying = false
                if finished {
                    self?.onComplete?()
                }
                self?.onComplete = nil
            }
        }
        synth.delegate = delegateHandler
    }
    
    func startPreview(text: String, voice: AVSpeechSynthesisVoice, rate: Float, completion: @escaping () -> Void) {
        stopPreview()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        
        onComplete = completion
        isPlaying = true
        synthesizer?.speak(utterance)
    }
    
    func stopPreview() {
        if synthesizer?.isSpeaking == true {
            synthesizer?.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        onComplete = nil
    }
}

/// Separate delegate handler to avoid Sendable issues
private class SpeechDelegateHandler: NSObject, AVSpeechSynthesizerDelegate {
    private let onFinish: (Bool) -> Void
    
    init(onFinish: @escaping (Bool) -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish(true)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish(false)
    }
}

#Preview {
    VoiceSelectionSheet { type in
        print("Selected: \(type)")
    }
}
