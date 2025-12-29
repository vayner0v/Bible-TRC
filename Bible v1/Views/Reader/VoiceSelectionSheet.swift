//
//  VoiceSelectionSheet.swift
//  Bible v1
//
//  Voice Selection for Audio Playback
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
        case .premium: return "Premium Voice"
        case .builtin: return "Built-in Enhanced"
        }
    }
    
    var subtitle: String {
        switch self {
        case .premium: return "AI-powered natural narration"
        case .builtin: return "High-quality system voice"
        }
    }
    
    var icon: String {
        switch self {
        case .premium: return "waveform.circle.fill"
        case .builtin: return "speaker.wave.3.fill"
        }
    }
    
    var badgeText: String? {
        switch self {
        case .premium: return "AI"
        case .builtin: return nil
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
            // Filter for English enhanced/premium voices
            guard voice.language.hasPrefix("en") else { continue }
            
            let quality: VoiceQuality
            let identifier = voice.identifier.lowercased()
            
            if identifier.contains("premium") || identifier.contains("enhanced") {
                quality = .premium
            } else if identifier.contains("compact") {
                continue // Skip compact/low quality voices
            } else if voice.quality == .enhanced {
                quality = .enhanced
            } else {
                quality = .standard
            }
            
            // Only include enhanced or premium voices
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
        
        // Return empty array if no enhanced voices found - UI will show download instructions
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
    @State private var showBuiltinVoices = false
    @State private var isPreviewing = false
    @State private var previewingVoice: String?
    @State private var showPaywall = false
    @State private var isPreviewLoading = false
    
    // Use a class wrapper to hold the synthesizer so it can be accessed in delegate
    @StateObject private var previewController = VoicePreviewController()
    
    /// Check if user has premium access (subscription or promo code)
    private var hasPremiumAccess: Bool {
        subscriptionManager.isPremium || PromoCodeService.shared.isPromoActivated
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "headphones.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 10)
                            
                            Text("Choose Your Voice")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textColor)
                            
                            Text("Select how you'd like to listen")
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.top, 20)
                        
                        // Subscription requirement notice for premium
                        if !hasPremiumAccess && selectedType == .premium {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Premium Required")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeManager.textColor)
                                    Text("Subscribe to unlock AI voices")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Voice Options
                        VStack(spacing: 16) {
                            ForEach(VoiceType.allCases) { type in
                                VoiceOptionCard(
                                    type: type,
                                    isSelected: selectedType == type,
                                    themeManager: themeManager,
                                    openAITTSService: openAITTSService,
                                    isPremiumSubscriber: hasPremiumAccess
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedType = type
                                    }
                                    HapticManager.shared.lightImpact()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Voice Details Section
                        if selectedType == .premium {
                            PremiumVoiceDetails(
                                openAITTSService: openAITTSService,
                                themeManager: themeManager
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        } else {
                            BuiltinVoiceDetails(
                                audioService: audioService,
                                themeManager: themeManager,
                                onPreview: { voiceId in
                                    previewVoice(voiceId)
                                },
                                isPreviewing: isPreviewing,
                                previewingVoice: previewingVoice,
                                isPreviewLoading: isPreviewLoading
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Bottom CTA
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button {
                            // Check if premium is selected but user is not subscribed
                            if selectedType == .premium && !hasPremiumAccess {
                                showPaywall = true
                            } else {
                                HapticManager.shared.success()
                                // Save selection to settings for sync with settings toggle
                                settings.preferredVoiceType = selectedType == .premium ? .premium : .builtin
                                onSelect(selectedType)
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.title3)
                                Text("Start Listening")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: themeManager.accentColor.opacity(0.3), radius: 10, y: 5)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [themeManager.backgroundColor.opacity(0), themeManager.backgroundColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
        }
        .onDisappear {
            previewController.stopPreview()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onChange(of: subscriptionManager.isPremium) { _, isPremium in
            // If user just subscribed, auto-select premium and dismiss
            if isPremium && showPaywall {
                showPaywall = false
                selectedType = .premium
                settings.preferredVoiceType = .premium
                onSelect(.premium)
                dismiss()
            }
        }
        .onAppear {
            // Sync selected voice type from settings
            selectedType = settings.preferredVoiceType == .premium ? .premium : .builtin
            // Sync AudioService subscription status when sheet appears
            audioService.syncSubscriptionStatus()
        }
    }
    
    private func previewVoice(_ voiceId: String) {
        // Stop any currently playing preview immediately
        previewController.stopPreview()
        
        guard let voice = AVSpeechSynthesisVoice(identifier: voiceId) else { return }
        
        // Set loading state
        isPreviewLoading = true
        isPreviewing = true
        previewingVoice = voiceId
        
        // Start preview with completion handler
        previewController.startPreview(
            text: "For God so loved the world, that he gave his only Son.",
            voice: voice,
            rate: audioService.speechRate
        ) {
            // Preview finished - reset state
            DispatchQueue.main.async {
                self.isPreviewing = false
                self.previewingVoice = nil
                self.isPreviewLoading = false
            }
        }
        
        // Clear loading state after a short delay (voice has started)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isPreviewLoading = false
        }
    }
}

// MARK: - Voice Preview Controller

/// Controller class to manage voice preview playback with proper cancellation
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
        // Stop any current preview first
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

/// Separate delegate handler to avoid Sendable issues with AVSpeechSynthesizer
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

// MARK: - Voice Option Card

struct VoiceOptionCard: View {
    let type: VoiceType
    let isSelected: Bool
    let themeManager: ThemeManager
    let openAITTSService: OpenAITTSService
    let isPremiumSubscriber: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : themeManager.accentColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(type.displayName)
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        if let badge = type.badgeText {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.accentGradient)
                                .cornerRadius(4)
                        }
                        
                        if type == .premium && !isPremiumSubscriber {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text(type.subtitle)
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    if type == .premium {
                        Text("Voice: \(openAITTSService.selectedVoice.displayName)")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: isSelected ? themeManager.accentColor.opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 10 : 5)
        }
        .buttonStyle(VoiceScaleButtonStyle())
    }
}

// MARK: - Premium Voice Details

struct PremiumVoiceDetails: View {
    @ObservedObject var openAITTSService: OpenAITTSService
    let themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium AI Voices")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(OpenAIVoice.allCases) { voice in
                        PremiumVoiceCard(
                            voice: voice,
                            isSelected: openAITTSService.selectedVoice == voice,
                            themeManager: themeManager
                        ) {
                            openAITTSService.setVoice(voice)
                            HapticManager.shared.lightImpact()
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Info card
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(themeManager.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Powered by OpenAI")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    Text("Natural AI voices with expressive narration")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
            }
            .padding()
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct PremiumVoiceCard: View {
    let voice: OpenAIVoice
    let isSelected: Bool
    let themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              themeManager.accentGradient :
                              LinearGradient(colors: [themeManager.cardBackgroundColor, themeManager.cardBackgroundColor], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                    
                    Text(String(voice.displayName.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : themeManager.accentColor)
                }
                
                Text(voice.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Text(voice.description)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(1)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(VoiceScaleButtonStyle())
    }
}

// MARK: - Built-in Voice Details

struct BuiltinVoiceDetails: View {
    @ObservedObject var audioService: AudioService
    let themeManager: ThemeManager
    let onPreview: (String) -> Void
    let isPreviewing: Bool
    let previewingVoice: String?
    let isPreviewLoading: Bool
    
    @State private var availableVoices: [EnhancedVoice] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enhanced System Voices")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
                .padding(.horizontal)
            
            if availableVoices.isEmpty {
                // No enhanced voices available - show download instructions
                VStack(spacing: 12) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.title)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("No Enhanced Voices Found")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Download enhanced voices in Settings → Accessibility → Spoken Content → Voices")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableVoices) { voice in
                            BuiltinVoiceCard(
                                voice: voice,
                                isSelected: audioService.selectedBuiltinVoiceId == voice.identifier,
                                isPreviewing: previewingVoice == voice.identifier,
                                isAnyPreviewLoading: isPreviewLoading,
                                themeManager: themeManager,
                                onTap: {
                                    audioService.setBuiltinVoice(voice.identifier)
                                    HapticManager.shared.lightImpact()
                                },
                                onPreview: {
                                    onPreview(voice.identifier)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Speed control
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Reading Speed")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Text(audioService.rateDisplayName(audioService.speechRate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.accentColor)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "tortoise.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Slider(
                        value: Binding(
                            get: { Double(audioService.speechRate) },
                            set: { audioService.setRate(Float($0)) }
                        ),
                        in: 0.3...0.7
                    )
                    .tint(themeManager.accentColor)
                    
                    Image(systemName: "hare.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Info card
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Works Offline")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    Text("No internet required for built-in voices")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .onAppear {
            availableVoices = EnhancedVoice.availableEnhancedVoices()
        }
    }
}

struct BuiltinVoiceCard: View {
    let voice: EnhancedVoice
    let isSelected: Bool
    let isPreviewing: Bool
    let isAnyPreviewLoading: Bool
    let themeManager: ThemeManager
    let onTap: () -> Void
    let onPreview: () -> Void
    
    /// Disable preview button if another voice is being previewed/loading
    private var isPreviewDisabled: Bool {
        isAnyPreviewLoading && !isPreviewing
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                        .frame(width: 50, height: 50)
                    
                    if isPreviewing {
                        // Animated waveform during preview
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Capsule()
                                    .fill(isSelected ? Color.white : themeManager.accentColor)
                                    .frame(width: 3, height: CGFloat.random(in: 8...20))
                                    .animation(
                                        .easeInOut(duration: 0.3)
                                        .repeatForever()
                                        .delay(Double(i) * 0.1),
                                        value: isPreviewing
                                    )
                            }
                        }
                    } else {
                        Text(String(voice.name.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : themeManager.accentColor)
                    }
                }
                
                Text(voice.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Text(voice.quality.rawValue)
                    .font(.caption2)
                    .foregroundColor(voice.quality.color)
                
                // Preview button - disabled when another preview is loading
                Button(action: onPreview) {
                    Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                        .font(.caption)
                        .foregroundColor(isPreviewDisabled ? themeManager.secondaryTextColor.opacity(0.5) : themeManager.accentColor)
                        .padding(6)
                        .background(Circle().fill(themeManager.accentColor.opacity(isPreviewDisabled ? 0.05 : 0.1)))
                }
                .disabled(isPreviewDisabled)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(VoiceScaleButtonStyle())
    }
}

// MARK: - Animated Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        LinearGradient(
            colors: [
                themeManager.backgroundColor,
                themeManager.accentColor.opacity(0.1),
                themeManager.backgroundColor
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Voice Scale Button Style

struct VoiceScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    VoiceSelectionSheet { type in
        print("Selected: \(type)")
    }
}
