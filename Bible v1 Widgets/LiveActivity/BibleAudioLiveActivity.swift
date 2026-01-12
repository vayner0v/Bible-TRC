//
//  BibleAudioLiveActivity.swift
//  Bible v1 Widgets
//
//  Dynamic Island and Lock Screen UI for Bible audio playback
//  Features full-width text layout, themed appearance, and background-executing controls
//

import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

/// Live Activity widget for Bible audio playback
struct BibleAudioLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BibleAudioAttributes.self) { context in
            // Lock screen / notification banner - Full width layout
            ThemedAudioLockScreen(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ThemedAudioExpandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ThemedAudioExpandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ThemedAudioExpandedCenter(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ThemedAudioExpandedBottom(context: context)
                }
            } compactLeading: {
                ThemedAudioCompactLeading(context: context)
            } compactTrailing: {
                ThemedAudioCompactTrailing(context: context)
            } minimal: {
                ThemedAudioMinimal(context: context)
            }
            .keylineTint(ThemeColors.audio(for: loadSettings().audioTheme).accent)
        }
    }
    
    private func loadSettings() -> DynamicIslandWidgetSettings {
        DynamicIslandWidgetSettings.load()
    }
}

// MARK: - Settings Helper

private func loadSettings() -> DynamicIslandWidgetSettings {
    DynamicIslandWidgetSettings.load()
}

private func themeColors() -> ThemeColors {
    ThemeColors.audio(for: loadSettings().audioTheme)
}

// MARK: - Themed Lock Screen View

struct ThemedAudioLockScreen: View {
    let context: ActivityViewContext<BibleAudioAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.audio(for: settings.audioTheme) }
    private var textScale: CGFloat { settings.audioTextSize.scaleFactor }
    
    var body: some View {
        VStack(alignment: .leading, spacing: settings.audioCompactMode ? 6 : 8) {
            // Header row - only show in compact mode
            if settings.audioCompactMode {
                headerRow
            }
            
            // Verse reference - Dynamic (with book name in non-compact mode)
            Text(context.state.reference)
                .font(.system(size: settings.audioCompactMode ? 14 * textScale : 16 * textScale, weight: .semibold))
                .foregroundStyle(colors.accent)
            
            // Full width verse text - Dynamic (if enabled)
            if settings.audioShowVerseText && !settings.audioCompactMode {
                verseTextContent
            }
            
            // Progress section (if enabled)
            if settings.audioShowProgress {
                progressSection
            }
            
            // Controls
            controlsSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: colors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var headerRow: some View {
        HStack(spacing: 8) {
            // App icon
            Image(systemName: "book.closed.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(colors.accent)
            
            // Dynamic book and chapter
            Text(context.attributes.chapterReference)
                .font(.system(size: 13 * textScale, weight: .semibold))
                .foregroundStyle(colors.text)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var verseTextContent: some View {
        if context.state.isLoading {
            HStack(spacing: 6) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colors.text))
                    .scaleEffect(0.7)
                Text("Loading audio...")
                    .font(.system(size: 13 * textScale))
                    .foregroundStyle(colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(context.state.verseText)
                .font(.system(size: 13 * textScale, weight: .regular))
                .foregroundStyle(colors.text.opacity(0.85))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var progressSection: some View {
        HStack(spacing: 10) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colors.progressBackground)
                    
                    Capsule()
                        .fill(colors.progressFill)
                        .frame(width: max(0, geo.size.width * context.state.progress))
                }
            }
            .frame(height: 3)
            
            // Progress text
            Text(context.state.progressText)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(colors.secondaryText)
                .fixedSize()
        }
    }
    
    private var controlsSection: some View {
        HStack {
            Spacer()
            
            // Previous button
            Button(intent: AudioControlIntent(action: .previous)) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(context.state.currentVerse == 0 ? colors.text.opacity(0.25) : colors.text.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Play/Pause button
            Button(intent: AudioControlIntent(action: .toggle)) {
                ZStack {
                    Circle()
                        .fill(colors.accent)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(settings.audioTheme == .minimal ? .black : .white)
                        .offset(x: context.state.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Next button
            Button(intent: AudioControlIntent(action: .next)) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(context.state.currentVerse >= context.state.totalVerses - 1 ? colors.text.opacity(0.25) : colors.text.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.top, 2)
    }
}

// MARK: - Dynamic Island Compact Views

struct ThemedAudioCompactLeading: View {
    let context: ActivityViewContext<BibleAudioAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.audio(for: settings.audioTheme) }
    
    var body: some View {
        Group {
            if context.state.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colors.accent))
                    .scaleEffect(0.55)
            } else if context.state.isPlaying {
                if settings.audioAnimationsEnabled {
                    Image(systemName: "waveform")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(colors.accent)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(colors.accent)
                }
            } else {
                Image(systemName: "pause.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(colors.secondaryText)
            }
        }
    }
}

struct ThemedAudioCompactTrailing: View {
    let context: ActivityViewContext<BibleAudioAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.audio(for: settings.audioTheme) }
    
    var body: some View {
        Text(abbreviateReference(context.state.reference))
            .font(.system(size: 11 * settings.audioTextSize.scaleFactor, weight: .medium))
            .foregroundStyle(colors.text.opacity(0.85))
            .lineLimit(1)
    }
    
    private func abbreviateReference(_ ref: String) -> String {
        let parts = ref.split(separator: " ")
        guard parts.count >= 2 else { return ref }
        let book = String(parts[0].prefix(3))
        return "\(book) \(parts.dropFirst().joined(separator: " "))"
    }
}

// MARK: - Dynamic Island Expanded Views

struct ThemedAudioExpandedLeading: View {
    let context: ActivityViewContext<BibleAudioAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.audio(for: settings.audioTheme) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(colors.accent)
            
            Text(context.attributes.bookName)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(colors.secondaryText)
                .lineLimit(1)
        }
    }
}

