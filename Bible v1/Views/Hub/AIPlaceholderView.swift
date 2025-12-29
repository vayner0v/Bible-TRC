//
//  AIPlaceholderView.swift
//  Bible v1
//
//  AI Feature Placeholder - Coming Soon
//

import SwiftUI

/// Placeholder view for the upcoming AI feature
struct AIPlaceholderView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var particleOpacity: Double = 0
    @State private var glowAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient using theme colors
                backgroundGradient
                    .ignoresSafeArea()
                
                // Animated particles
                animatedParticles
                
                // Content
                VStack(spacing: 32) {
                    Spacer()
                    
                    // AI icon with glow
                    aiIconSection
                    
                    // Title and description
                    textSection
                    
                    // Features preview
                    featuresPreview
                    
                    Spacer()
                    
                    // Notify button
                    notifyButton
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textColor)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowAnimation = true
                }
                withAnimation(.easeIn(duration: 1).delay(0.3)) {
                    particleOpacity = 1
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                themeManager.backgroundColor,
                themeManager.cardBackgroundColor,
                themeManager.backgroundColor
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var animatedParticles: some View {
        GeometryReader { geometry in
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.accentColor.opacity(0.3),
                                themeManager.hubGlowColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 4...12), height: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .blur(radius: CGFloat.random(in: 1...3))
                    .opacity(particleOpacity * Double.random(in: 0.3...0.8))
            }
        }
    }
    
    private var aiIconSection: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            themeManager.accentColor.opacity(glowAnimation ? 0.5 : 0.2),
                            themeManager.hubGlowColor.opacity(glowAnimation ? 0.5 : 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 140, height: 140)
                .blur(radius: glowAnimation ? 8 : 4)
            
            // Middle ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [themeManager.accentColor, themeManager.hubGlowColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
            
            // Inner background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.cardBackgroundColor,
                            themeManager.backgroundColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            // AI Icon
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.accentColor, themeManager.hubGlowColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    private var textSection: some View {
        VStack(spacing: 16) {
            Text("AI Companion")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(themeManager.textColor)
            
            Text("Coming Soon")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.accentColor, themeManager.hubGlowColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Your personal spiritual assistant powered by AI.\nGet insights, answers to questions, and guided scripture study.")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var featuresPreview: some View {
        VStack(spacing: 16) {
            Text("What to Expect")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(1)
            
            VStack(spacing: 12) {
                FeaturePreviewRow(
                    icon: "text.bubble.fill",
                    title: "Ask Questions",
                    description: "Get answers about scripture and faith",
                    color: themeManager.accentColor,
                    themeManager: themeManager
                )
                
                FeaturePreviewRow(
                    icon: "book.fill",
                    title: "Study Companion",
                    description: "Deep dive into any passage",
                    color: themeManager.hubGlowColor,
                    themeManager: themeManager
                )
                
                FeaturePreviewRow(
                    icon: "lightbulb.fill",
                    title: "Daily Insights",
                    description: "Personalized devotional content",
                    color: themeManager.hubTileSecondaryColor,
                    themeManager: themeManager
                )
                
                FeaturePreviewRow(
                    icon: "hands.sparkles.fill",
                    title: "Prayer Helper",
                    description: "Guidance for your prayer life",
                    color: themeManager.accentColor,
                    themeManager: themeManager
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.dividerColor, lineWidth: 1)
                    )
            )
        }
    }
    
    private var notifyButton: some View {
        Button {
            // Could set up notification for when AI is ready
            HapticManager.shared.success()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill")
                Text("Notify Me When Ready")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.accentGradient)
            .cornerRadius(14)
            .shadow(color: themeManager.hubShadowColor, radius: 10, y: 5)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

/// Feature preview row
struct FeaturePreviewRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
    }
}

/// AI button for Hub header
struct AIFloatingButton: View {
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.accentColor.opacity(isAnimating ? 0.3 : 0.15),
                                themeManager.hubGlowColor.opacity(isAnimating ? 0.3 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .blur(radius: 6)
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.accentColor,
                                themeManager.hubGlowColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: themeManager.hubShadowColor, radius: 8, y: 4)
                
                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    AIPlaceholderView()
}

#Preview("AI Button") {
    ZStack {
        Color.gray.opacity(0.2)
        AIFloatingButton(action: {})
    }
}
