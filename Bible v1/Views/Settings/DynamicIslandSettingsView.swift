//
//  DynamicIslandSettingsView.swift
//  Bible v1
//
//  Settings view for Dynamic Island customization
//

import SwiftUI

struct DynamicIslandSettingsView: View {
    @ObservedObject private var settingsService = DynamicIslandSettingsService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var previewMode: PreviewMode = .audio
    @State private var previewState: PreviewState = .playing
    
    enum PreviewMode: String, CaseIterable {
        case audio = "Audio"
        case ai = "AI"
    }
    
    enum PreviewState: String, CaseIterable {
        case playing = "Playing"
        case paused = "Paused"
        case thinking = "Thinking"
        case streaming = "Streaming"
        case complete = "Complete"
        
        var availableFor: PreviewMode {
            switch self {
            case .playing, .paused: return .audio
            case .thinking, .streaming, .complete: return .ai
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Live Preview Section
                livePreviewSection
                
                // Audio Settings Section
                audioSettingsSection
                
                // AI Settings Section
                aiSettingsSection
                
                // Reset Section
                resetSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(themeManager.backgroundColor)
        .navigationTitle("Dynamic Island")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Live Preview Section
    
    private var livePreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PREVIEW")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.secondaryTextColor)
            
            // Preview mode selector
            Picker("Preview", selection: $previewMode) {
                ForEach(PreviewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: previewMode) { _, newMode in
                // Update state to match mode
                if newMode == .audio {
                    previewState = .playing
                } else {
                    previewState = .thinking
                }
            }
            
            // State selector
            HStack(spacing: 8) {
                if previewMode == .audio {
                    ForEach([PreviewState.playing, .paused], id: \.self) { state in
                        stateButton(state)
                    }
                } else {
                    ForEach([PreviewState.thinking, .streaming, .complete], id: \.self) { state in
                        stateButton(state)
                    }
                }
            }
            
            // The preview component
            DynamicIslandPreview(
                mode: previewMode,
                state: previewState,
                settings: settingsService.settings
            )
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    private func stateButton(_ state: PreviewState) -> some View {
        Button {
            previewState = state
        } label: {
            Text(state.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(previewState == state ? .white : themeManager.secondaryTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(previewState == state ? themeManager.accentColor : themeManager.cardBackgroundColor.opacity(0.5))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Audio Settings Section
    
    private var audioSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.cyan)
                Text("AUDIO PLAYBACK")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            VStack(spacing: 0) {
                // Theme
                settingRow(
                    icon: "paintpalette.fill",
                    title: "Theme",
                    trailing: {
                        Menu {
                            ForEach(DITheme.allCases) { theme in
                                Button {
                                    settingsService.settings.audioTheme = theme
                                } label: {
                                    Label(theme.displayName, systemImage: theme.iconName)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(settingsService.settings.audioTheme.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(themeManager.secondaryTextColor)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                            }
                        }
                    }
                )
                
                Divider().padding(.leading, 44)
                
                // Text Size
                settingRow(
                    icon: "textformat.size",
                    title: "Text Size",
                    trailing: {
                        Picker("", selection: settingsService.audioTextSize) {
                            ForEach(DITextSize.allCases) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                )
                
                Divider().padding(.leading, 44)
                
                // Show Progress Bar
                settingToggle(
                    icon: "chart.bar.fill",
                    title: "Show Progress Bar",
                    binding: settingsService.audioShowProgress
                )
                
                Divider().padding(.leading, 44)
                
                // Show Verse Text
                settingToggle(
                    icon: "text.alignleft",
                    title: "Show Verse Text",
                    binding: settingsService.audioShowVerseText
                )
                
                Divider().padding(.leading, 44)
                
                // Compact Mode
                settingToggle(
                    icon: "rectangle.compress.vertical",
                    title: "Compact Mode",
                    binding: settingsService.audioCompactMode
                )
                
                Divider().padding(.leading, 44)
                
                // Animations
                settingToggle(
                    icon: "wand.and.stars",
                    title: "Animations",
                    binding: settingsService.audioAnimationsEnabled
                )
                
                Divider().padding(.leading, 44)
                
                // Haptic Feedback
                settingToggle(
                    icon: "hand.tap.fill",
                    title: "Haptic Feedback",
                    binding: settingsService.audioHapticsEnabled
                )
            }
            .padding(.vertical, 8)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    // MARK: - AI Settings Section
    
    private var aiSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI GENERATION")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            VStack(spacing: 0) {
                // Theme
                settingRow(
                    icon: "paintpalette.fill",
                    title: "Theme",
                    trailing: {
                        Menu {
                            ForEach(DITheme.allCases) { theme in
                                Button {
                                    settingsService.settings.aiTheme = theme
                                } label: {
                                    Label(theme.displayName, systemImage: theme.iconName)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(settingsService.settings.aiTheme.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(themeManager.secondaryTextColor)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                            }
                        }
                    }
                )
                
                Divider().padding(.leading, 44)
                
                // Text Size
                settingRow(
                    icon: "textformat.size",
                    title: "Text Size",
                    trailing: {
                        Picker("", selection: settingsService.aiTextSize) {
                            ForEach(DITextSize.allCases) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                )
                
                Divider().padding(.leading, 44)
                
                // Show Progress Bar
                settingToggle(
                    icon: "chart.bar.fill",
                    title: "Show Progress Bar",
                    binding: settingsService.aiShowProgress
                )
                
                Divider().padding(.leading, 44)
                
                // Compact Mode
                settingToggle(
                    icon: "rectangle.compress.vertical",
                    title: "Compact Mode",
                    binding: settingsService.aiCompactMode
                )
                
                Divider().padding(.leading, 44)
                
                // Animations
                settingToggle(
                    icon: "wand.and.stars",
                    title: "Animations",
                    binding: settingsService.aiAnimationsEnabled
                )
            }
            .padding(.vertical, 8)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation {
                    settingsService.resetToDefaults()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset All to Defaults")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Views
    
    private func settingRow<Trailing: View>(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(themeManager.accentColor)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(themeManager.textColor)
            
            Spacer()
            
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func settingToggle(
        icon: String,
        title: String,
        binding: Binding<Bool>
    ) -> some View {
        settingRow(icon: icon, title: title) {
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(themeManager.accentColor)
        }
    }
}

#Preview {
    NavigationStack {
        DynamicIslandSettingsView()
    }
}



