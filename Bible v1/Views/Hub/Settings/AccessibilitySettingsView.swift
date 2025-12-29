//
//  AccessibilitySettingsView.swift
//  Bible v1
//
//  Spiritual Hub - Accessibility Settings
//  Updated with system text size toggle and renamed controls
//

import SwiftUI

struct AccessibilitySettingsView: View {
    @ObservedObject private var accessibility = AccessibilityManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            List {
                // App Text Size Section
                Section {
                    // Use iOS Text Size toggle
                    Toggle(isOn: $settings.useSystemTextSize) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Use iOS Text Size", systemImage: "iphone")
                            Text("Follows your device's Dynamic Type settings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(themeManager.accentColor)
                    
                    // App-specific slider (only shown when not using system)
                    if !settings.useSystemTextSize {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("App Text Size")
                                Spacer()
                                Text(String(format: "%.0f%%", settings.appUIScaleMultiplier * 100))
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.accentColor)
                            }
                            
                            Slider(
                                value: $settings.appUIScaleMultiplier,
                                in: 0.8...1.6,
                                step: 0.1
                            )
                            .tint(themeManager.accentColor)
                            
                            Text("Affects the entire app interface")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $settings.boldTextEnabled) {
                        Label("Bold Text", systemImage: "bold")
                    }
                    .tint(themeManager.accentColor)
                    
                    Toggle(isOn: $settings.increaseLineSpacing) {
                        Label("Increase Line Spacing", systemImage: "text.alignleft")
                    }
                    .tint(themeManager.accentColor)
                } header: {
                    Text("Text")
                } footer: {
                    Text("Adjust text for easier reading throughout the app")
                }
                .listRowBackground(themeManager.cardBackgroundColor)
                
                // Font Style Section
                Section {
                    Picker("Font Style", selection: $settings.accessibleFontStyle) {
                        ForEach(AccessibleFontStyle.allCases) { style in
                            VStack(alignment: .leading) {
                                Text(style.rawValue)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Font Style")
                } footer: {
                    Text("Choose a font that works best for you")
                }
                .listRowBackground(themeManager.cardBackgroundColor)
                
                // Display Section
                Section {
                    Toggle(isOn: $settings.highContrastEnabled) {
                        Label("High Contrast", systemImage: "circle.lefthalf.filled")
                    }
                    .tint(themeManager.accentColor)
                    
                    Toggle(isOn: $settings.buttonShapesEnabled) {
                        Label("Button Shapes", systemImage: "rectangle")
                    }
                    .tint(themeManager.accentColor)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Improve visibility of interface elements")
                }
                .listRowBackground(themeManager.cardBackgroundColor)
                
                // Motion Section
                Section {
                    Toggle(isOn: $settings.reducedMotionEnabled) {
                        Label("Reduce Motion", systemImage: "figure.walk")
                    }
                    .tint(themeManager.accentColor)
                } header: {
                    Text("Motion")
                } footer: {
                    Text("Minimize animations throughout the app")
                }
                .listRowBackground(themeManager.cardBackgroundColor)
                
                // Reader vs App Explanation
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(themeManager.accentColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App vs Reader Text Size")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("These settings affect the entire app interface (menus, buttons, settings). Scripture reader has its own text size adjustment in Reading settings.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        NavigationLink {
                            ReadingSettingsView()
                        } label: {
                            HStack {
                                Label("Reader Text Settings", systemImage: "book.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Related Settings")
                }
                .listRowBackground(themeManager.cardBackgroundColor)
                
                // Preview Section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preview")
                            .font(previewHeadingFont)
                        
                        Text("This is how body text will appear. Adjust the settings above to find what works best for you.")
                            .font(previewBodyFont)
                            .lineSpacing(settings.effectiveLineSpacing)
                        
                        Text("\"For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.\"")
                            .font(previewBodyFont)
                            .italic()
                            .lineSpacing(settings.effectiveLineSpacing)
                        
                        Text("— Jeremiah 29:11")
                            .font(previewCaptionFont)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }
                .listRowBackground(themeManager.cardBackgroundColor)
                
                // Reset Section
                Section {
                    Button(role: .destructive) {
                        settings.resetAccessibilitySettings()
                        HapticManager.shared.success()
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
                .listRowBackground(themeManager.cardBackgroundColor)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Accessibility")
    }
    
    // MARK: - Preview Fonts
    
    private var previewHeadingFont: Font {
        let size = settings.effectiveUIFontSize * 1.3
        let weight: Font.Weight = settings.boldTextEnabled ? .bold : .semibold
        return .system(size: size, weight: weight)
    }
    
    private var previewBodyFont: Font {
        let size = settings.effectiveUIFontSize
        let weight: Font.Weight = settings.boldTextEnabled ? .medium : .regular
        return .system(size: size, weight: weight)
    }
    
    private var previewCaptionFont: Font {
        let size = settings.effectiveUIFontSize * 0.8
        let weight: Font.Weight = settings.boldTextEnabled ? .medium : .regular
        return .system(size: size, weight: weight)
    }
}

// MARK: - Screen Reader Support Info

struct ScreenReaderInfoView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("VoiceOver Support")
                        .font(.headline)
                    
                    Text("This app is designed to work with VoiceOver. All interactive elements are labeled for screen reader users.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Navigation Tips")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        BulletPoint(text: "Swipe left/right to move between elements")
                        BulletPoint(text: "Double-tap to activate buttons")
                        BulletPoint(text: "Use the rotor to navigate by headings")
                        BulletPoint(text: "Three-finger swipe to scroll")
                    }
                }
            }
        }
        .navigationTitle("Screen Reader")
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AccessibilitySettingsView()
    }
}
