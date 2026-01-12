//
//  SplashView.swift
//  Bible v1
//
//  Animated splash screen with preloader animation
//

import SwiftUI

/// Animated splash screen displayed on app launch
struct SplashView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Animation states
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var subtitleOpacity: Double = 0
    @State private var backgroundProgress: Double = 0
    
    let onAnimationComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated background gradient
            animatedBackground
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icon with glow effect
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                themeManager.hubGlowColor.opacity(0.3 - Double(index) * 0.1),
                                lineWidth: 2
                            )
                            .frame(width: 120 + CGFloat(index) * 40, height: 120 + CGFloat(index) * 40)
                            .scaleEffect(glowScale + CGFloat(index) * 0.1)
                            .opacity(glowOpacity)
                    }
                    
                    // Radiant glow background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.hubGlowColor.opacity(0.4),
                                    themeManager.hubGlowColor.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)
                    
                    // Main icon
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    themeManager.accentColor,
                                    themeManager.accentColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                }
                
                // App title
                VStack(spacing: 8) {
                    Text("Bible")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundColor(themeManager.textColor)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)
                    
                    Text("Your Spiritual Journey")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .opacity(subtitleOpacity)
                }
                
                Spacer()
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private var animatedBackground: some View {
        ZStack {
            // Base background
            themeManager.backgroundColor
            
            // Gradient overlay that animates
            LinearGradient(
                colors: [
                    themeManager.accentColor.opacity(0.15 * (1 - backgroundProgress)),
                    themeManager.hubGlowColor.opacity(0.1 * (1 - backgroundProgress)),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private func startAnimationSequence() {
        // Phase 1: Icon appears with spring (0ms - 500ms)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // Phase 2: Glow pulses outward (300ms - 800ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                glowScale = 1.2
                glowOpacity = 1.0
            }
        }
        
        // Phase 3: Title fades in with slide (500ms - 1000ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
        }
        
        // Phase 4: Subtitle appears (700ms - 1100ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.4)) {
                subtitleOpacity = 1.0
            }
        }
        
        // Phase 5: Background settles (800ms - 1200ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                backgroundProgress = 1.0
            }
        }
        
        // Phase 6: Glow pulses (continuous until transition)
        startGlowPulse()
        
        // Phase 7: Complete and transition (2000ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onAnimationComplete()
        }
    }
    
    private func startGlowPulse() {
        // Subtle continuous pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowScale = 1.3
        }
    }
}

/// Container view that manages splash to main app transition
struct SplashContainer: View {
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Main content (HomeView with Hub as first tab)
            HomeView()
                .opacity(showSplash ? 0 : 1)
            
            // Splash overlay
            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        splashOpacity = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSplash = false
                    }
                }
                .opacity(splashOpacity)
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    SplashView(onAnimationComplete: {})
}

#Preview("Container") {
    SplashContainer()
}







