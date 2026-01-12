//
//  DynamicIslandPreview.swift
//  Bible v1
//
//  Interactive preview component for Dynamic Island settings
//

import SwiftUI

struct DynamicIslandPreview: View {
    let mode: DynamicIslandSettingsView.PreviewMode
    let state: DynamicIslandSettingsView.PreviewState
    let settings: DynamicIslandSettings
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var animationPhase: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Dynamic Island mockup
            dynamicIslandMockup
            
            // Lock Screen mockup
            lockScreenMockup
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Dynamic Island Mockup
    
    private var dynamicIslandMockup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dynamic Island")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
            
            HStack {
                Spacer()
                
                // The island shape
                HStack(spacing: 10) {
                    // Leading content
                    leadingContent
                    
                    // Center content
                    centerContent
                    
                    // Trailing content
                    trailingContent
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var leadingContent: some View {
        if mode == .audio {
            if state == .playing && currentAudioSettings.audioAnimationsEnabled {
                Image(systemName: "waveform")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(accentColor)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            } else {
                Image(systemName: state == .paused ? "pause.fill" : "play.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(state == .paused ? .white.opacity(0.6) : accentColor)
            }
        } else {
            if state == .complete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.green)
            } else if currentAISettings.aiAnimationsEnabled {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(aiAccentColor)
                    .symbolEffect(.pulse, isActive: true)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(aiAccentColor)
            }
        }
    }
    
    @ViewBuilder
    private var centerContent: some View {
        if mode == .audio {
            Text("John 3:16")
                .font(.system(size: scaledFontSize(11), weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        } else {
            Text("TRC AI")
                .font(.system(size: scaledFontSize(11), weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        if mode == .audio {
            Text("3/31")
                .font(.system(size: scaledFontSize(10), weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        } else {
            if state == .streaming {
                Text("45%")
                    .font(.system(size: scaledFontSize(10), weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
            } else if state == .complete {
                Text("Done")
                    .font(.system(size: scaledFontSize(10), weight: .semibold))
                    .foregroundStyle(.green)
            } else {
                Text("AI")
                    .font(.system(size: scaledFontSize(10), weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Lock Screen Mockup
    
    private var lockScreenMockup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lock Screen")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
            
            if mode == .audio {
                audioLockScreenContent
            } else {
                aiLockScreenContent
            }
        }
    }
    
    private var audioLockScreenContent: some View {
        VStack(alignment: .leading, spacing: currentAudioSettings.audioCompactMode ? 8 : 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: currentAudioSettings.audioCompactMode ? 28 : 32, height: currentAudioSettings.audioCompactMode ? 28 : 32)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: currentAudioSettings.audioCompactMode ? 12 : 14))
                        .foregroundStyle(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("TRC Bible")
                        .font(.system(size: scaledFontSize(12), weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("John 3")
                        .font(.system(size: scaledFontSize(10)))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Text("Premium AI")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.08))
                    .clipShape(Capsule())
            }
            
            // Verse reference
            Text("John 3:16")
                .font(.system(size: scaledFontSize(13), weight: .semibold))
                .foregroundStyle(accentColor)
            
            // Verse text (if enabled)
            if currentAudioSettings.audioShowVerseText && !currentAudioSettings.audioCompactMode {
                Text("For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.")
                    .font(.system(size: scaledFontSize(12)))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(currentAudioSettings.audioCompactMode ? 2 : 4)
            }
            
            // Progress bar (if enabled)
            if currentAudioSettings.audioShowProgress {
                HStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.1))
                            
                            Capsule()
                                .fill(accentColor)
                                .frame(width: geo.size.width * 0.52)
                        }
                    }
                    .frame(height: 4)
                    
                    Text("16 of 31")
                        .font(.system(size: scaledFontSize(10), weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            // Controls
            HStack {
                Spacer()
                
                Image(systemName: "backward.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: state == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: state == .playing ? 0 : 1)
                }
                
                Spacer()
                
                Image(systemName: "forward.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: themeGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var aiLockScreenContent: some View {
        VStack(alignment: .leading, spacing: currentAISettings.aiCompactMode ? 8 : 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(aiAccentColor.opacity(0.15))
                        .frame(width: currentAISettings.aiCompactMode ? 28 : 32, height: currentAISettings.aiCompactMode ? 28 : 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: currentAISettings.aiCompactMode ? 12 : 14))
                        .foregroundStyle(aiAccentColor)
                        .symbolEffect(.pulse, isActive: currentAISettings.aiAnimationsEnabled && state != .complete)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("TRC AI")
                        .font(.system(size: scaledFontSize(12), weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Study")
                        .font(.system(size: scaledFontSize(10)))
                        .foregroundStyle(aiAccentColor.opacity(0.9))
                }
                
                Spacer()
                
                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)
                    
                    Text(statusText)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .clipShape(Capsule())
            }
            
            // Content based on state
            Group {
                switch state {
                case .thinking:
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(aiAccentColor.opacity(0.3 + Double(i) * 0.2))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        Text("Processing...")
                            .font(.system(size: scaledFontSize(12)))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                case .streaming:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The concept of faith in this passage speaks to a deep trust in God's promises...")
                            .font(.system(size: scaledFontSize(12)))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(currentAISettings.aiCompactMode ? 2 : 3)
                        
                        if currentAISettings.aiShowProgress {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(.white.opacity(0.1))
                                    
                                    Capsule()
                                        .fill(aiAccentColor)
                                        .frame(width: geo.size.width * 0.45)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                    
                case .complete:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Understanding Faith in John 3:16")
                            .font(.system(size: scaledFontSize(13), weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text("This verse reveals the depth of God's love for humanity and the gift of salvation through belief...")
                            .font(.system(size: scaledFontSize(12)))
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(currentAISettings.aiCompactMode ? 2 : 3)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 9))
                            Text("Tap to view")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(aiAccentColor.opacity(0.8))
                    }
                    
                default:
                    EmptyView()
                }
            }
            
            // Cancel button (for thinking/streaming)
            if state == .thinking || state == .streaming {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 5) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Cancel")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.08))
                    .clipShape(Capsule())
                    
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: aiThemeGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var currentAudioSettings: DynamicIslandSettings {
        settings
    }
    
    private var currentAISettings: DynamicIslandSettings {
        settings
    }
    
    private var accentColor: Color {
        let colors = DIThemeColors.colors(for: settings.audioTheme, mode: "audio")
        return colors.accent
    }
    
    private var aiAccentColor: Color {
        let colors = DIThemeColors.colors(for: settings.aiTheme, mode: "ai")
        return colors.accent
    }
    
    private var themeGradientColors: [Color] {
        let colors = DIThemeColors.colors(for: settings.audioTheme, mode: "audio")
        return colors.backgroundGradient
    }
    
    private var aiThemeGradientColors: [Color] {
        let colors = DIThemeColors.colors(for: settings.aiTheme, mode: "ai")
        return colors.backgroundGradient
    }
    
    private var statusColor: Color {
        switch state {
        case .thinking, .streaming: return aiAccentColor
        case .complete: return .green
        default: return .red
        }
    }
    
    private var statusText: String {
        switch state {
        case .thinking: return "Thinking"
        case .streaming: return "Writing"
        case .complete: return "Ready"
        default: return "Paused"
        }
    }
    
    private func scaledFontSize(_ base: CGFloat) -> CGFloat {
        let scale = mode == .audio ? settings.audioTextSize.scaleFactor : settings.aiTextSize.scaleFactor
        return base * scale
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            animationPhase = (animationPhase + 1) % 3
        }
    }
}

#Preview {
    DynamicIslandPreview(
        mode: .audio,
        state: .playing,
        settings: .default
    )
    .padding()
    .background(Color.black)
}



