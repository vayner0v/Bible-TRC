//
//  AudioStepView.swift
//  Bible v1
//
//  Onboarding Audio Preferences
//

import SwiftUI

struct AudioStepView: View {
    let onContinue: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var audioService = AudioService.shared
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    // Animated waveform background
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { i in
                            WaveformBar(
                                delay: Double(i) * 0.1,
                                themeManager: themeManager
                            )
                        }
                    }
                    .opacity(0.3)
                    
                    Image(systemName: "headphones")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(height: 80)
                .padding(.top, 40)
                
                Text("Listen to Scripture")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)
                
                Text("Set your audio preferences")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : -20)
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Voice Type Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Default Voice")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        VStack(spacing: 12) {
                            VoiceTypeCard(
                                title: "Premium AI Voice",
                                description: "Natural, expressive narration powered by AI",
                                icon: "waveform.circle.fill",
                                badge: "Recommended",
                                isSelected: audioService.preferredVoiceType == .premium,
                                themeManager: themeManager
                            ) {
                                audioService.setPreferredVoiceType(.premium)
                                HapticManager.shared.lightImpact()
                            }
                            
                            VoiceTypeCard(
                                title: "Built-in Voice",
                                description: "High-quality system voice, works offline",
                                icon: "speaker.wave.3.fill",
                                badge: nil,
                                isSelected: audioService.preferredVoiceType == .builtin,
                                themeManager: themeManager
                            ) {
                                audioService.setPreferredVoiceType(.builtin)
                                HapticManager.shared.lightImpact()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    // Reading Speed
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Reading Speed")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            Spacer()
                            
                            Text(audioService.rateDisplayName(audioService.speechRate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(themeManager.accentColor.opacity(0.15))
                                .cornerRadius(8)
                        }
                        
                        HStack(spacing: 16) {
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
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    // Immersive Mode Toggle
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Listening Experience")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Toggle(isOn: $audioService.immersiveModeEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(themeManager.accentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Immersive Mode")
                                        .font(.body)
                                        .foregroundColor(themeManager.textColor)
                                    
                                    Text("Full-screen experience with animations")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                            }
                        }
                        .tint(themeManager.accentColor)
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    
                    // Info callout
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("Premium AI voices require an active subscription. You can change these settings anytime.")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 120)
                }
            }
            .opacity(showContent ? 1 : 0)
            
            // Continue button
            VStack {
                OnboardingPrimaryButton(title: "Continue", action: onContinue)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(
                LinearGradient(
                    colors: [themeManager.backgroundColor.opacity(0), themeManager.backgroundColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Waveform Animation

struct WaveformBar: View {
    let delay: Double
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    
    // Legacy init for compatibility
    init(delay: Double, themeManager: ThemeManager) {
        self.delay = delay
    }
    
    var body: some View {
        Capsule()
            .fill(themeManager.accentColor)
            .frame(width: 6, height: isAnimating ? 40 : 20)
            .animation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Voice Type Card

struct VoiceTypeCard: View {
    let title: String
    let description: String
    let icon: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Legacy init for compatibility
    init(title: String, description: String, icon: String, badge: String?, isSelected: Bool, themeManager: ThemeManager, onTap: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.icon = icon
        self.badge = badge
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : themeManager.accentColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.accentGradient)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.dividerColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AudioStepView(onContinue: {})
}

