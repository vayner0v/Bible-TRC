//
//  ImmersiveModeSettingsView.swift
//  Bible v1
//
//  Settings for immersive listening mode
//

import SwiftUI

struct ImmersiveModeSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Enable/Disable Section
                    enableSection
                    
                    // Animation Section
                    if settings.immersiveModeEnabled {
                        animationSection
                        
                        // Behavior Section
                        behaviorSection
                        
                        // Preview Section
                        previewSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Immersive Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Enable Section
    
    private var enableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IMMERSIVE LISTENING")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                Toggle(isOn: $settings.immersiveModeEnabled) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(themeManager.accentGradient)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Immersive Mode")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.textColor)
                            
                            Text("Full-screen experience with animations")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
                .tint(themeManager.accentColor)
                .padding()
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Animation Section
    
    private var animationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ANIMATIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Animation Style")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    HStack(spacing: 12) {
                        ForEach(ImmersiveAnimationStyle.allCases) { style in
                            AnimationStyleButton(
                                style: style,
                                isSelected: settings.immersiveAnimationStyle == style,
                                themeManager: themeManager
                            ) {
                                settings.immersiveAnimationStyle = style
                                HapticManager.shared.selection()
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Auto-hide delay
                VStack(spacing: 0) {
                    SettingsSliderRow(
                        title: "Auto-Hide UI Delay",
                        value: $settings.immersiveAutoHideDelay,
                        range: 1.0...10.0,
                        step: 0.5,
                        tickMarks: [1, 3, 5, 7, 10],
                        formatValue: { String(format: "%.1fs", $0) }
                    )
                }
                .padding()
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Behavior Section
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BEHAVIOR")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "sun.max.fill",
                    title: "Keep Screen On",
                    subtitle: "Prevent screen from dimming while listening",
                    isOn: $settings.immersiveKeepScreenOn
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                SettingsToggleRow(
                    icon: "play.circle.fill",
                    title: "Background Audio",
                    subtitle: "Continue playing when app is backgrounded",
                    isOn: $settings.immersiveBackgroundAudio
                )
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREVIEW")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            ImmersiveModePreview(
                animationStyle: settings.immersiveAnimationStyle,
                themeManager: themeManager
            )
            .frame(height: 200)
            .cornerRadius(14)
        }
    }
}

// MARK: - Animation Style Button

struct AnimationStyleButton: View {
    let style: ImmersiveAnimationStyle
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconForStyle)
                    .font(.title2)
                
                VStack(spacing: 2) {
                    Text(style.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? themeManager.accentColor.opacity(0.15) : Color.clear)
            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? themeManager.accentColor : themeManager.dividerColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel("\(style.displayName) animation")
        .accessibilityValue(isSelected ? "Selected" : "")
    }
    
    private var iconForStyle: String {
        switch style {
        case .none: return "circle.slash"
        case .gentle: return "leaf.fill"
        case .dynamic: return "bolt.fill"
        }
    }
}

// MARK: - Immersive Mode Preview

struct ImmersiveModePreview: View {
    let animationStyle: ImmersiveAnimationStyle
    let themeManager: ThemeManager
    
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    themeManager.backgroundColor,
                    themeManager.accentColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated glow effect
            if animationStyle != .none {
                Circle()
                    .fill(themeManager.accentColor.opacity(glowOpacity))
                    .blur(radius: 50)
                    .scaleEffect(pulseScale)
                    .offset(y: 20)
            }
            
            // Preview content
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(themeManager.accentColor)
                    .scaleEffect(animationStyle == .dynamic ? pulseScale : 1.0)
                
                VStack(spacing: 4) {
                    Text("Immersive Mode")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(animationStyle.description)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: animationStyle) { _, _ in
            startAnimations()
        }
    }
    
    private func startAnimations() {
        guard animationStyle != .none else {
            pulseScale = 1.0
            glowOpacity = 0.3
            return
        }
        
        let duration = animationStyle == .gentle ? 3.0 : 1.5
        
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            pulseScale = animationStyle == .gentle ? 1.05 : 1.15
            glowOpacity = animationStyle == .gentle ? 0.4 : 0.6
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ImmersiveModeSettingsView()
    }
}






