//
//  WelcomeStepView.swift
//  Bible v1
//
//  Onboarding Welcome Screen
//

import SwiftUI

struct WelcomeStepView: View {
    let onContinue: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo and branding
            VStack(spacing: 24) {
                // Animated icon
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.accentColor.opacity(0.3),
                                    themeManager.accentColor.opacity(0)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // Main icon container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.accentColor,
                                        themeManager.accentColor.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: themeManager.accentColor.opacity(0.4), radius: 20)
                        
                        // Book icon
                        Image(systemName: "book.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)
                }
                
                // App name
                VStack(spacing: 8) {
                    Text("Bible")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Your Daily Companion")
                        .font(.title3)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            
            Spacer()
            
            // Features preview
            VStack(spacing: 16) {
                WelcomeFeatureRow(
                    icon: "book.closed.fill",
                    title: "Read Scripture",
                    description: "Multiple translations at your fingertips",
                    themeManager: themeManager,
                    delay: 0.3
                )
                
                WelcomeFeatureRow(
                    icon: "headphones",
                    title: "Listen",
                    description: "AI-powered natural narration",
                    themeManager: themeManager,
                    delay: 0.4
                )
                
                WelcomeFeatureRow(
                    icon: "heart.fill",
                    title: "Grow",
                    description: "Track your spiritual journey",
                    themeManager: themeManager,
                    delay: 0.5
                )
            }
            .padding(.horizontal, 32)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Get Started button
            VStack(spacing: 16) {
                OnboardingPrimaryButton(title: "Get Started", action: onContinue)
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
            }
            .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Welcome Feature Row

struct WelcomeFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let themeManager: ThemeManager
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    WelcomeStepView(onContinue: {})
}