struct ThemedAudioExpandedTrailing: View {
    let context: ActivityViewContext<BibleAudioAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.audio(for: settings.audioTheme) }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Image(systemName: context.state.voiceType.contains("Premium") ? "waveform.circle.fill" : "speaker.wave.2.fill")
                .font(.system(size: 12))
                .foregroundStyle(colors.secondaryText)
            
            Text(context.state.progressText)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(colors.secondaryText)
        }
    }
}

struct ThemedAudioExpandedCenter: View {
    let context: ActivityViewContext<BibleAudioAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.audio(for: settings.audioTheme) }
    
    var body: some View {
        VStack(spacing: 1) {
            Text(context.state.reference)
                .font(.system(size: 13 * settings.audioTextSize.scaleFactor, weight: .semibold))
                .foregroundStyle(colors.text)
                .lineLimit(1)
            
            Text(context.state.isLoading ? "Loading..." : (context.state.isPlaying ? "Playing" : "Paused"))
                .font(.system(size: 10))
                .foregroundStyle(context.state.isPlaying ? colors.accent : colors.secondaryText)
        }
    }
}

struct ThemedAudioExpandedBottom: View {
    let context: ActivityViewContext<BibleAudioAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.audio(for: settings.audioTheme) }
    
    var body: some View {
        VStack(spacing: 10) {
            // Verse text - Dynamic (if enabled)
            if settings.audioShowVerseText {
                Text(context.state.verseText)
                    .font(.system(size: 11 * settings.audioTextSize.scaleFactor))
                    .foregroundStyle(colors.text.opacity(0.7))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Progress bar (if enabled)
            if settings.audioShowProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colors.progressBackground)
                        
                        Capsule()
                            .fill(colors.progressFill)
                            .frame(width: geo.size.width * context.state.progress)
                    }
                }
                .frame(height: 3)
            }
            
            // Controls
            HStack(spacing: 28) {
                Button(intent: AudioControlIntent(action: .previous)) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(context.state.currentVerse == 0 ? colors.text.opacity(0.25) : colors.text)
                }
                .buttonStyle(.plain)
                
                Button(intent: AudioControlIntent(action: .toggle)) {
                    ZStack {
                        Circle()
                            .fill(colors.accent)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(settings.audioTheme == .minimal ? .black : .white)
                            .offset(x: context.state.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
                
                Button(intent: AudioControlIntent(action: .next)) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(context.state.currentVerse >= context.state.totalVerses - 1 ? colors.text.opacity(0.25) : colors.text)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Minimal View

struct ThemedAudioMinimal: View {
    let context: ActivityViewContext<BibleAudioAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.audio(for: settings.audioTheme) }
    
    var body: some View {
        Group {
            if context.state.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colors.accent))
                    .scaleEffect(0.45)
            } else if context.state.isPlaying {
                if settings.audioAnimationsEnabled {
                    Image(systemName: "waveform")
                        .font(.system(size: 11))
                        .foregroundStyle(colors.accent)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(colors.accent)
                }
            } else {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(colors.accent)
            }
        }
    }
}
