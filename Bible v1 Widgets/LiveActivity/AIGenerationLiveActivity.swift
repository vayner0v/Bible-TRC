//
//  AIGenerationLiveActivity.swift
//  Bible v1 Widgets
//
//  Dynamic Island and Lock Screen UI for AI generation progress
//  Features themed appearance and background-executing controls
//

import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

/// Live Activity widget for AI generation
struct AIGenerationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AIGenerationAttributes.self) { context in
            ThemedAILockScreen(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ThemedAIExpandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ThemedAIExpandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ThemedAIExpandedCenter(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ThemedAIExpandedBottom(context: context)
                }
            } compactLeading: {
                ThemedAICompactLeading(context: context)
            } compactTrailing: {
                ThemedAICompactTrailing(context: context)
            } minimal: {
                ThemedAIMinimal(context: context)
            }
            .keylineTint(ThemeColors.ai(for: loadSettings().aiTheme, mode: context.attributes.mode).accent)
            .widgetURL(URL(string: "biblev1://ai-chat/\(context.attributes.conversationId)"))
        }
    }
    
    private func loadSettings() -> DynamicIslandWidgetSettings {
        DynamicIslandWidgetSettings.load()
    }
}

// MARK: - Themed Lock Screen View

struct ThemedAILockScreen: View {
    let context: ActivityViewContext<AIGenerationAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.ai(for: settings.aiTheme, mode: context.attributes.mode) }
    private var textScale: CGFloat { settings.aiTextSize.scaleFactor }
    
    var body: some View {
        VStack(alignment: .leading, spacing: settings.aiCompactMode ? 10 : 14) {
            // Header
            headerRow
            
            // Content based on status
            contentSection
            
            // Cancel button (only when actively generating)
            if context.state.status == "thinking" || context.state.status == "streaming" {
                cancelButton
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: colors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var headerRow: some View {
        HStack(spacing: 10) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(colors.accent.opacity(0.15))
                    .frame(width: settings.aiCompactMode ? 28 : 36, height: settings.aiCompactMode ? 28 : 36)
                
                if settings.aiAnimationsEnabled && (context.state.status == "thinking" || context.state.status == "streaming") {
                    Image(systemName: "sparkles")
                        .font(.system(size: settings.aiCompactMode ? 12 : 16, weight: .semibold))
                        .foregroundStyle(colors.accent)
                        .symbolEffect(.pulse, isActive: true)
                } else {
                    Image(systemName: context.state.status == "complete" ? "checkmark.circle.fill" : "sparkles")
                        .font(.system(size: settings.aiCompactMode ? 12 : 16, weight: .semibold))
                        .foregroundStyle(context.state.status == "complete" ? .green : colors.accent)
                }
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("TRC AI")
                    .font(.system(size: 13 * textScale, weight: .semibold))
                    .foregroundStyle(colors.text)
                
                Text(context.attributes.modeDisplayName)
                    .font(.system(size: 11 * textScale))
                    .foregroundStyle(colors.accent.opacity(0.9))
            }
            
            Spacer()
            
            // Status indicator
            statusBadge
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(colors.text.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch context.state.status {
        case "thinking", "streaming": return colors.accent
        case "complete": return .green
        default: return .red
        }
    }
    
    private var statusText: String {
        switch context.state.status {
        case "thinking": return "Thinking"
        case "streaming": return "Writing"
        case "complete": return "Ready"
        default: return "Error"
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        switch context.state.status {
        case "thinking":
            thinkingView
        case "streaming":
            streamingView
        case "complete":
            completeView
        default:
            errorView
        }
    }
    
    private var thinkingView: some View {
        HStack(spacing: 10) {
            // Animated dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(colors.accent.opacity(0.35 + Double(i) * 0.2))
                        .frame(width: 6, height: 6)
                }
            }
            
            Text("Processing your question...")
                .font(.system(size: 13 * textScale))
                .foregroundStyle(colors.secondaryText)
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    private var streamingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Preview text - Dynamic
            Text(context.state.preview)
                .font(.system(size: 13 * textScale))
                .foregroundStyle(colors.text.opacity(0.8))
                .lineLimit(settings.aiCompactMode ? 2 : 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Progress bar (if enabled)
            if settings.aiShowProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(colors.progressBackground)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [colors.progressFill, colors.progressFill.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * context.state.progress)
                    }
                }
                .frame(height: 4)
            }
        }
    }
    
    private var completeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title if available
            if let title = context.state.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 14 * textScale, weight: .semibold))
                    .foregroundStyle(colors.text)
            }
            
            // Preview text
            Text(context.state.preview)
                .font(.system(size: 13 * textScale))
                .foregroundStyle(colors.text.opacity(0.75))
                .lineLimit(settings.aiCompactMode ? 2 : 3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Tap hint
            HStack(spacing: 5) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 10))
                Text("Tap to view response")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(colors.accent.opacity(0.8))
            .padding(.top, 4)
        }
    }
    
    private var errorView: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text("Generation failed. Please try again.")
                .font(.system(size: 13 * textScale))
                .foregroundStyle(colors.text.opacity(0.7))
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var cancelButton: some View {
        HStack {
            Spacer()
            
            Button(intent: AICancelIntent()) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(colors.text.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(colors.text.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
}

// MARK: - Dynamic Island Compact Views

struct ThemedAICompactLeading: View {
    let context: ActivityViewContext<AIGenerationAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.ai(for: settings.aiTheme, mode: context.attributes.mode) }
    
    var body: some View {
        Group {
            if context.state.status == "complete" {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.green)
            } else if context.state.status == "error" {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)
            } else {
                if settings.aiAnimationsEnabled {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(colors.accent)
                        .symbolEffect(.pulse, isActive: true)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(colors.accent)
                }
            }
        }
    }
}

struct ThemedAICompactTrailing: View {
    let context: ActivityViewContext<AIGenerationAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.ai(for: settings.aiTheme, mode: context.attributes.mode) }
    
    var body: some View {
        Group {
            if context.state.status == "thinking" {
                Text("AI")
                    .font(.system(size: 11 * settings.aiTextSize.scaleFactor, weight: .semibold))
                    .foregroundStyle(colors.text.opacity(0.8))
            } else if context.state.status == "streaming" {
                Text("\(Int(context.state.progress * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(colors.text.opacity(0.8))
            } else if context.state.status == "complete" {
                Text("Done")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.green)
            } else {
                Text("!")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Dynamic Island Expanded Views

struct ThemedAIExpandedLeading: View {
    let context: ActivityViewContext<AIGenerationAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.ai(for: settings.aiTheme, mode: context.attributes.mode) }
    
    var body: some View {
        Group {
            if settings.aiAnimationsEnabled && context.state.status != "complete" && context.state.status != "error" {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(colors.accent)
                    .symbolEffect(.pulse, isActive: true)
            } else {
                Image(systemName: context.state.status == "complete" ? "checkmark.circle.fill" : "sparkles")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(context.state.status == "complete" ? .green : colors.accent)
            }
        }
    }
}

struct ThemedAIExpandedTrailing: View {
    let context: ActivityViewContext<AIGenerationAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.ai(for: settings.aiTheme, mode: context.attributes.mode) }
    
    var body: some View {
        Text(context.attributes.modeDisplayName)
            .font(.system(size: 11 * settings.aiTextSize.scaleFactor, weight: .medium))
            .foregroundStyle(colors.accent.opacity(0.9))
    }
}

struct ThemedAIExpandedCenter: View {
    let context: ActivityViewContext<AIGenerationAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.ai(for: settings.aiTheme, mode: context.attributes.mode) }
    
    var body: some View {
        VStack(spacing: 1) {
            Text("TRC AI")
                .font(.system(size: 13 * settings.aiTextSize.scaleFactor, weight: .semibold))
                .foregroundStyle(colors.text)
            
            Text(statusText)
                .font(.system(size: 10))
                .foregroundStyle(statusColor)
        }
    }
    
    private var statusText: String {
        switch context.state.status {
        case "thinking": return "Thinking..."
        case "streaming": return "Generating..."
        case "complete": return "Response ready"
        default: return "Failed"
        }
    }
    
    private var statusColor: Color {
        switch context.state.status {
        case "complete": return .green
        case "error": return .red
        default: return colors.secondaryText
        }
    }
}

struct ThemedAIExpandedBottom: View {
    let context: ActivityViewContext<AIGenerationAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.ai(for: settings.aiTheme, mode: context.attributes.mode) }
    
    var body: some View {
        VStack(spacing: 8) {
            // Content based on status
            if context.state.status == "thinking" {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(colors.accent.opacity(0.3 + Double(i) * 0.2))
                            .frame(width: 5, height: 5)
                    }
                    Text("Processing...")
                        .font(.system(size: 10))
                        .foregroundStyle(colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if context.state.status == "streaming" || context.state.status == "complete" {
                Text(context.state.preview)
                    .font(.system(size: 11 * settings.aiTextSize.scaleFactor))
                    .foregroundStyle(colors.text.opacity(0.7))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Progress bar (streaming only, if enabled)
            if context.state.status == "streaming" && settings.aiShowProgress {
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
        }
    }
}

// MARK: - Minimal View

struct ThemedAIMinimal: View {
    let context: ActivityViewContext<AIGenerationAttributes>
    
    private var settings: DynamicIslandWidgetSettings { DynamicIslandWidgetSettings.load() }
    private var colors: ThemeColors { ThemeColors.ai(for: settings.aiTheme, mode: context.attributes.mode) }
    
    var body: some View {
        Group {
            if context.state.status == "complete" {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)
            } else if context.state.status == "error" {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            } else {
                if settings.aiAnimationsEnabled {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(colors.accent)
                        .symbolEffect(.pulse, isActive: true)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(colors.accent)
                }
            }
        }
    }
}
